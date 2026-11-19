param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
	[string]$GodotPath = "C:\apps\godot\Godot_v4.7.2-stable_win64.exe",
	[ValidateRange(1, 10)][int]$Repetitions = 3,
	[ValidateRange(0.1, 600)][double]$WarmupSeconds = 20.0,
	[ValidateRange(0.1, 600)][double]$BaselineSeconds = 30.0,
	[ValidateRange(0.1, 600)][double]$ActiveSeconds = 90.0,
	[ValidateRange(0.1, 600)][double]$UiSeconds = 15.0,
	[ValidateRange(0.1, 600)][double]$ResumedSeconds = 30.0,
	[string]$ReportRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path ("godot_task_state/profile_gameplay_" + (Get-Date -Format "yyyyMMdd_HHmmss")))
)

$ErrorActionPreference = "Stop"
$projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path
$godotExecutable = (Resolve-Path -LiteralPath $GodotPath).Path
$reportPath = [System.IO.Path]::GetFullPath($ReportRoot)
if (-not $reportPath.StartsWith($projectPath + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Profile reports must be written inside the project godot_task_state folder."
}
if (-not $reportPath.Contains([System.IO.Path]::DirectorySeparatorChar + "godot_task_state" + [System.IO.Path]::DirectorySeparatorChar)) {
	throw "Profile reports must stay under godot_task_state."
}
if (-not (Test-Path -LiteralPath $godotExecutable -PathType Leaf)) { throw "Godot executable is missing: $godotExecutable" }
New-Item -ItemType Directory -Path $reportPath -Force | Out-Null

$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$previousProfileOutput = $env:MOONMART_PROFILE_OUTPUT
$previousWarmup = $env:MOONMART_PROFILE_WARMUP_SECONDS
$previousBaseline = $env:MOONMART_PROFILE_BASELINE_SECONDS
$previousActive = $env:MOONMART_PROFILE_ACTIVE_SECONDS
$previousUi = $env:MOONMART_PROFILE_UI_SECONDS
$previousResumed = $env:MOONMART_PROFILE_RESUMED_SECONDS
$invariant = [System.Globalization.CultureInfo]::InvariantCulture
$runSummaries = [System.Collections.Generic.List[string]]::new()

try {
	for ($runIndex = 1; $runIndex -le $Repetitions; $runIndex++) {
		$runPath = Join-Path $reportPath ("run_{0:D2}" -f $runIndex)
		$appDataPath = Join-Path $runPath "appdata"
		$localAppDataPath = Join-Path $runPath "localappdata"
		New-Item -ItemType Directory -Path $runPath, $appDataPath, $localAppDataPath -Force | Out-Null
		$env:APPDATA = $appDataPath
		$env:LOCALAPPDATA = $localAppDataPath
		$env:MOONMART_PROFILE_OUTPUT = $runPath
		$env:MOONMART_PROFILE_WARMUP_SECONDS = $WarmupSeconds.ToString($invariant)
		$env:MOONMART_PROFILE_BASELINE_SECONDS = $BaselineSeconds.ToString($invariant)
		$env:MOONMART_PROFILE_ACTIVE_SECONDS = $ActiveSeconds.ToString($invariant)
		$env:MOONMART_PROFILE_UI_SECONDS = $UiSeconds.ToString($invariant)
		$env:MOONMART_PROFILE_RESUMED_SECONDS = $ResumedSeconds.ToString($invariant)
		$stdoutPath = Join-Path $runPath "stdout.log"
		$stderrPath = Join-Path $runPath "stderr.log"
		$memoryPath = Join-Path $runPath "process_memory.csv"
		$memoryRows = [System.Collections.Generic.List[object]]::new()
		$startUtc = [DateTime]::UtcNow
		$previousSampleUtc = $null
		$previousCpuSeconds = $null
		$process = Start-Process -FilePath $godotExecutable -ArgumentList @("--path", $projectPath, "--script", "res://tests/performance/profile_gameplay.gd") -WorkingDirectory $projectPath -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
		$null = $process.Handle # cache the handle so ExitCode is readable after exit
		while ($true) {
			$process.Refresh()
			if ($process.HasExited) { break }
			try {
				$sample = Get-Process -Id $process.Id -ErrorAction Stop
				$sampleUtc = [DateTime]::UtcNow
				$cpuPercent = $null
				if ($null -ne $previousSampleUtc -and $null -ne $previousCpuSeconds) {
					$wallDeltaSeconds = ($sampleUtc - $previousSampleUtc).TotalSeconds
					if ($wallDeltaSeconds -gt 0.0) { $cpuPercent = [Math]::Round((($sample.CPU - $previousCpuSeconds) / $wallDeltaSeconds) * 100.0, 1) }
				}
				$memoryRows.Add([pscustomobject]@{
					utc = $sampleUtc.ToString("o")
					elapsed_seconds = [Math]::Round(($sampleUtc - $startUtc).TotalSeconds, 3)
					working_set_mib = [Math]::Round($sample.WorkingSet64 / 1MB, 2)
					private_bytes_mib = [Math]::Round($sample.PrivateMemorySize64 / 1MB, 2)
					cpu_seconds = [Math]::Round($sample.CPU, 3)
					cpu_percent_of_one_core = $cpuPercent
				})
				$previousSampleUtc = $sampleUtc
				$previousCpuSeconds = $sample.CPU
			} catch { }
			Start-Sleep -Seconds 1
		}
		$memoryRows | Export-Csv -LiteralPath $memoryPath -NoTypeInformation
		$process.WaitForExit()
		$stdout = Get-Content -LiteralPath $stdoutPath -Raw
		$stderr = Get-Content -LiteralPath $stderrPath -Raw
		if ($null -eq $stdout) { $stdout = "" }
		if ($null -eq $stderr) { $stderr = "" }
		if ($process.ExitCode -ne 0) {
			throw "Gameplay profile run $runIndex failed with exit code $($process.ExitCode). Review $stderrPath and $stdoutPath."
		}
		if ($stderr.Trim().Length -gt 0) {
			throw "Gameplay profile run $runIndex wrote to stderr. Review $stderrPath."
		}
		if (-not $stdout.Contains("Gameplay profile PASS:")) {
			throw "Gameplay profile run $runIndex did not report its save-safe completion marker. Review $stdoutPath."
		}
		$runSummary = ("run_{0:D2}: exit={1}; frames={2}; memory={3}; isolated_data={4}" -f $runIndex, $process.ExitCode, (Join-Path $runPath "phase_summary.csv"), $memoryPath, $appDataPath)
		$runSummaries.Add($runSummary)
		Write-Output ("Completed gameplay profile run {0}/{1}." -f $runIndex, $Repetitions)
	}
} finally {
	$env:APPDATA = $previousAppData
	$env:LOCALAPPDATA = $previousLocalAppData
	$env:MOONMART_PROFILE_OUTPUT = $previousProfileOutput
	$env:MOONMART_PROFILE_WARMUP_SECONDS = $previousWarmup
	$env:MOONMART_PROFILE_BASELINE_SECONDS = $previousBaseline
	$env:MOONMART_PROFILE_ACTIVE_SECONDS = $previousActive
	$env:MOONMART_PROFILE_UI_SECONDS = $previousUi
	$env:MOONMART_PROFILE_RESUMED_SECONDS = $previousResumed
}

try {
	$cpuName = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1 -ExpandProperty Name)
} catch {
	try {
		$cpuName = (Get-ItemProperty -LiteralPath "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -Name "ProcessorNameString" -ErrorAction Stop).ProcessorNameString
	} catch {
		$cpuName = $env:PROCESSOR_IDENTIFIER
	}
}
if ([string]::IsNullOrWhiteSpace($cpuName)) { $cpuName = "Not exposed to this process" }
$hostLines = [System.Collections.Generic.List[string]]::new()
$hostLines.Add("Profile root: $reportPath")
$hostLines.Add("Runs: $Repetitions")
$hostLines.Add("CPU: $cpuName")
$hostLines.Add("Renderer/GPU: recorded by the Godot driver in each run's metadata.json")
$hostLines.Add("Audio: system default driver; rendered window; vsync disabled with a fixed 60 FPS engine cap")
$hostLines.Add("Scope: local comparative profile; not release-target sign-off")
$hostLines.Add("")
$hostLines.AddRange($runSummaries.ToArray())
$hostInfo = [string]::Join([Environment]::NewLine, $hostLines.ToArray())
[System.IO.File]::WriteAllText((Join-Path $reportPath "README.txt"), $hostInfo, [System.Text.UTF8Encoding]::new($false))
Write-Output "Gameplay profiling complete: $reportPath"
