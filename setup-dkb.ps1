param(
    [Parameter(Mandatory = $true)]
    [string]$Exefs,

    [Parameter(Mandatory = $true)]
    [string]$Romfs,

    [Parameter(Mandatory = $true)]
    [string]$Destination,

    [Parameter(Mandatory = $true)]
    [string]$ToolsPackage,

    [string]$Language = 'pt-BR',

    [ValidateRange(1, 64)]
    [int]$Jobs = 6,

    [switch]$Verify
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Resolve-ExistingDirectory([string]$Path, [string]$Name) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Name folder does not exist: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

$exefsPath = Resolve-ExistingDirectory $Exefs 'ExeFS'
$romfsPath = Resolve-ExistingDirectory $Romfs 'RomFS'
$toolsPath = Resolve-ExistingDirectory $ToolsPackage 'Tools package'
$destinationPath = [System.IO.Path]::GetFullPath($Destination)

foreach ($requiredFile in @('main', 'sdk', 'rtld', 'main.npdm')) {
    if (-not (Test-Path -LiteralPath (Join-Path $exefsPath $requiredFile) -PathType Leaf)) {
        throw "ExeFS is missing '$requiredFile': $exefsPath"
    }
}

$packedRomfs = (Test-Path -LiteralPath (Join-Path $romfsPath 'romfs.bin') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $romfsPath 'index.json') -PathType Leaf)
if (-not $packedRomfs -and -not (Get-ChildItem -LiteralPath $romfsPath -Force | Select-Object -First 1)) {
    throw "RomFS folder is empty: $romfsPath"
}

$python = Join-Path $toolsPath 'python\python.exe'
$installer = Join-Path $toolsPath 'installer\__main__.py'
$clang = Join-Path $toolsPath 'llvm\bin\clang.exe'
$ninja = Join-Path $toolsPath 'bin\ninja.exe'
$deps = Join-Path $toolsPath 'runtime\deps'
foreach ($requiredPath in @($python, $installer, $clang, $ninja, (Join-Path $deps 'include'), (Join-Path $deps 'lib'))) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Tools package is incomplete; missing: $requiredPath"
    }
}

$arguments = @(
    '-m', 'installer',
    '--game', 'bananza',
    '--exefs', $exefsPath,
    '--romfs', $romfsPath,
    '--dest', $destinationPath,
    '--root', $toolsPath,
    '--package', $toolsPath,
    '--lang', $Language,
    '--jobs', $Jobs.ToString()
)
if ($Verify) { $arguments += '--verify' }

Write-Host "Building Donkey Kong Bananza locally from the supplied dump."
Write-Host "Destination: $destinationPath"
Write-Host "The dump stays on this PC; it is not uploaded to GitHub."
& $python @arguments
if ($LASTEXITCODE -ne 0) {
    throw "The installer exited with code $LASTEXITCODE. Re-run this command to resume from completed steps."
}

Write-Host "Installation complete: $destinationPath"
