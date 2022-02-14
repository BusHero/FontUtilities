$script:fonts = @{}

function Add-FontFamily{
	param([ValidateNotNullOrEmpty()][string]$Family,
		  [ValidateNotNullOrEmpty()][string]$Uri)
	$script:fonts[$Family] = $Uri
}

function Get-FontFamily {
	param([ValidateNotNullOrEmpty()][string]$Family,
		  [switch]$All)
	if ($All) {
		return $script:fonts.Clone()
	}
	return $script:fonts[$Family]
}

function Remove-FontFamily {
	param (
		[ValidateNotNullOrEmpty()][string]$Family,
		[switch]$All
	)
	if ($All) {
		$script:fonts = @{}
	} else {
		$script:fonts.Remove($Family)
	}
}

#region Install-FontFile (Implementation Details)
function Format-Name {
	param (
		[Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$font
	)
	switch ($font.Extension) {
		".ttf" { "$($font.BaseName) (TrueType)" }
		".otf" { "$($font.BaseName) (OpenType)" }
	}
}

function assertFileExists($file) {
	if (-not (Test-Path $file)) 
	{
		throw "$file not found"
	}
}

function assertFileIsFontFile($file){
	if (-not (isFontFile $file))
	{
		throw [System.Exception] "$file is not a font file"
	}
}

function isFontFile($file) {
	switch ([System.IO.Path]::GetExtension($file)) {
		".ttf" { $true }
		default { $false }
	}
}

function copyFontDestination($FontFile, $location) {
	New-Item -Path $Location -ItemType Directory -Force
	Copy-Item -Path $FontFile -Destination $Location 
}

function ensureRegistry($Registry) {
	if (!(Test-Path $Registry))
	{
		New-Item -Path $Registry
	}
}

function addFontToRegistry($FontFile, $Registry) {
	ensureRegistry $Registry

	$font = Get-Item $FontFile 
	New-ItemProperty -Name $(Format-Name $font) `
		-Path $Registry `
		-PropertyType string `
		-Value $font.Name `
		-Force `
		-ErrorAction SilentlyContinue | Out-Null
}

function DownloadFontsArchive {
	param([string]$uri)
	if (-not $uri) {
		return
	}
	New-Item -Path "$PSScriptRoot\.fonts" -ItemType Directory -Force
	$fontDirectoryName = "font_$([guid]::NewGuid())"
	$fontDirectoryPath = "$PSScriptRoot\.fonts\$fontDirectoryName"
	$zipFilePath = "$PSScriptRoot\.fonts\$fontDirectoryName.zip"

	Invoke-WebRequest -Uri $uri -Method Get -ContentType 'application/zip' -OutFile $zipFilePath
	Expand-Archive -Path $zipFilePath -DestinationPath $fontDirectoryPath
	
	$fontDirectoryPath
}

#endregion

function Install-FontFile {
	[CmdletBinding()]
	param(
		[string[]]$Path,
		[string]$url,
		[Parameter(Mandatory = $true)][string]$Destination,
		[Parameter(Mandatory = $true)][string]$Registry)
	try {
		$Path += DownloadFontsArchive $url

		foreach ($file in $Path)
		{
			try {
				assertFileExists $file
				
				$item = Get-Item -Path $file
				$files = switch ($item.PSIsContainer) {
					$true {
						Get-ChildItem $item | 
							Where-Object { isFontFile $_.Name }}
					$false {
						assertFileIsFontFile $item
						@($item)
					}
				} 
				foreach ($file in $files) {
					try {
						copyFontDestination $file.FullName $Destination
						addFontToRegistry $file.FullName $Registry
					} catch {
					}
				}
			} catch { }
		}
	} catch {}
}

Export-ModuleMember -Function Install-FontFile,
							  Add-FontFamily,
							  Get-FontFamily,
							  Remove-FontFamily