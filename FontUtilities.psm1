$script:fonts = @{}

function Format-Name {
	param (
		[Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$font
	)
	switch ($font.Extension) {
		".ttf" { "$($font.BaseName) (TrueType)" }
		".otf" { "$($font.BaseName) (OpenType)" }
	}
}


#region Install-FontFile (Implementation Details)

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

function isFontFile {
	param (
		[string]$file
	)
	switch ([System.IO.Path]::GetExtension($file)) {
		".ttf" { $true }
		default { $false }
	}
}

function copyFontDestination($FontFile, $location) {
	if (-not (Test-Path $Location))
	{
		New-Item -Path $Location -ItemType Directory
	}
	Copy-Item -Path $FontFile -Destination $Location 
}

function ensureRegistry($Registry) {
	if (-not (Test-Path $Registry))
	{
		New-Item -Path $Registry
	}
}

function addFontToRegistry($FontFile, $Registry) {
	ensureRegistry $Registry

	$font = Get-Item $FontFile 
	$formattedName = Format-Name $font
	New-ItemProperty -Name $formattedName `
		-Path $Registry `
		-PropertyType string `
		-Value $font.Name `
		-Force `
		-ErrorAction SilentlyContinue | Out-Null
}

#endregion

function Install-FontFile {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)][string[]]$Path,
		[Parameter(Mandatory = $true)][string]$Destination,
		[Parameter(Mandatory = $true)][string]$Registry)
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
					copyFontDestination $file $Destination
					addFontToRegistry $file $Registry
				} catch {
				}
			}
		} catch {
		}
	}
}

Export-ModuleMember -Function Install-FontFile