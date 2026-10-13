param([Parameter(Mandatory = $true)][int]$TransportId)
$ErrorActionPreference = 'Stop'
$alphaAdb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $alphaAdb)) { throw 'Android platform-tools were not found.' }
Write-Host 'Phone model and Android version:'
& $alphaAdb -t $TransportId shell getprop ro.product.model
& $alphaAdb -t $TransportId shell getprop ro.build.version.release
Write-Host 'Google Play services version:'
& $alphaAdb -t $TransportId shell dumpsys package com.google.android.gms | Select-String 'versionName|versionCode'
Write-Host 'Maps errors (API keys redacted):'
& $alphaAdb -t $TransportId logcat -d -s 'Google Maps Android API' 'Google Maps Android API v2' 'MapsInitializer' 'GooglePlayServicesUtil' |
    ForEach-Object { $_ -replace 'AIza[0-9A-Za-z_-]+', '[redacted]' }
