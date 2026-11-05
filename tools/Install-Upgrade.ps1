# Qingli local ZIP installer/updater. Preview unless -Apply is specified.
# No Rainmeter process control, directory deletion, or global configuration edits.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SkinsDirectory,
    [switch]$Apply
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-Sha256([string]$Path) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $stream = $null
    try {
        $stream = [IO.File]::OpenRead($Path)
        return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '').ToLowerInvariant()
    } finally {
        if ($stream) { $stream.Dispose() }
        $algorithm.Dispose()
    }
}

function Assert-NoReparseChain([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Directory links and reparse points are not supported.'
            }
        }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
}

function Get-SafeFiles([string]$Directory) {
    $pending = New-Object 'Collections.Generic.Stack[string]'
    $pending.Push($Directory)
    while ($pending.Count -gt 0) {
        $folder = $pending.Pop()
        foreach ($item in Get-ChildItem -LiteralPath $folder -Force) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'The payload contains a directory link or reparse point.'
            }
            if ($item.PSIsContainer) { $pending.Push($item.FullName) }
            else { $item }
        }
    }
}

try {
    $packageRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $sourceRoot = [IO.Path]::GetFullPath((Join-Path $packageRoot 'Qingli'))
    Assert-NoReparseChain $sourceRoot
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) { throw 'Qingli payload is missing beside tools.' }
    if (-not [IO.Path]::IsPathRooted($SkinsDirectory)) { throw 'Use the full local path to a Skins directory.' }
    $skinsRoot = [IO.Path]::GetFullPath($SkinsDirectory).TrimEnd('\')
    if ($skinsRoot -notmatch '^[A-Za-z]:\\' -or [IO.Path]::GetFileName($skinsRoot) -ine 'Skins') {
        throw 'The destination must be a local directory named Skins.'
    }
    if ((Test-Path -LiteralPath $skinsRoot) -and -not (Test-Path -LiteralPath $skinsRoot -PathType Container)) { throw 'Skins is not a directory.' }
    $destination = [IO.Path]::GetFullPath((Join-Path $skinsRoot 'Qingli'))
    if ($destination.Equals($packageRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $destination.StartsWith($packageRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
        $packageRoot.StartsWith($destination + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The source package and destination overlap.'
    }
    Assert-NoReparseChain $destination
    if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Container)) { throw 'Qingli destination is not a directory.' }

    $manifestPath = Join-Path $sourceRoot 'MANIFEST.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $entries = @{}
    foreach ($property in $manifest.PSObject.Properties) {
        $relative = $property.Name.Replace('\', '/')
        $parts = $relative.Split('/')
        if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains(':') -or
            ($parts -contains '..') -or ($parts -contains '.') -or ($parts -contains '') -or
            $relative -ieq 'MANIFEST.json') { throw 'Invalid manifest path.' }
        if ($entries.ContainsKey($relative) -or $property.Value -isnot [string] -or $property.Value -notmatch '^[a-fA-F0-9]{64}$') {
            throw 'Duplicate or malformed manifest entry.'
        }
        $entries[$relative] = $property.Value
    }
    if ($entries.Count -lt 1) { throw 'Empty payload manifest.' }
    $payload = @(Get-SafeFiles $sourceRoot | Sort-Object FullName)
    if ($payload.Count -ne $entries.Count + 1) { throw 'The payload file set differs from the manifest.' }
    foreach ($file in $payload) {
        $relative = $file.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
        if ($relative -ne 'MANIFEST.json') {
            if (-not $entries.ContainsKey($relative)) { throw 'Unexpected payload file.' }
            if ((Get-Sha256 $file.FullName) -ine $entries[$relative]) { throw 'Payload hash mismatch.' }
        }
        if ($relative -match '(?i)(QWeather\.local\.json$|(?:^|/)Rainmeter\.ini$|\.log$|\.bak$|\.tmp$|cache.*\.json$|\.(?:exe|dll|lnk|ttf|otf)$|(?:^|/)@UpgradeBackup/)') {
            throw 'The payload contains a private runtime file or unsupported binary.'
        }
    }

    $protected = @(
        '@Resources/Refined/Settings.inc',
        '@Resources/Refined/Accent.inc',
        '@Resources/Refined/Material.inc',
        '@Resources/Refined/QWeather.local.json'
    )
    $plan = @()
    foreach ($file in $payload) {
        $relative = $file.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
        $target = [IO.Path]::GetFullPath((Join-Path $destination $relative.Replace('/', '\')))
        if (-not $target.StartsWith($destination + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'A destination path escaped Qingli.' }
        Assert-NoReparseChain $target
        $exists = Test-Path -LiteralPath $target
        if ($exists -and -not (Test-Path -LiteralPath $target -PathType Leaf)) { throw 'A destination file is occupied by a directory.' }
        $action = 'CopyNew'
        if ($exists) {
            if ($protected -contains $relative) { $action = 'Preserve' }
            elseif ((Get-Sha256 $target) -eq (Get-Sha256 $file.FullName)) { $action = 'Unchanged' }
            else { $action = 'Update' }
        }
        $plan += [pscustomobject]@{ Action=$action; Relative=$relative; Source=$file.FullName; Target=$target }
    }
    Write-Output ('Target: ' + $destination)
    foreach ($item in $plan) { Write-Output ($item.Action + ' ' + $item.Relative) }
    Write-Output 'Existing QWeather.local.json and files absent from the package are never removed or overwritten.'
    if (-not $Apply) { Write-Output 'PREVIEW ONLY. No files were written. Use -Apply after reviewing the destination.'; exit 0 }

    # All validation finishes before the first destination mutation.
    $backupRoot = Join-Path $destination ('@UpgradeBackup\' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fffffff') + '-' + [Guid]::NewGuid().ToString('N'))
    foreach ($item in $plan) {
        if ($item.Action -eq 'Preserve' -or $item.Action -eq 'Unchanged') { continue }
        Assert-NoReparseChain $item.Target
        if ($item.Action -eq 'Update') {
            $backup = Join-Path $backupRoot $item.Relative.Replace('/', '\')
            Assert-NoReparseChain $backup
            $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($backup)) -Force
            Copy-Item -LiteralPath $item.Target -Destination $backup -ErrorAction Stop
        }
        $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($item.Target)) -Force
        Copy-Item -LiteralPath $item.Source -Destination $item.Target -Force -ErrorAction Stop
    }
    Write-Output 'APPLIED. Rainmeter was not started, stopped, refreshed, or reconfigured.'
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
