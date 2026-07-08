[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('copy', 'cut')]
    [string] $Mode,

    [Parameter()]
    [string] $PathList,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Paths
)

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Write-Error 'This script must run in an STA PowerShell process. Use: pwsh -Sta -File set-file-clipboard.ps1 <copy|cut> <paths...>'
    exit 1
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

function Set-ClipboardDataObject {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.DataObject] $DataObject
    )

    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            [System.Windows.Forms.Clipboard]::SetDataObject($DataObject, $true)
            return
        }
        catch {
            if ($attempt -eq 5) {
                throw
            }

            Start-Sleep -Milliseconds 80
        }
    }
}

$inputPaths = Get-InputPaths

if (-not $inputPaths -or $inputPaths.Count -eq 0) {
    Write-Error 'No files were provided.'
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms

$fileList = [System.Collections.Specialized.StringCollection]::new()
$resolvedPaths = [System.Collections.Generic.List[string]]::new()

foreach ($path in $inputPaths) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }

    try {
        $resolved = Resolve-Path -LiteralPath $path -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty Path
    }
    catch {
        Write-Error "Path not found: $path"
        exit 1
    }

    if (-not (Test-Path -LiteralPath $resolved)) {
        Write-Error "Path not found: $resolved"
        exit 1
    }

    [void] $fileList.Add($resolved)
    [void] $resolvedPaths.Add($resolved)
}

if ($fileList.Count -eq 0) {
    Write-Error 'No valid files were provided.'
    exit 1
}

$dataObject = [System.Windows.Forms.DataObject]::new()
$dataObject.SetFileDropList($fileList)

# Shell uses Preferred DropEffect to distinguish copy from cut/move.
$dropEffect = if ($Mode -eq 'cut') { 2 } else { 1 }
$bytes = [BitConverter]::GetBytes([UInt32] $dropEffect)
$stream = [System.IO.MemoryStream]::new($bytes)
$dataObject.SetData('Preferred DropEffect', $stream)

Set-ClipboardDataObject -DataObject $dataObject

Write-Host ("Copied {0} item(s) to the Windows file clipboard as {1}." -f $fileList.Count, $Mode)
