[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Destination = "."
)

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Write-Error 'This script must run in an STA PowerShell process. Use: pwsh -Sta -File paste-file-clipboard.ps1 <destination>'
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms

try {
    $destinationPath = (Resolve-Path -LiteralPath $Destination -ErrorAction Stop |
        Select-Object -First 1 -ExpandProperty Path)
}
catch {
    Write-Error "Destination not found: $Destination"
    exit 1
}

if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
    Write-Error "Destination is not a directory: $destinationPath"
    exit 1
}

$dataObject = [System.Windows.Forms.Clipboard]::GetDataObject()

if (-not $dataObject) {
    Write-Error 'Clipboard is empty.'
    exit 1
}

$fileDropList = $dataObject.GetData([System.Windows.Forms.DataFormats]::FileDrop)

if (-not $fileDropList -or $fileDropList.Count -eq 0) {
    Write-Error 'Clipboard does not contain files.'
    exit 1
}

$dropEffect = 1
$effectData = $dataObject.GetData('Preferred DropEffect')

if ($effectData -is [System.IO.Stream]) {
    $buffer = [byte[]]::new(4)
    $effectData.Position = 0
    [void] $effectData.Read($buffer, 0, 4)
    $dropEffect = [BitConverter]::ToUInt32($buffer, 0)
}
elseif ($effectData -is [byte[]] -and $effectData.Length -ge 4) {
    $dropEffect = [BitConverter]::ToUInt32($effectData, 0)
}

$shouldMove = (($dropEffect -band 2) -eq 2)
$action = if ($shouldMove) { 'move' } else { 'copy' }
$count = 0

function Get-AvailablePath {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter()]
        [switch] $Container
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Path
    }

    $parent = [System.IO.Path]::GetDirectoryName($Path)
    $name = if ($Container) {
        [System.IO.Path]::GetFileName($Path)
    }
    else {
        [System.IO.Path]::GetFileNameWithoutExtension($Path)
    }
    $extension = if ($Container) { '' } else { [System.IO.Path]::GetExtension($Path) }

    $candidate = Join-Path $parent ("{0} - Copy{1}" -f $name, $extension)

    if (-not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $index = 2

    while ($true) {
        $candidate = Join-Path $parent ("{0} - Copy ({1}){2}" -f $name, $index, $extension)

        if (-not (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }

        $index++
    }
}

foreach ($source in $fileDropList) {
    if (-not (Test-Path -LiteralPath $source)) {
        Write-Warning "Skipped missing path: $source"
        continue
    }

    $target = Join-Path $destinationPath ([System.IO.Path]::GetFileName($source))
    $target = Get-AvailablePath -Path $target -Container:(Test-Path -LiteralPath $source -PathType Container)

    if ($shouldMove) {
        Move-Item -LiteralPath $source -Destination $target -ErrorAction Stop
    }
    else {
        Copy-Item -LiteralPath $source -Destination $target -Recurse -ErrorAction Stop
    }

    $count++
}

if ($shouldMove -and $count -gt 0) {
    [System.Windows.Forms.Clipboard]::Clear()
}

Write-Host ("Pasted {0} item(s) to {1} as {2}." -f $count, $destinationPath, $action)
