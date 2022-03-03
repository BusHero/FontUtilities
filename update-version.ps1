[CmdletBinding(PositionalBinding = $false)]
Param
(
  [Parameter(Mandatory = $true)]
  [ValidateScript({
        Test-Path $_ -PathType leaf -Include '*.psd1'
  })]
  [string]
  $Path,
  $Major,
  $Minor,
  $Build,
  $Revision,

  [switch]
  $IncrementMinor,

  [switch]
  $IncrimentMajor
)


$Module = Test-ModuleManifest -Path $Path
$Major = switch ($Major) {
	$null { $Module.Version.Major }
	default { $Major }
}
$Minor = switch ($Minor) {
	$null { $Module.Version.Minor }
	default { $Minor }
}
$Build = switch ($Build) {
	$null { $Module.Version.Build }
	default { $Build }
}
$Revision = switch ($Revision) {
	$null { $Module.Version.Revision }
	default { $Revision }
}

if ($IncrimentMajor) {
	$Major++
}

if ($IncrementMinor) {
	$Minor++
}

$version = switch ($Revision) {
	-1 { New-Object System.Version -ArgumentList $Major, $Minor, $Build }
	default { New-Object System.Version -ArgumentList $Major, $Minor, $Build, $Revision }
}
Update-ModuleManifest -Path $Path -ModuleVersion $version