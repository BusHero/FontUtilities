$script:FontsConfig = "$PSScriptRoot\fonts.json"

function getFontsHashtable {
	switch (Test-Path -Path $script:FontsConfig) {
		$true {
			Get-Content -Path $script:FontsConfig | ConvertFrom-Json -AsHashtable
		}
		Default { @{} }
	}
}

function saveFontsHashtable($fonts) {
	$fonts | ConvertTo-Json | Out-File -FilePath $script:FontsConfig
}

function Add-FontFamily{
	param([ValidateNotNullOrEmpty()][string]$Family,
		  [Alias('Url')][ValidateNotNullOrEmpty()][string]$Uri,
		  [ValidateNotNullOrEmpty()][string]$Path,
		  [ValidateNotNullOrEmpty()][string]$Online)
	if ($Path) {
		Copy-Item -Path $Path -Destination $script:FontsConfig -Force
	}
	elseif ($Online) {
		Invoke-WebRequest -Uri $Online `
						  -Method Get `
						  -ContentType 'application/json' `
						  -OutFile $script:FontsConfig
	}
	else {
		$fonts = getFontsHashtable
		$fonts[$Family] = $Uri
		saveFontsHashtable $fonts
	}
}

function Get-FontFamily {
	param([ValidateNotNullOrEmpty()][string]$Family,
		  [switch]$All)
	$fonts = getFontsHashtable
	
	if ($All) {
		return $fonts.Clone()
	}

	return $fonts[$Family]
}

function Remove-FontFamily {
	param (
		[ValidateNotNullOrEmpty()][string]$Family,
		[switch]$All
	)
	$fonts = getFontsHashtable

	if ($All) {
		$fonts = @{}
	} else {
		$fonts.Remove($Family)
	}
	saveFontsHashtable $fonts
}

#region Install-Font (Implementation Details)
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

function DownloadFontsArchive([Parameter(ValueFromPipeline)][string]$uri) {
	if (-not $uri) {
		return
	}
	$fontDirectoryName = "font_$([guid]::NewGuid())"
	$fontDirectoryPath = "$PSScriptRoot\.fonts\$fontDirectoryName"
	$zipFilePath = "$PSScriptRoot\.fonts\$fontDirectoryName.zip"
	
	New-Item -Path "$PSScriptRoot\.fonts" -ItemType Directory -Force
	Invoke-WebRequest -Uri $uri -Method Get -ContentType 'application/zip' -OutFile $zipFilePath
	Expand-Archive -Path $zipFilePath -DestinationPath $fontDirectoryPath
	
	$fontDirectoryPath
}

#endregion

function Install-Font {
	[CmdletBinding()]
	param(
		[ValidateNotNullOrEmpty()][string[]]$Path,
		[ValidateNotNullOrEmpty()][string]$url,
		[ValidateNotNullOrEmpty()][string]$Family,
		[Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Destination = "C:\Windows\fonts",
		[Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Registry = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts")
	try {
		if ($url)
		{
			$Path += DownloadFontsArchive $url
		}
		if ($Family)
		{
			$Path += Get-FontFamily -Family $Family | DownloadFontsArchive
		}

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

Export-ModuleMember -Function Install-Font,
							  Add-FontFamily,
							  Get-FontFamily,
							  Remove-FontFamily `
					-Variable FontsConfig
