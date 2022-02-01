[CmdletBinding()]
param (
	[Parameter()][string]$Family,
	[Parameter()][string]$Config)

function Format-Name {
	param (
		[Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$font
	)
	switch ($font.Extension) {
		".ttf" { "$($font.BaseName) (TrueType)" }
		".otf" { "$($font.BaseName) (OpenType)" }
	}
}

function Install-Font {
	param (
		[Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$font
	)
	Copy-Item -Path $font.FullName -Destination "C:\Windows\Fonts"
	$formatedFontName = Format-Name $font
	New-ItemProperty -Name $formatedFontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $font.Name -Force -ErrorAction SilentlyContinue | Out-Null
}

function Get-Font-Family {
	param (
		[Parameter(Mandatory = $true)][string]$fontFamily
	)
	$fontsPath = "$($env:TEMP)\fonts-$(New-Guid).json"
	$fontZipPath = "$($env:TEMP)\$Family_$(New-Guid)"
	$fontZipFileName = "$fontZipPath.zip"

	Invoke-WebRequest $Config -OutFile $fontsPath 
	$fonts = Get-Content $fontsPath | ConvertFrom-Json -AsHashtable
	Invoke-WebRequest $fonts[$Family] -OutFile $fontZipFileName
	Expand-Archive -LiteralPath $fontZipFileName -DestinationPath $fontZipPath
	$fontZipPath
}

$fontExpandPath = Get-Font-Family $Family
$fontFiles = Get-ChildItem $fontExpandPath -Filter "*.ttf"
foreach ($font in $fontFiles) {
	Install-Font $font
} 