# 1. Find font
# 1.1 Download Json
# 1.2 Parse Json
# 2. Download font in Zip folder Done
# 3. Unzip folder Done
# 4. Install font Done
# 4.1 Copy font to the C:\Windows\Fonts Done
# 4.2 Add font name to the windows registry HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts Done

[CmdletBinding()]
param (
	[Parameter()]
	[string]
	$Family
)

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
	New-ItemProperty -Name $formatedFontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts(Test)" -PropertyType string -Value $font.Name -Force -ErrorAction SilentlyContinue | Out-Null
}

function Get-Font-Family {
	param (
		[Parameter(Mandatory = $true)][string]$fontFamily
	)
	$fonts = Get-Content .\fonts.json | ConvertFrom-Json -AsHashtable
	$fontZipPath = "$($env:TEMP)\$Family_$(New-Guid)"
	$fontZipFileName = "$fontZipPath.zip"
	Invoke-WebRequest $fonts[$Family] -OutFile $fontZipFileName
	Expand-Archive -LiteralPath $fontZipFileName -DestinationPath $fontZipPath
	$fontZipPath
}

$fontExpandPath = Get-Font-Family $Family
$fontFiles = Get-ChildItem $fontExpandPath -Filter "*.ttf"
foreach ($font in $fontFiles) {
	Install-Font $font
} 

Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts(Test)"
