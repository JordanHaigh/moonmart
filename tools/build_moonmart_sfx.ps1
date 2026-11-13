param(
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$sampleRate = 44100
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot "assets\audio\sfx"
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

function Add-BellStrike {
    param(
        [double[]]$Buffer,
        [int]$StartSample,
        [double]$Fundamental,
        [double]$Velocity,
        [double]$Brightness,
        [double]$DecayScale,
        [double]$SampleRate
    )

    # Inharmonic mode ratios model a struck metal or glass resonator, not a sine beep.
    $modeRatios = @(1.0, 2.756, 5.404, 8.933, 13.34, 18.64, 24.9)
    $modeWeights = @(1.0, 0.48, 0.27, 0.16, 0.105, 0.068, 0.044)
    $modeDecays = @(1.42, 1.12, 0.86, 0.63, 0.46, 0.34, 0.25)
    $modePhases = @(0.12, 0.71, 1.37, 2.09, 2.81, 3.53, 4.27)
    for ($mode = 0; $mode -lt $modeRatios.Count; $mode++) {
        $frequency = $Fundamental * $modeRatios[$mode]
        if ($frequency -ge ($SampleRate * 0.46)) { continue }
        $amplitude = $Velocity * $modeWeights[$mode] * [Math]::Pow($Brightness, $mode)
        $decay = $modeDecays[$mode] * $DecayScale
        $samples = [Math]::Min($Buffer.Length - $StartSample, [int][Math]::Ceiling($SampleRate * ($decay * 2.75 + 0.12)))
        $phase = $modePhases[$mode]
        for ($offset = 0; $offset -lt $samples; $offset++) {
            $time = $offset / $SampleRate
            $attack = 1.0 - [Math]::Exp(-$time * 420.0)
            $envelope = $attack * [Math]::Exp(-$time / $decay)
            $bufferIndex = $StartSample + $offset
            $Buffer[$bufferIndex] += $amplitude * $envelope * [Math]::Sin(2.0 * [Math]::PI * $frequency * $time + $phase)
        }
    }
}

function New-MoonmartEffect {
    param(
        [string]$Name,
        [double]$DurationSeconds,
        [object[]]$Strikes,
        [double]$Brightness = 0.83,
        [double]$DecayScale = 1.0
    )

    $dryLength = [int][Math]::Ceiling($DurationSeconds * $sampleRate)
    $tailSamples = [int][Math]::Ceiling(0.28 * $sampleRate)
    $dry = [double[]]::new($dryLength + $tailSamples)
    foreach ($strike in $Strikes) {
        Add-BellStrike -Buffer $dry -StartSample ([int][Math]::Round($strike.at * $sampleRate)) -Fundamental $strike.frequency -Velocity $strike.velocity -Brightness $Brightness -DecayScale ($DecayScale * $strike.decay) -SampleRate $sampleRate
    }
	$fadeSamples = [Math]::Min([int][Math]::Round(0.14 * $sampleRate), $dry.Length)
	$fadeStart = $dry.Length - $fadeSamples
	for ($i = $fadeStart; $i -lt $dry.Length; $i++) {
		$dry[$i] *= 1.0 - (($i - $fadeStart) / [double]$fadeSamples)
	}

    # Short, dark early reflections add a room-like tail without smearing the attack.
    $leftDelayA = [int][Math]::Round(0.037 * $sampleRate)
    $leftDelayB = [int][Math]::Round(0.083 * $sampleRate)
    $rightDelayA = [int][Math]::Round(0.052 * $sampleRate)
    $rightDelayB = [int][Math]::Round(0.097 * $sampleRate)
    $stereo = [double[]]::new($dry.Length * 2)
    $peak = 0.0
    for ($i = 0; $i -lt $dry.Length; $i++) {
        $left = 0.84 * $dry[$i]
        $right = 0.84 * $dry[$i]
        if ($i -ge $leftDelayA) { $left += 0.105 * $dry[$i - $leftDelayA] }
        if ($i -ge $leftDelayB) { $left += 0.056 * $dry[$i - $leftDelayB] }
        if ($i -ge $rightDelayA) { $right += 0.094 * $dry[$i - $rightDelayA] }
        if ($i -ge $rightDelayB) { $right += 0.061 * $dry[$i - $rightDelayB] }
        $stereo[2 * $i] = $left
        $stereo[(2 * $i) + 1] = $right
        $peak = [Math]::Max($peak, [Math]::Max([Math]::Abs($left), [Math]::Abs($right)))
    }
	$outputFadeSamples = [Math]::Min([int][Math]::Round(0.105 * $sampleRate), $dry.Length)
	$outputFadeStart = $dry.Length - $outputFadeSamples
	for ($i = $outputFadeStart; $i -lt $dry.Length; $i++) {
		$fade = 1.0 - (($i - $outputFadeStart) / [double]$outputFadeSamples)
		$stereo[2 * $i] *= $fade
		$stereo[(2 * $i) + 1] *= $fade
	}
    if ($peak -lt 1.0e-9) { throw "Synthesis for $Name produced silence." }
    $targetPeak = 0.68
    $gain = $targetPeak / $peak
    $outputPath = Join-Path $OutputDirectory $Name
    $stream = [System.IO.File]::Open($outputPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    try {
        $writer = [System.IO.BinaryWriter]::new($stream)
        try {
            $dataBytes = $stereo.Length * 2
            $writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
            $writer.Write([int](36 + $dataBytes))
            $writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
            $writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
            $writer.Write([int]16)
            $writer.Write([int16]1)
            $writer.Write([int16]2)
            $writer.Write([int]$sampleRate)
            $writer.Write([int]($sampleRate * 4))
            $writer.Write([int16]4)
            $writer.Write([int16]16)
            $writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
            $writer.Write([int]$dataBytes)
            foreach ($sample in $stereo) {
                $scaled = [Math]::Max(-1.0, [Math]::Min(1.0, $sample * $gain))
                $writer.Write([int16][Math]::Round($scaled * 32767.0))
            }
        }
        finally { $writer.Dispose() }
    }
    finally { $stream.Dispose() }

    $seconds = $stereo.Length / 2.0 / $sampleRate
    $peakDb = 20.0 * [Math]::Log10($targetPeak)
    [pscustomobject]@{
        file = $Name
        sample_rate_hz = $sampleRate
        channels = 2
        bit_depth = 16
        duration_seconds = [Math]::Round($seconds, 3)
        peak_dbfs = [Math]::Round($peakDb, 2)
        peak_normalization = "-3.35 dBFS target; no clipping"
        source_model = "inharmonic struck resonators with short stereo early reflections"
        bytes = (Get-Item -LiteralPath $outputPath).Length
    }
}

$metadata = @(
    (New-MoonmartEffect -Name "moonmart_door_bell.wav" -DurationSeconds 1.42 -Brightness 0.78 -Strikes @(
        @{ at = 0.000; frequency = 880.0; velocity = 0.82; decay = 1.12 },
        @{ at = 0.145; frequency = 1174.66; velocity = 0.69; decay = 0.92 }
    )),
    (New-MoonmartEffect -Name "moonmart_threshold_door_bell.wav" -DurationSeconds 1.74 -Brightness 0.76 -Strikes @(
        @{ at = 0.000; frequency = 880.0; velocity = 0.82; decay = 1.12 },
        @{ at = 0.145; frequency = 1169.96; velocity = 0.58; decay = 1.14 },
        @{ at = 0.310; frequency = 587.33; velocity = 0.09; decay = 1.48 }
    )),
    (New-MoonmartEffect -Name "moonmart_register_chime.wav" -DurationSeconds 1.18 -Brightness 0.88 -Strikes @(
        @{ at = 0.000; frequency = 1396.91; velocity = 0.66; decay = 0.82 },
        @{ at = 0.092; frequency = 1760.0; velocity = 0.62; decay = 0.72 },
        @{ at = 0.186; frequency = 2093.0; velocity = 0.40; decay = 0.62 }
    )),
    (New-MoonmartEffect -Name "moonmart_threshold_register_chime.wav" -DurationSeconds 1.52 -Brightness 0.80 -Strikes @(
        @{ at = 0.000; frequency = 1396.91; velocity = 0.54; decay = 0.96 },
        @{ at = 0.105; frequency = 1746.83; velocity = 0.42; decay = 0.98 },
        @{ at = 0.216; frequency = 2079.0; velocity = 0.25; decay = 0.84 },
        @{ at = 0.318; frequency = 698.46; velocity = 0.055; decay = 1.15 }
    )),
    (New-MoonmartEffect -Name "moonmart_story_reveal.wav" -DurationSeconds 2.48 -Brightness 0.73 -Strikes @(
        @{ at = 0.000; frequency = 392.0; velocity = 0.30; decay = 1.32 },
        @{ at = 0.170; frequency = 587.33; velocity = 0.42; decay = 1.18 },
        @{ at = 0.365; frequency = 880.0; velocity = 0.51; decay = 1.06 },
        @{ at = 0.540; frequency = 1174.66; velocity = 0.27; decay = 0.94 }
    ))
)

$manifestPath = Join-Path $OutputDirectory "moonmart_sfx_metadata.json"
$metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
$metadata | Format-Table -AutoSize
Write-Output "Metadata: $manifestPath"
