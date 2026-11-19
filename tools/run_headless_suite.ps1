param(
	[string]$GodotExecutable = 'C:\apps\godot\Godot_v4.7.2-stable_win64.exe',
	[string]$ReportRoot = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $projectRoot 'tests\headless'

if (-not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) {
	throw "Godot executable not found: $GodotExecutable"
}
if (-not (Test-Path -LiteralPath $testRoot -PathType Container)) {
	throw "Headless test folder not found: $testRoot"
}

if ([string]::IsNullOrWhiteSpace($ReportRoot)) {
	$runId = Get-Date -Format 'yyyyMMdd_HHmmss'
	$ReportRoot = Join-Path $projectRoot "godot_task_state\headless_suite_$runId"
}
New-Item -ItemType Directory -Force -Path $ReportRoot | Out-Null

$tests = @(Get-ChildItem -LiteralPath $testRoot -Filter 'test_*.gd' -File | Sort-Object Name)
if ($tests.Count -eq 0) {
	throw "No test scripts found in $testRoot"
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($test in $tests) {
	$testId = [System.IO.Path]::GetFileNameWithoutExtension($test.Name)
	$testReportRoot = Join-Path $ReportRoot $testId
	$appDataRoot = Join-Path $testReportRoot 'appdata'
	$localAppDataRoot = Join-Path $testReportRoot 'localappdata'
	New-Item -ItemType Directory -Force -Path $appDataRoot,$localAppDataRoot | Out-Null
	$stdoutPath = Join-Path $testReportRoot 'stdout.log'
	$stderrPath = Join-Path $testReportRoot 'stderr.log'
	$scenePath = [System.IO.Path]::ChangeExtension($test.FullName, '.tscn')

	if (Test-Path -LiteralPath $scenePath -PathType Leaf) {
		$arguments = @('--headless', '--path', $projectRoot, '--script', 'res://tests/headless/run_scene_test.gd', '--', "res://tests/headless/$([System.IO.Path]::GetFileName($scenePath))")
	} else {
		$arguments = @('--headless', '--path', $projectRoot, '--script', "res://tests/headless/$($test.Name)")
	}

	$previousAppData = $env:APPDATA
	$previousLocalAppData = $env:LOCALAPPDATA
	$env:APPDATA = $appDataRoot
	$env:LOCALAPPDATA = $localAppDataRoot
	$exitCode = 1
	$errorText = ''
	try {
		$process = Start-Process -FilePath $GodotExecutable -ArgumentList $arguments -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
		$exitCode = $process.ExitCode
		if (Test-Path -LiteralPath $stderrPath) {
			$errorText = [System.IO.File]::ReadAllText($stderrPath)
		}
	} catch {
		$errorText = $_.Exception.Message
	} finally {
		$env:APPDATA = $previousAppData
		$env:LOCALAPPDATA = $previousLocalAppData
	}

	$passed = $exitCode -eq 0 -and [string]::IsNullOrWhiteSpace($errorText)
	$results.Add([pscustomobject]@{
		Test = $testId
		Status = if ($passed) { 'PASS' } else { 'FAIL' }
		ExitCode = $exitCode
		Stderr = if ([string]::IsNullOrWhiteSpace($errorText)) { '' } else { $stderrPath }
		Stdout = $stdoutPath
	})
	Write-Output ("{0,-38} {1} (exit {2})" -f $testId, $(if ($passed) { 'PASS' } else { 'FAIL' }), $exitCode)
}

$results | Export-Csv -LiteralPath (Join-Path $ReportRoot 'summary.csv') -NoTypeInformation
$failed = @($results | Where-Object Status -ne 'PASS').Count
Write-Output "Headless suite: $($results.Count - $failed)/$($results.Count) passed. Report: $ReportRoot\summary.csv"
if ($failed -gt 0) {
	exit 1
}
exit 0
