# 1. Find font
# 2. Download font in Zip folder
# 3. Unzip folder
# 4. Install font
# 4.1 Copy font to the C:\Windows\Fonts
# 4.2 Add font name to the windows registry HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts

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

function Expand-Fonts {
	param (
		[Parameter(Mandatory = $true)][string]$font
	)
	$item = Get-Item $font
	$fontPath = "$($env:TEMP)\$($item.BaseName)_$(New-Guid)"
	Expand-Archive -LiteralPath $item.FullName -DestinationPath $fontPath
	$fontPath	
}


$fontZipPath = "$($env:TEMP)\Roboto_$(New-Guid).zip"
Invoke-WebRequest https://fonts.google.com/download?family=Roboto -OutFile $fontZipPath
$fontExpandPath = Expand-Fonts $fontZipPath
$fontFiles = Get-ChildItem $fontExpandPath -Filter "*.ttf"

foreach ($font in $fontFiles) {
	Install-Font $font
} 

Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts(Test)"
