$Script:ConfigUrl = 'https://raw.githubusercontent.com/BusHero/Install-Font/main/fonts.json'
$Script:ConfigPath = '.\fonts.json'
$Script:FontsCachePath = '.\.fonts'

function Update-Config {
	Invoke-WebRequest $Script:ConfigUrl -OutFile $ConfigPath
}

function Write-Error($message) {
	[Console]::ForegroundColor = 'red'
	[Console]::Error.WriteLine($message)
	[Console]::ResetColor()
	exit
}

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
	Write-Information "Copying fonts to C:\Windows\Fonts ..."
	Copy-Item -Path $font.FullName -Destination "C:\Windows\Fonts"
	$formatedFontName = Format-Name $font

	Write-Information "Set up register keys ..."
	New-ItemProperty -Name $formatedFontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $font.Name -Force -ErrorAction SilentlyContinue | Out-Null
}

function Get-File {
	param (
		[string]$Source,
		[string]$Destination
	)
	try {
		Invoke-WebRequest $Source -OutFile $Destination
	}
	catch [Microsoft.PowerShell.Commands.HttpResponseException] {
		Write-Output $PSItem.ErrorDetails.Message
	}
}

function Get-FontFamily {
	param (
		[Parameter(Mandatory = $true)][string]$fontFamily
	)
	$fontFamilyZip = "${Script:FontsCachePath}\$fontFamily.zip"
	$fontFamilyPath = "${Script:FontsCachePath}\$fontFamily"
	$fonts = Get-Content $Script:ConfigPath | ConvertFrom-Json -AsHashtable

	Write-Information "Downloading font '$fontFamily' font family..."
	Get-File -Source $fonts[$Family] -Destination $fontFamilyZip

	Write-Information "Unzipping archive ..."
	Expand-Archive -LiteralPath $fontZipFileName -DestinationPath $fontFamilyPath
	$fontFamilyPath
}

function Install-FontFamily {
	param ([Parameter()][string]$Family)
	$fontFamilyZip = "${Script:FontsCachePath}\$Family.zip"
	$fontFamilyPath = "${Script:FontsCachePath}\$Family"
	$fonts = Get-Content $Script:ConfigPath | ConvertFrom-Json -AsHashtable

	Write-Information "Downloading font '$fontFamily' font family..."
	Get-File -Source $fonts[$Family] -Destination $fontFamilyZip

	Write-Information "Unzipping archive ..."
	Expand-Archive -LiteralPath $fontFamilyZip -DestinationPath $fontFamilyPath

	$fontFiles = Get-ChildItem $fontExpandPath -Filter "*.ttf"

	foreach ($font in $fontFiles) {
		Install-Font $font
	}

	Remove-Item $fontFamilyPath -Recurse -Force
}

Export-ModuleMember Install-FontFamily
Export-ModuleMember Update-Config

Update-Config
mkdir $Script:FontsCachePath -Force