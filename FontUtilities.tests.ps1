# 1. User can register fonts(Font family + url)
# 2. User can get font's url

BeforeAll { 
    Import-Module .\FontUtilities.psm1

    function Select-Zip {
        [CmdletBinding()]
        Param(
            $First,
            $Second,
            $ResultSelector = { ,$args }
        )
    
        [System.Linq.Enumerable]::Zip($First, $Second, [Func[Object, Object, Object[]]]$ResultSelector)
    }
}

Describe "Install font file" {
    BeforeAll {
        $FontFileName = 'font.ttf'
        $FontFile = "TestDrive:\$FontFileName"
        $Location = 'TestDrive:\fonts'
        $url = 'https://raw.githubusercontent.com/BusHero/test-repo/main/TestFont.zip'

        $RegistryEntry = 'font (TrueType)'
        $RegistryName = 'Fonts'
        $Registry = "TestRegistry:\$RegistryName"
        New-Item -Path $FontFile -ItemType File
        New-Item -Path $Location -ItemType Directory
        New-Item -Path $Registry
    }
    Context "Font is installed" {
        BeforeAll {
            Install-FontFile -FontFile $FontFile `
                             -Location $Location `
                             -Registry $Registry
        }
        It "<FontFileName> is copied to the <location>" {
            Test-Path "$Location\$FontFileName" | 
                should -BeTrue -because "$FontFileName should be copied"
        }
        It "<FontFileName> is added to the <Registry>" {
            Get-ItemProperty -path $Registry |
                Select-object -ExpandProperty $RegistryEntry |
                should -be $FontFileName -because 'Registry entry should be created'
        }
    }

    It "Throw if font file does not exist" {
        Install-FontFile -FontFile 'NonExistingFile' `
                            -Location $Location `
                            -Registry $Registry `
                            -ErrorVariable err
        $err.Count | should -BeGreaterThan 0
    }
    
    Context "Throws if file is not a font file" -Foreach @(
        @{File="TestDrive:\file.json"; ItemType='File'}
        @{File="TestDrive:\file.txt"; ItemType='File'}
        @{File="TestDrive:\file.xml"; ItemType='File'}
        @{File="TestDrive:\directory"; ItemType='Directory'}
    ) {
        BeforeAll{
            $NewRegistry = "TestRegistry:\NewRegistry"
            New-Item -Path $NewRegistry
            New-Item -Path $File -ItemType $ItemType
            Install-FontFile -FontFile $File `
                             -Location $Location `
                             -Registry $Registry `
                             -ErrorVariable err
        }
        It "There should be errors" {
            $err.Count | should -BeGreaterThan 0
        }
        It "'<file>' was not copied to <Location>" {
            Get-ChildItem -Path $Location | should -HaveCount 0
        }
        It "'<file>' was not added to the <Register>" {
            Get-Item -path $NewRegistry |
                Select-Object -ExpandProperty Property |
                should -HaveCount 0
        }

        AfterAll {
            Remove-Item -Path $File -Recurse -Force
            Remove-Item -Path $NewRegistry -Recurse -Force
        }
    }

    Context "Creates location if it doesn't exist" {
        BeforeAll {
            $NonExistentLocation = 'TestDrive:\.fonts'
        }
        It "<NonExistentLocation> is created automatically" {
            Install-FontFile -FontFile $FontFile `
                             -Location $NonExistentLocation `
                             -Registry $Registry
            Test-Path -Path $NonExistentLocation | should -be $true
            Test-Path -Path $NonExistentLocation\$FontFileName | should -be $true
        }
        AfterAll {
            if (Test-Path -Path $NonExistentLocation) {
                Remove-Item -Path $NonExistentLocation -Recurse -Force
            }
        }
    }

    Context "Creates Registry key if it doesn't exist" {
        BeforeAll {
            $NonExistingRegistryName = 'Fonts New'
            $NonExistingRegistry = "TestRegistry:\$NonExistingRegistryName"
        }
        It "<NonExistingRegistry> is created automatically" {
            Install-FontFile -FontFile $FontFile `
                             -Location $Location `
                             -Registry $NonExistingRegistry
            
            Test-Path $NonExistingRegistry | should -beTrue -because 'Install-FontFamily should create non existing register key'
            Get-ItemProperty -path $NonExistingRegistry |
                Select-object -ExpandProperty $RegistryEntry |
                should -be $FontFileName -because 'Registry entry should be created if missing'
        }
        AfterAll {
            If (Test-Path $NonExistingRegistry) {
                Remove-Item -path $NonExistingRegistry -Recurse
            }
        }
    }

    Context "Installs several fonts at once" {
        BeforeAll {
            #region Garbage
            
            $FontNames = 'font1', 'font2'
            $FontFileNames = foreach ($font in $FontNames) { "$font.ttf" }
            $FontPaths = foreach ($fontFileName in $FontFileNames) { "TestDrive:\$fontFileName" }
            $FontRegistryProperties = foreach ($fontName in $FontNames) { "$fontName (TrueType)" }
            $FontsInstallationDirectory = 'TestDrive:\foobar'
            $FontsInstallationRegistry = "TestRegistry:\foobar"

            foreach ($fontPath in $FontPaths) { New-Item -Path $fontPath -ItemType File }
            New-Item -Path $FontsInstallationDirectory -ItemType Directory
            New-Item -Path $FontsInstallationRegistry
            
            #endregion Garbage

            Install-FontFile -FontFile $FontPaths `
                             -Location $FontsInstallationDirectory `
                             -Registry $FontsInstallationRegistry
        }

        It "'<FontPaths>' were installed" {
            foreach ($font in $fonts) {
                Test-Path -Path $Location\$font | should -beTrue -because "$font should be installed in the $location"
            }
        }

        It "'<FontPaths> were added to registry" {
            $RegistryItem = Get-ItemProperty $FontsInstallationRegistry
            foreach ($counter in 0..($FontRegistryProperties.Length - 1)) { 
                $RegistryItem |
                    Select-Object -ExpandProperty $FontRegistryProperties[$counter] |
                    should -be $FontFileNames[$counter] -because 'Registry entry should be created'
            }
        }

        AfterAll {
            $fonts | Remove-Item -Force -ErrorAction Ignore
            $font | Remove-Item -Force -ErrorAction Ignore
            Remove-Item -Path $FontsInstallationDirectory -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsInstallationRegistry -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Install several fonts at once. One file is a txt file" {
        BeforeAll {
            #region Garbage
            $fontName = 'foo'
            $fontFileName = "$fontName.ttf"
            $fontFilePath = "TestDrive:\$fontFileName"
            $registryEntry = "$fontName (TrueType)"
            $nonFileName = 'bar.txt'
            $nonFilePath = "TestDrive:\$nonFileName"

            $FontsInstallationDirectory = 'TestDrive:\foobar'
            $FontsInstallationRegistry = "TestRegistry:\foobar"

            New-Item -Path $fontFilePath -ItemType File
            New-Item -Path $nonFileName -ItemType File
            New-Item -Path $FontsInstallationDirectory -ItemType Directory
            New-Item -Path $FontsInstallationRegistry
            #endregion Garbage

            Install-FontFile -FontFile $fontFilePath, $nonFilePath `
                             -Location $FontsInstallationDirectory `
                             -Registry $FontsInstallationRegistry
        }
        It "<fontName> was installed" {
            Test-Path $FontsInstallationDirectory\$fontFileName | should -beTrue
        }
        It "<registryEntry> was added to registry" {
            Get-ItemProperty $FontsInstallationRegistry |
                Select-Object -ExpandProperty $registryEntry |
                should -be $fontFileName -because 'Registry entry should be created'
        }
        It "<registry> does not contain any other stuff" {
            Get-ItemProperty $FontsInstallationRegistry | should -HaveCount 1
        }
        It "<nonFileName> was not installed" {
            Test-Path $FontsInstallationDirectory\$nonFileName |
                should -beFalse -because "Application doesn't install non font files"
        }
        AfterAll {
            Remove-Item -Path $FontsInstallationDirectory -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $FontsInstallationRegistry -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $fontFilePath -Recurse -Force -ErrorAction Ignore
            Remove-Item -Path $nonFileName -Recurse -Force -ErrorAction Ignore
        }
    }
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
