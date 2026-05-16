param(
	[string]$GodotPath = "..\Godot_v4.6.2-stable_win64_console.exe",
	[string]$Preset = "Web",
	[string]$Output = "build\web\index.html",
	[string]$TemplateVersion = "4.6.2.stable",
	[switch]$UseGodotExporter
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([System.IO.Path]::IsPathRooted($GodotPath)) {
	$godotExe = Resolve-Path $GodotPath
} else {
	$godotExe = Resolve-Path (Join-Path $projectRoot $GodotPath)
}
$outputPath = Join-Path $projectRoot $Output
$outputDir = Split-Path -Parent $outputPath
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($outputPath)
$templateRoot = Join-Path $env:APPDATA "Godot\export_templates\$TemplateVersion"
$webTemplate = Join-Path $templateRoot "web_nothreads_release.zip"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Push-Location $projectRoot
try {
	if ($UseGodotExporter) {
		& $godotExe --headless --path . --export-release $Preset $Output
		if ($LASTEXITCODE -eq 0) {
			Write-Host "Web build created at $outputDir"
			return
		}

		Write-Warning "Godot full Web export failed; falling back to manual Web template assembly."
	}

	if (!(Test-Path $webTemplate)) {
		throw "Missing Web export template: $webTemplate"
	}

	$pckOutput = Join-Path $outputDir "$baseName.pck"
	& $godotExe --headless --path . --export-pack $Preset $pckOutput
	if ($LASTEXITCODE -ne 0) {
		throw "Godot PCK export failed with exit code $LASTEXITCODE."
	}

	$tempTemplateDir = Join-Path $outputDir "_template"
	Remove-Item -LiteralPath $tempTemplateDir -Recurse -Force -ErrorAction SilentlyContinue
	New-Item -ItemType Directory -Force -Path $tempTemplateDir | Out-Null
	tar -xf $webTemplate -C $tempTemplateDir

	Copy-Item -LiteralPath (Join-Path $tempTemplateDir "godot.js") -Destination (Join-Path $outputDir "$baseName.js") -Force
	Copy-Item -LiteralPath (Join-Path $tempTemplateDir "godot.wasm") -Destination (Join-Path $outputDir "$baseName.wasm") -Force
	Copy-Item -LiteralPath (Join-Path $tempTemplateDir "godot.audio.worklet.js") -Destination (Join-Path $outputDir "$baseName.audio.worklet.js") -Force
	Copy-Item -LiteralPath (Join-Path $tempTemplateDir "godot.audio.position.worklet.js") -Destination (Join-Path $outputDir "$baseName.audio.position.worklet.js") -Force

	$wasmFile = Get-Item -LiteralPath (Join-Path $outputDir "$baseName.wasm")
	$pckFile = Get-Item -LiteralPath $pckOutput
	$config = @{
		args = @()
		canvasResizePolicy = 2
		executable = $baseName
		experimentalVK = $false
		fileSizes = @{
			"$baseName.pck" = $pckFile.Length
			"$baseName.wasm" = $wasmFile.Length
		}
		focusCanvas = $true
		gdextensionLibs = @()
		serviceWorker = ""
	}
	$configJson = $config | ConvertTo-Json -Compress -Depth 5
	$html = Get-Content -LiteralPath (Join-Path $tempTemplateDir "godot.html") -Raw
	$html = $html.Replace('$GODOT_PROJECT_NAME', 'MemeWave')
	$html = $html.Replace('$GODOT_SPLASH_COLOR', 'black')
	$html = $html.Replace('$GODOT_HEAD_INCLUDE', '')
	$html = $html.Replace('$GODOT_SPLASH_CLASSES', 'show-image--false fullsize--false use-filter--true')
	$html = $html.Replace('$GODOT_SPLASH', '')
	$html = $html.Replace('$GODOT_URL', "$baseName.js")
	$html = $html.Replace('$GODOT_CONFIG', $configJson)
	$html = $html.Replace('$GODOT_THREADS_ENABLED', 'false')
	Set-Content -LiteralPath $outputPath -Value $html -Encoding UTF8

	Remove-Item -LiteralPath $tempTemplateDir -Recurse -Force
	Write-Host "Web build created at $outputDir"
}
finally {
	Pop-Location
}
