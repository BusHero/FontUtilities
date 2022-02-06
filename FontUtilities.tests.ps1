BeforeAll { 
    Import-Module .\FontUtilities.psm1
    InModuleScope FontUtilities {
        $script:foo = 'bar'
    }
}

Describe "Install-FontFamily" {
    It "Can updated variables" {
        InModuleScope FontUtilities {
            $script:foo | should -be 'bar'
        }
    }
}

AfterAll {
    Remove-Module FontUtilities
}
