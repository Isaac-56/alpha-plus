[CmdletBinding()]
param([string]$ProjectPath = 'C:\Projects\alpha_plus')

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path.TrimEnd('\', '/')
$packageRoot = $PSScriptRoot.TrimEnd('\', '/')
if ($packageRoot.Equals($projectRoot, [StringComparison]::OrdinalIgnoreCase) -or
    $packageRoot.StartsWith($projectRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Extract the ZIP outside alpha_plus, for example in Downloads, then run this script.'
}

$payloadFiles = @(
    'lib/core/widgets/onboarding_scaffold.dart'
    'lib/features/auth/presentation/phone_login_screen.dart'
    'lib/features/auth/presentation/otp_screen.dart'
    'lib/features/auth/presentation/driver_name_screen.dart'
    'test/widget_test.dart'
    'ALPHA_PLUS_PAGE_QUEUE.md'
)
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -PathType Leaf)) {
    throw 'Select the Alpha Plus project root, where pubspec.yaml is located.'
}
$pubspec = Get-Content -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Raw
if ($pubspec -notmatch '(?m)^name:\s*alpha_plus\s*$') {
    throw 'This update is for Alpha Plus, not the passenger app.'
}
foreach ($relative in $payloadFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $packageRoot $relative) -PathType Leaf)) {
        throw "The ZIP is incomplete. Missing: $relative"
    }
}
foreach ($relative in @(
    'lib/features/auth/data/driver_auth_service.dart',
    'lib/features/profile/data/driver_profile_repository.dart',
    'lib/core/widgets/alpha_back_button.dart'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $relative) -PathType Leaf)) {
        throw "The selected project is incomplete. Missing: $relative"
    }
}
foreach ($command in @('flutter', 'dart', 'git')) {
    $null = Get-Command $command -ErrorAction Stop
}

$backupName = 'alpha_plus-before-auth-pages-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$backupRoot = Join-Path (Split-Path $projectRoot -Parent) $backupName
$null = New-Item -ItemType Directory -Path $backupRoot
foreach ($relative in (@($payloadFiles) + @('pubspec.lock'))) {
    $original = Join-Path $projectRoot $relative
    if (Test-Path -LiteralPath $original -PathType Leaf) {
        $saved = Join-Path $backupRoot $relative
        $null = New-Item -ItemType Directory -Path (Split-Path $saved -Parent) -Force
        Copy-Item -LiteralPath $original -Destination $saved
    }
}
Write-Host "Original files backed up outside the project: $backupRoot"

foreach ($relative in $payloadFiles) {
    $destination = Join-Path $projectRoot $relative
    $null = New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force
    Copy-Item -LiteralPath (Join-Path $packageRoot $relative) -Destination $destination -Force
}

$dartFiles = @($payloadFiles | Where-Object { $_.EndsWith('.dart') })
Push-Location -LiteralPath $projectRoot
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed. Stop here and send the output.' }
    & dart format @dartFiles
    if ($LASTEXITCODE -ne 0) { throw 'Formatting failed. Stop here and send the output.' }
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Analysis failed. Do not commit; send the errors.' }
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed. Do not commit; send the failing test output.' }
    & git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace checks failed. Review the reported files before committing.' }
} finally {
    Pop-Location
}
Write-Host 'AUTH PAGE CHECKS PASSED. Test the pages on your phone next.'
Write-Host 'No database settings, API keys, security rules, or remote Git branches were changed.'
