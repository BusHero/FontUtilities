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
		[string]$FontFile,
		[string]$Location,
		[string]$Registry)
	if (-not (Test-Path $FontFile)) 
	{
		throw [System.IO.FileNotFoundException] "$FontFile not found"
	}

	if (-not (Test-Path $Location))
	{
		New-Item -Path $Location -ItemType Directory
	}
	Copy-Item -Path $FontFile -Destination $Location 
	
	$font = Get-Item $FontFile
	$formattedName = Format-Name $font
	New-ItemProperty -Name $formattedName `
					 -Path $Registry `
					 -PropertyType string `
					 -Value $font.Name `
					 -Force `
					 -ErrorAction SilentlyContinue | Out-Null
}

Export-ModuleMember -Function Add-Font, Get-Font, Install-FontFile