# 1. User can register fonts(Font family + url)
# 2. User can get font's url

BeforeAll { 
    Import-Module .\FontUtilities.psm1
}

Describe "Install font file" {
    BeforeAll {
        $FontFileName = 'font.ttf'
        $FontFilePath = "TestDrive:\$FontFileName"
        $FontRegistryEntry = 'font (TrueType)'
        $FontsDestinationDirectory = 'TestDrive:\fonts'
        $FontsDestinationRegistry = 'TestRegistry:\fonts'
    }
    Context "Font is installed" {
        BeforeAll {
            New-Item -Path $FontsDestinationDirectory -ItemType Directory
            New-Item -Path $FontsDestinationRegistry
            New-Item -Path $FontFilePath -ItemType File

            Install-FontFile -Path $FontFilePath `
                             -Location $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<FontFileName> is copied to the <FontsDestinationDirectory>" {
            Test-Path "$FontsDestinationDirectory\$FontFileName" | 
                should -BeTrue -because "$FontFileName should be copied"
        }
        It "<FontFileName> is added to the <FontsDestinationRegistry>" {
            Get-ItemProperty -path $FontsDestinationRegistry |
                Select-object -ExpandProperty $FontRegistryEntry |
                should -be $FontFileName -because 'Registry entry should be created'
        }
        AfterAll {
            Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontFilePath -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Throw if font file does not exist" {
        BeforeAll {
            New-Item -Path $FontsDestinationDirectory -ItemType Directory
            New-Item -Path $FontsDestinationRegistry
            Install-FontFile -Path $FontFilePath `
                            -Location $FontsDestinationDirectory `
                            -Registry $FontsDestinationRegistry `
                            -ErrorVariable err
        }
        It "There are errors" {
            $err.Count | should -BeGreaterThan 0
        }
        AfterAll {
            Remove-Item -Path $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
        }
    }
    
    Context "Throws if file is not a font file" -Foreach @(
        @{File="TestDrive:\file.json"; ItemType='File'}
        @{File="TestDrive:\file.txt"; ItemType='File'}
        @{File="TestDrive:\file.xml"; ItemType='File'}
        @{File="TestDrive:\directory"; ItemType='Directory'}
    ) {
        BeforeAll{
            New-Item -Path $FontsDestinationDirectory -ItemType Directory
            New-Item -Path $FontsDestinationRegistry
            New-Item -Path $File -ItemType $ItemType
            Install-FontFile -Path $File `
                             -Location $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry `
                             -ErrorVariable err
        }
        It "There should be errors" {
            $err.Count | should -BeGreaterThan 0
        }
        It "'<file>' was not copied to <FontsDestinationDirectory>" {
            Get-ChildItem -Path $FontsDestinationDirectory | should -HaveCount 0
        }
        It "'<file>' was not added to the <FontsDestinationRegistry>" {
            Get-Item -path $FontsDestinationRegistry |
                Select-Object -ExpandProperty Property |
                should -HaveCount 0
        }
        AfterAll {
            Remove-Item -Path $File -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Creates location if it doesn't exist" {
        BeforeAll {
            New-Item -Path $FontFilePath -ItemType File
            New-Item -Path $FontsDestinationRegistry

            Install-FontFile -Path $FontFilePath `
                             -Location $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<FontsDestinationDirectory> is created automatically" {
            Test-Path -Path $FontsDestinationDirectory | should -beTrue
        }
        It "<FontsDestinationDirectory>\<FontFileName> exists" {
            Test-Path -Path $FontsDestinationDirectory\$FontFileName | should -beTrue
        }
        AfterAll {
            Remove-Item -Path $FontFilePath -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Creates Registry key if it doesn't exist" {
        BeforeAll {
            New-Item -Path $FontFilePath -ItemType File
            New-Item -Path $FontsDestinationDirectory -ItemType Directory
            
            Install-FontFile -Path $FontFilePath `
                             -Location $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<FontsDestinationRegistry> is created automatically" {
            Test-Path $FontsDestinationRegistry | should -beTrue -because 'Install-FontFamily should create non existing register key'
        }
        It "<FontRegistryEntry> should be created" {
            Get-ItemProperty -path $FontsDestinationRegistry |
                Select-object -ExpandProperty $FontRegistryEntry |
                should -be $FontFileName -because 'Registry entry should be created if missing'
        }
        AfterAll {
            Remove-Item -Path $FontFilePath -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Installs several fonts at once" {
        BeforeAll {
            #region Garbage
            $FontNames = 'font1', 'font2'
            $FontFileNames = foreach ($font in $FontNames) { "$font.ttf" }
            $FontPaths = foreach ($fontFileName in $FontFileNames) { "TestDrive:\$fontFileName" }
            $FontRegistryProperties = foreach ($fontName in $FontNames) { "$fontName (TrueType)" }
            foreach ($fontPath in $FontPaths) { New-Item -Path $fontPath -ItemType File }
            New-Item -Path $FontsDestinationDirectory -ItemType Directory
            New-Item -Path $FontsDestinationRegistry
            
            #endregion Garbage

            Install-FontFile -Path $FontPaths `
                             -Location $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }

        It "'<FontPaths>' were installed" {
            foreach ($font in $fonts) {
                Test-Path -Path $Location\$font | should -beTrue -because "$font should be installed in the $location"
            }
        }

        It "'<FontPaths> were added to registry" {
            $RegistryItem = Get-ItemProperty $FontsDestinationRegistry
            foreach ($counter in 0..($FontRegistryProperties.Length - 1)) { 
                $RegistryItem |
                    Select-Object -ExpandProperty $FontRegistryProperties[$counter] |
                    should -be $FontFileNames[$counter] -because 'Registry entry should be created'
            }
        }

        AfterAll {
            $fonts | Remove-Item -Force -ErrorAction Ignore
            $font | Remove-Item -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Install several fonts at once. One file is a txt file" {
        BeforeAll {
            #region Garbage
            $nonFileName = 'bar.txt'
            $nonFilePath = "TestDrive:\$nonFileName"

            New-Item -Path $fontFilePath -ItemType File
            New-Item -Path $nonFilePath -ItemType File
            New-Item -Path $FontsDestinationDirectory -ItemType Directory
            New-Item -Path $FontsDestinationRegistry
            #endregion Garbage

            Install-FontFile -Path $fontFilePath, $nonFilePath `
                             -Location $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<fontName> was installed" {
            Test-Path $FontsDestinationDirectory\$fontFileName | should -beTrue
        }
        It "<FontRegistryEntry> was added to registry" {
            Get-ItemProperty $FontsDestinationRegistry |
                Select-Object -ExpandProperty $FontRegistryEntry |
                should -be $fontFileName -because 'Registry entry should be created'
        }
        It "<registry> does not contain any other stuff" {
            Get-ItemProperty $FontsDestinationRegistry | should -HaveCount 1
        }
        It "<nonFileName> was not installed" {
            Test-Path $FontsDestinationDirectory\$nonFileName |
                should -beFalse -because "Application doesn't install non font files"
        }
        AfterAll {
            Remove-Item -Path $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $fontFilePath -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $nonFilePath -Recurse -Force -ErrorAction Ignore
        }
    }

    # Context "Install fonts from directory" {
    #     BeforeAll {
    #         $fontName = 'foo'
    #         $fontFileName = "$fontName.ttf"
    #         $registryEntry = "$fontName (TrueType)"
    #         $FontsSourceDirectory = "TestDrive:\directory"
    #         $FontsDestinationDirectory = 'TestDrive:\foobar'
    #         $FontsDestinationRegistry = "TestRegistry:\foobar"

    #         New-Item -Path $FontsSourceDirectory -ItemType Directory
    #         New-Item -Name $fontFileName -Path $FontsSourceDirectory -ItemType File
    #         New-Item -Path $FontsDestinationDirectory -ItemType Directory
    #         New-Item -Path $FontsDestinationRegistry
    #     }
    #     RemoveAll {
    #         Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
    #         Remove-Item -Path $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
    #         Remove-Item -Path $FontsSourceDirectory -Recurse -Force -ErrorAction Ignore
    #     }
    # }

    # Context "Downloads font from the provided url" {
    #     BeforeAll {
    #         $FontFileName = 'TestFont.ttf'
    #         $Location = 'TestDrive:\fonts'
    
    #         $RegistryEntry = 'TestFont (TrueType)'
    #         Donwload-FontFamily -URL 'https://raw.githubusercontent.com/BusHero/test-repo/main/TestFont.zip' `
    #                             -Location $Location `
    #                             -Registry $Registry
    #     }
    #     It "TestFont was copied" {
    #         Test-Path -Path $Location\$FontFileName |
    #             should -BeTrue -Because "Font should be installed"
    #     }
    #     It "TestFont was added to Registry key" {
    #         Get-ItemProperty -path $Registry |
    #             Select-object -ExpandProperty $RegistryEntry |
    #             should -be $FontFileName -because 'Registry entry should be created'
    #     }
    #     AfterAll {
    #         Remove-Item -Name $FontFileName -Path $Location -Force -ErrorAction Ignore
    #         Remove-ItemProperty -Path $Registry -Name $RegistryEntry -Force -ErrorAction Ignore
    #     }
    # }
}

AfterAll {
    Remove-Module FontUtilities -ErrorAction Ignore
}
