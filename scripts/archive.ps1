[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Destination,

    [Parameter()]
    [string] $PathList,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Paths
)

$ErrorActionPreference = 'Stop'

function Get-SevenZip {
    $configured = $env:YAZI_WINDOWS_CLIPBOARD_7Z
    if (-not [string]::IsNullOrWhiteSpace($configured) -and (Test-Path -LiteralPath $configured -PathType Leaf)) {
        return $configured
    }

    $command = Get-Command 7z.exe -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty Source
    if ($command) {
        return $command
    }

    $candidates = @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe',
        'D:\7zip\7-Zip\7z.exe'
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    throw '7-Zip was not found. Install 7-Zip or set YAZI_WINDOWS_CLIPBOARD_7Z to 7z.exe.'
}

function Get-InputPaths {
    $items = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($PathList)) {
        if (-not (Test-Path -LiteralPath $PathList -PathType Leaf)) {
            Write-Error "Path list not found: $PathList"
            exit 1
        }

        Get-Content -LiteralPath $PathList -Encoding UTF8 |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { [void] $items.Add($_) }
    }

    foreach ($path in $Paths) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            [void] $items.Add($path)
        }
    }

    return $items
}

function Get-AvailablePath {
    param(
        [Parameter(Mandatory)]
        [string] $Directory,

        [Parameter(Mandatory)]
        [string] $FileName
    )

    $candidate = Join-Path -Path $Directory -ChildPath $FileName
    if (-not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $stem = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $extension = [System.IO.Path]::GetExtension($FileName)
    $candidate = Join-Path -Path $Directory -ChildPath ("{0} - Copy{1}" -f $stem, $extension)

    if (-not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $index = 2
    while ($true) {
        $candidate = Join-Path -Path $Directory -ChildPath ("{0} - Copy ({1}){2}" -f $stem, $index, $extension)
        if (-not (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }

        $index++
    }
}

try {
    $destinationPath = Resolve-Path -LiteralPath $Destination -ErrorAction Stop |
        Select-Object -First 1 -ExpandProperty Path
}
catch {
    Write-Error "Destination not found: $Destination"
    exit 1
}

if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
    Write-Error "Destination is not a directory: $destinationPath"
    exit 1
}

$items = @(
    Get-InputPaths |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object {
            Resolve-Path -LiteralPath $_ -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty Path
        } |
        Where-Object { $_ } |
        Select-Object -Unique
)

if ($items.Count -eq 0) {
    Write-Error 'No valid files were provided.'
    exit 1
}

if ($items.Count -eq 1) {
    $item = Get-Item -LiteralPath $items[0]
    $archiveName = "$($item.BaseName).zip"
}
else {
    $directoryName = Split-Path -Path $destinationPath -Leaf
    if ([string]::IsNullOrWhiteSpace($directoryName)) {
        $directoryName = 'Archive'
    }

    $archiveName = "$directoryName.zip"
}

$sevenZip = Get-SevenZip
$archivePath = Get-AvailablePath -Directory $destinationPath -FileName $archiveName

& $sevenZip a -tzip -- $archivePath @items | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "7-Zip archive failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

Write-Host "Created: $archivePath"
