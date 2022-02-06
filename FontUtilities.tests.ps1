BeforeAll { 
    Import-Module .\FontUtilities.psm1
}

Describe "Install-FontFamily" {

    It "Can updated variables" {
        InModuleScope FontUtilities {
            
        }
    }
}

AfterAll {
    Remove-Module FontUtilities
}
