# Installs open-folder for this Windows user, so Notion's "Folder" links
# open the project's Google Drive folder in Explorer, and both Folder and
# Todoist links put the browser back behind Notion. No admin rights needed.
# Run it again any time to update. Run from any window:
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://gabrielbusch08.github.io/open-folder/install.ps1 | iex"
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -eq 'Core') { throw 'Run this with Windows PowerShell (powershell.exe), not PowerShell 7.' }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base = 'https://gabrielbusch08.github.io/open-folder'
$dir = Join-Path $env:LOCALAPPDATA 'open-folder'
$src = Join-Path $dir 'OpenFolder.cs'
$exe = Join-Path $dir 'open-folder.exe'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

Write-Host 'Downloading and building open-folder.exe...'
Invoke-WebRequest "$base/OpenFolder.cs" -OutFile $src -UseBasicParsing
if (Test-Path $exe) { Remove-Item $exe -Force }
Add-Type -Path $src -OutputAssembly $exe -OutputType WindowsApplication -ReferencedAssemblies System.Windows.Forms

Write-Host 'Registering openfolder: and opentodoist: links for this user...'
foreach ($scheme in 'openfolder', 'opentodoist') {
  $key = "HKCU:\Software\Classes\$scheme"
  New-Item -Path $key -Force -Value "URL:$scheme (open-folder)" | Out-Null
  New-ItemProperty -Path $key -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
  New-Item -Path "$key\DefaultIcon" -Force -Value 'explorer.exe,0' | Out-Null
  New-Item -Path "$key\shell\open\command" -Force -Value "`"$exe`" `"%1`"" | Out-Null
}

# Same search as the program, to say where it will look.
$found = $null
$bases = @($env:USERPROFILE, (Join-Path $env:USERPROFILE 'Google Drive')) + (Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Root })
foreach ($b in $bases) { foreach ($n in 'My Drive', 'Meu Drive') {
  $p = Join-Path $b $n
  if (-not $found -and (Test-Path (Join-Path $p '02 AREAS'))) { $found = $p }
} }
Write-Host ''
if ($found) {
  Write-Host "Done. Your Drive: $found" -ForegroundColor Green
  Write-Host 'Test it: click a Folder link in Notion. Firefox asks once which app to use: pick open-folder and tick "Always".'
} else {
  Write-Host 'Installed, but no My Drive / Meu Drive folder with "02 AREAS" was found.' -ForegroundColor Yellow
  Write-Host "Start Google Drive for desktop, or put your Drive's path in $(Join-Path $dir 'drive.txt')"
}

# Tell the default browser (Firefox) to send Todoist links through open-folder
# from now on: the Todoist page keeps that setting per browser.
Write-Host 'Opening a page in your browser to switch Todoist links over to open-folder...'
Start-Process 'https://gabrielbusch08.github.io/open-todoist/#helper-on'
