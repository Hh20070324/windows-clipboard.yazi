[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('copy', 'cut')]
    [string] $Mode,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Paths
)

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Write-Error 'This script must run in an STA PowerShell process. Use: pwsh -Sta -File set-file-clipboard.ps1 <copy|cut> <paths...>'
    exit 1
}

if (-not $Paths -or $Paths.Count -eq 0) {
    Write-Error 'No files were provided.'
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms

$fileList = [System.Collections.Specialized.StringCollection]::new()
$resolvedPaths = [System.Collections.Generic.List[string]]::new()

foreach ($path in $Paths) {
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

[System.Windows.Forms.Clipboard]::SetDataObject($dataObject, $true)

Write-Host ("Copied {0} item(s) to the Windows file clipboard as {1}." -f $fileList.Count, $Mode)
