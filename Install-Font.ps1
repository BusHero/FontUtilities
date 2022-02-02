[CmdletBinding()]
param (
	[Parameter()][string]$Family,
	[Parameter()][string]$Config)

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
	Write-Host "Copying fonts to C:\Windows\Fonts ..."
	Copy-Item -Path $font.FullName -Destination "C:\Windows\Fonts"
	$formatedFontName = Format-Name $font

	Write-Host "Set up register keys ..."
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

function Get-Font-Family {
	param (
		[Parameter(Mandatory = $true)][string]$fontFamily
	)
	$fontsPath = "$($env:TEMP)\fonts-$(New-Guid).json"
	$fontZipPath = "$($env:TEMP)\$Family_$(New-Guid)"
	$fontZipFileName = "$fontZipPath.zip"

	Write-Host "Downloading config file ..."
	Get-File -Source $Config -Destination $fontsPath
	$fonts = Get-Content $fontsPath | ConvertFrom-Json -AsHashtable
	
	Write-Host "Downloading font '$fontFamily' font family..."
	Get-File -Source $fonts[$Family] -Destination $fontZipFileName

	Write-Host "Unzipping archive ..."
	Expand-Archive -LiteralPath $fontZipFileName -DestinationPath $fontZipPath
	$fontZipPath
}

function Main {
	$fontExpandPath = Get-Font-Family $Family
	$fontFiles = Get-ChildItem $fontExpandPath -Filter "*.ttf"
	foreach ($font in $fontFiles) {
		Install-Font $font
	}
}

Main