Describe Add-ToolPath -InModule ChoVersion {
    BeforeAll {
        $SavedPath = $Env:Path
    }

    AfterAll {
        $Env:Path = $SavedPath
    }

    Context "Parameter Validation" {
        It "Should have a mandatory Path parameter" {
            $Command | Should -HaveParameter Path -Mandatory
        }
        It "Should have a SetForUserExperimental parameter" {
            $Command | Should -HaveParameter SetForUserExperimental
        }
    }

    Context "The path parameter handles files or folders" {
        BeforeAll {
            Mock Test-Path { $Path -notmatch "^ENV:" } -Verifiable
            Mock Split-Path -Verifiable { "TestPath:\NoSuchFolder" }
        }

        It "Splits off the file when you pass a file path" {
            & $Command -Path "TestPath:\NoSuchFolder\NoSuchFile"

            Assert-VerifiableMock

            # Because we mocked Test-Path, it will trim the fake file name and add this to path:
            $Env:Path | Should -Match "^TestPath:\\NoSuchFolder$([IO.Path]::PathSeparator)"
        }
    }


}