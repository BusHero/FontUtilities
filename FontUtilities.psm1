$script:fonts = @{}

function Add-Font {
	param($family, $url)
	$script:fonts[$family] = $url
}

function Get-Font {
	param($family)
	$script:fonts[$family]
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

function Install-FontFile {
	param(
		[Parameter(Mandatory = $true)][string]$FontFile,
		[Parameter(Mandatory = $true)][string]$Location,
		[Parameter(Mandatory = $true)][string]$Registry)
	if (-not (Test-Path $FontFile)) 
	{
		throw [System.IO.FileNotFoundException] "$FontFile not found"
	}
	$extension = Get-Item $FontFile | Select-Object -ExpandProperty Extension
	if ($extension -ne '.ttf')
	{
		throw [System.Exception] "$FontFile is not a font file"
	}
	if (-not (Test-Path $Location))
	{
		New-Item -Path $Location -ItemType Directory
	}
	Copy-Item -Path $FontFile -Destination $Location 
	
	$font = Get-Item $FontFile
	$formattedName = Format-Name $font

	if (-not (Test-Path $Registry))
	{
		New-Item -Path $Registry
	}
	New-ItemProperty -Name $formattedName `
		-Path $Registry `
		-PropertyType string `
		-Value $font.Name `
		-Force `
		-ErrorAction SilentlyContinue | Out-Null
}

Export-ModuleMember -Function Add-Font, Get-Font, Install-FontFile