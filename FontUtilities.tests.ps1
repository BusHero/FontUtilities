# 1. User can register fonts(Font family + url)
# 2. User can get font's url

BeforeAll { 
    Import-Module .\FontUtilities.psm1
}

# Describe "Add-Font" {
#     Context "Get font that was added" {
#         It "Files are copied" {
#             $expectedUrl = "https://raw.githubusercontent.com/BusHero/test-repo/main/TestFont.zip"
#             Add-Font -Family "TestFont" -url $expectedUrl
#             Get-Font -Family "TestFont" | should -be $expectedUrl 
#         }
#     }
#     Context "Get font that wasn't added" {
#         It '$null is getted when no font is added' {
#             Get-Font -Family "ThisFontDoesNotExist" | should -be $null 
#         }
#     }
# }

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
        { Install-FontFile -FontFile 'NonExistingFile' `
                            -Location $Location `
                            -Registry $Registry } | should -throw
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
            { Install-FontFile -FontFile $File `
                               -Location $Location `
                               -Registry $Registry } | should -throw "$File is not a font file"
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
}

AfterAll {
    Remove-Module FontUtilities
}
