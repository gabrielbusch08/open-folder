# open-folder: opens a Google Drive folder in Windows Explorer from an
# "openfolder:<folder name>" link, and a Todoist project from an
# "opentodoist:<project ID>" link. install.txt saves this file in
# %LOCALAPPDATA%\open-folder and registers it for both link types (this user
# only), run by Windows' own PowerShell through a hidden console.
#
# A script, not a program of its own: Windows 11's Smart App Control blocks
# unsigned programs, and a program built on the PC is unsigned. PowerShell is
# signed by Microsoft. With Smart App Control on, PowerShell may run this
# script in Constrained Language mode, so it uses cmdlets and plain string
# operations only: no Add-Type, no .NET classes beyond the basic types.
# Kept to ASCII, because Windows PowerShell reads a file without a BOM as ANSI.
#
# The link carries a folder NAME, not a path, so it keeps working when a
# project folder moves between stages. The name is only compared with folder
# names found in the Drive; it is never used to build a path (except, after a
# Yes, as the name of a new folder inside 01 PROJECTS\IN PROGRESS), and the
# script only ever opens folders.
#
# When it has something to say or ask, it starts itself again in a visible
# PowerShell window with -Interactive.
param(
  [string]$Link = '',
  [switch]$Interactive
)

$ErrorActionPreference = 'Stop'
$AppFolder = Split-Path -Parent $PSCommandPath
# Searched in this order; the first folder whose name matches wins, shallower
# before deeper (Areas, then projects in their stage folders).
$SearchRoots = @('02 AREAS', '01 PROJECTS')
$MaxDepth = 3

# A short log next to the script, for when something doesn't work:
# %LOCALAPPDATA%\open-folder\log.txt, cut back to its last 100 lines.
function Write-Log([string]$Line) {
  try {
    $path = Join-Path $AppFolder 'log.txt'
    $lines = @()
    if (Test-Path -LiteralPath $path) { $lines = @(Get-Content -LiteralPath $path) }
    $lines += (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') + '  ' + $Line
    $lines | Select-Object -Last 100 | Set-Content -LiteralPath $path
  } catch { }
}

# Compare names loosely: no case, accents, spaces, punctuation or emoji, so
# "Compras / Aquisicoes" with accents in Notion matches "Compras _ Aquisicoes"
# in Drive.
function Get-Key([string]$Name) {
  $s = "$Name".ToLowerInvariant()
  $s = $s -replace '[\u00e0-\u00e5]', 'a' -replace '[\u00e8-\u00eb]', 'e' -replace '[\u00ec-\u00ef]', 'i'
  $s = $s -replace '[\u00f2-\u00f6]', 'o' -replace '[\u00f9-\u00fc]', 'u' -replace '\u00e7', 'c' -replace '\u00f1', 'n'
  $s = $s -replace '\p{Mn}', ''
  return ($s -replace '[^\p{L}\p{N}]', '')
}

# "openfolder:Notion%20Setup" or "openfolder://Notion%20Setup/" -> "Notion Setup"
function Get-NameFromLink([string]$Text) {
  $s = $Text -replace '^openfolder:', ''
  $s = $s.Trim('/')
  try { $s = [uri]::UnescapeDataString($s) } catch { $s = $s -replace '%20', ' ' }
  return $s.Trim()
}

# The page name as a folder name: characters Windows doesn't allow in names
# (like / or :) become "-". Empty if nothing usable is left, so a name can
# never point outside IN PROGRESS.
function Get-SafeFolderName([string]$Name) {
  $n = ($Name -replace '[\\/:*?"<>|\x00-\x1f]', '-').Trim().TrimEnd('. ')
  if ($n.Length -gt 100) { $n = $n.Substring(0, 100).Trim() }
  if ($n -eq '.' -or $n -eq '..' -or (Get-Key $n).Length -eq 0) { return '' }
  return $n
}

# The Drive's "My Drive" folder: from drive.txt if present, else the first
# My Drive / Meu Drive found, preferring one that holds "02 AREAS" (there may
# be one per Google account).
function Find-DriveRoot {
  $txt = Join-Path $AppFolder 'drive.txt'
  if (Test-Path -LiteralPath $txt) {
    $p = ("" + (Get-Content -LiteralPath $txt -Raw)).Trim().Trim('"')
    if ($p -and (Test-Path -LiteralPath $p -PathType Container)) { return $p }
  }
  $bases = @($env:USERPROFILE, (Join-Path $env:USERPROFILE 'Google Drive'))
  foreach ($d in @(Get-PSDrive -PSProvider FileSystem)) {
    if ("$($d.DisplayRoot)".StartsWith('\\')) { continue }  # network drives
    $bases += $d.Root
  }
  $first = ''
  foreach ($b in $bases) {
    foreach ($n in @('My Drive', 'Meu Drive')) {
      $p = Join-Path $b $n
      try {
        if (-not (Test-Path -LiteralPath $p -PathType Container)) { continue }
        if (Test-Path -LiteralPath (Join-Path $p '02 AREAS') -PathType Container) { return $p }
        if (-not $first) { $first = $p }
      } catch { }
    }
  }
  return $first
}

# Breadth-first, so a shallow match beats a deeper folder with the same name.
function Find-Folder([string]$Drive, [string]$Key) {
  $level = @()
  foreach ($r in $SearchRoots) {
    $p = Join-Path $Drive $r
    if (Test-Path -LiteralPath $p -PathType Container) { $level += $p }
  }
  for ($depth = 1; $depth -le $MaxDepth -and $level.Count -gt 0; $depth++) {
    $next = @()
    foreach ($dir in $level) {
      $subs = @()
      try { $subs = @(Get-ChildItem -LiteralPath $dir -Directory -ErrorAction Stop | Sort-Object Name) } catch { continue }
      foreach ($sub in $subs) {
        if ((Get-Key $sub.Name) -eq $Key) { return $sub.FullName }
        $next += $sub.FullName
      }
    }
    $level = $next
  }
  return ''
}

function Open-Folder([string]$Folder) {
  Write-Log "open $Folder"
  Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $Folder + '"')
}

# Hidden run: start again in a window that can talk. Interactive run: say it.
function Request-Window {
  Write-Log 'needs a window: starting again with -Interactive'
  $ps = Join-Path $PSHOME 'powershell.exe'
  Start-Process -FilePath $ps -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', ('"' + $PSCommandPath + '"'), '-Interactive', ('"' + $Link + '"'))
}

function Show-Message([string]$Message) {
  Write-Host ''
  Write-Host $Message
  Write-Host ''
  Read-Host 'Press Enter to close' | Out-Null
}

# "opentodoist:6ghQ34VjfcV5PX8J" -> the Todoist app on that project.
function Open-Todoist([string]$Text) {
  $id = ($Text -replace '^opentodoist:', '').Trim('/')
  if ($id -notmatch '^[A-Za-z0-9]+$') { return 1 }
  Start-Process -FilePath ('todoist://project?id=' + $id)
  return 0
}

function Open-DriveFolder([string]$Text) {
  $name = Get-NameFromLink $Text
  $drive = Find-DriveRoot
  if (-not $drive) {
    if (-not $Interactive) { Request-Window; return 1 }
    Show-Message ("Couldn't find your Google Drive folder (My Drive or Meu Drive).`n`n" +
      "Is Google Drive for desktop running? If your Drive is somewhere else, put its path in`n" +
      (Join-Path $AppFolder 'drive.txt'))
    return 1
  }
  $key = Get-Key $name
  if (-not $key) { Open-Folder $drive; return 0 }
  $found = Find-Folder $drive $key
  if ($found) { Open-Folder $found; return 0 }

  if (-not $Interactive) { Request-Window; return 1 }
  # No folder yet: offer to make one for the project in IN PROGRESS.
  $inProgress = Join-Path (Join-Path $drive '01 PROJECTS') 'IN PROGRESS'
  $folderName = Get-SafeFolderName $name
  if ($folderName -and (Test-Path -LiteralPath $inProgress -PathType Container)) {
    Write-Host ''
    Write-Host "No folder named `"$name`" in your Drive yet."
    Write-Host ''
    $answer = Read-Host 'Create it in 01 PROJECTS\IN PROGRESS? (y/n)'
    if ($answer -notmatch '^\s*[yYsS]') { Write-Log 'create: answered no'; return 1 }
    $created = Join-Path $inProgress $folderName
    New-Item -ItemType Directory -Force -Path $created | Out-Null
    Write-Log "created $created"
    Open-Folder $created
    return 0
  }
  $fallback = Join-Path $drive '01 PROJECTS'
  if (-not (Test-Path -LiteralPath $fallback -PathType Container)) { $fallback = $drive }
  Open-Folder $fallback
  Show-Message ("No folder named `"$name`" in your Drive's 02 AREAS or 01 PROJECTS.`n`n" +
    "The Drive folder needs the same name as the Notion page. Opened $fallback instead.")
  return 1
}

Write-Log ("link $Link" + $(if ($Interactive) { ' (window)' } else { '' }) +
  "; language mode $($ExecutionContext.SessionState.LanguageMode)")
try {
  if ($Link -match '^opentodoist:') { $result = Open-Todoist $Link }
  else { $result = Open-DriveFolder $Link }
} catch {
  Write-Log "error: $_"
  if ($Interactive) { Show-Message "Something went wrong: $_" }
  $result = 1
}
Write-Log "done, result $result"
exit $result
