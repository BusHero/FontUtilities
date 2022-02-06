#region Variables

$Script:foo = 'foo'
$Script:ConfigUrl = 'https://raw.githubusercontent.com/BusHero/Install-Font/main/fonts.json'
$Script:ConfigPath = "$PSScriptRoot\fonts.json"
$Script:FontsCachePath = "$PScriptRoot\.fonts"

#endregion

#region Private Functions

#endregion

#region Public Methods

function Get-Foo {
    $script:foo
}

function Update-Config {
	Write-Host $Script:ConfigPath	
	Invoke-WebRequest $Script:ConfigUrl -OutFile $Script:ConfigPath
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
	Write-Output "Copying fonts to C:\Windows\Fonts ..."
	Copy-Item -Path $font.FullName -Destination "C:\Windows\Fonts"
	$formatedFontName = Format-Name $font

	Write-Output "Set up register keys ..."
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

function Install-FontFamily {
	param ([Parameter()][string]$Family)
	$fontFamilyZip = "${Script:FontsCachePath}\$Family.zip"
	$fontFamilyPath = "${Script:FontsCachePath}\$Family"
	$fonts = Get-Content $Script:ConfigPath | ConvertFrom-Json -AsHashtable
	Write-Output "Downloading font '$fontFamily' font family..."
	Get-File -Source $fonts[$Family] -Destination $fontFamilyZip

	Write-Output "Unzipping archive ..."
	Expand-Archive -LiteralPath $fontFamilyZip -DestinationPath $fontFamilyPath

	$fontFiles = Get-ChildItem $fontExpandPath -Filter "*.ttf"

	foreach ($font in $fontFiles) {
		Install-Font $font
	}

	Remove-Item $fontFamilyPath -Recurse -Force
}

#endregion

Export-ModuleMember Install-FontFamily
Export-ModuleMember Update-Config

Update-Config
mkdir $Script:FontsCachePath -Force
