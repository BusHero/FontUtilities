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

Describe "Install Font" {
    BeforeAll {
        $FontFileName = 'font.ttf'
        $FontFile = "TestDrive:\$FontFileName"
        $Location = 'TestDrive:\fonts'
        
        $RegistryEntry = 'font (TrueType)'
        $RegistryName = 'Fonts'
        $Registry = "TestRegistry:\$RegistryName"
        
        New-Item -Path $FontFile -ItemType File
        New-Item -Path $Location -ItemType Directory
        New-Item -Path 'TestRegistry:\' -Name $RegistryName
    }
    Context "Font is installed" {
        BeforeAll {
            Install-FontFile -FontFile $FontFile -Location $Location -Registry $Registry
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
    AfterAll {
        Remove-Item -Path $FontFile -Recurse -Force
        Remove-Item -Path $Location -Recurse -Force
        Remove-Item -Path $Registry -Recurse -Force
    }
}

AfterAll {
    Remove-Module FontUtilities
}
