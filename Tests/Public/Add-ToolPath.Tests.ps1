#requires -Module ChoVersion
Describe Add-ToolPath <# -InModule ChoVersion #> {
    BeforeAll {
        $SavedPath = $Env:Path

        $Command = Get-Command Add-ToolPath
        $PSDefaultParameterValues = @{
            "Mock:ModuleName"              = "ChoVersion"
            "Assert-MockCalled:ModuleName" = "ChoVersion"
        }
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

    Context "Example 1. Add-ToolPath -Path 'C:\Program Files\Git\bin'" {
        BeforeAll {
            $TestPath = $Env:Path
            New-Item "TestDrive:\AFolder" -Force -ItemType Directory
        }
        BeforeEach {
            $Env:Path = $TestPath
        }

        It "Adds the Git bin directory to the front of the PATH environment variable for the current process" {
            & $Command -Path "TestDrive:\AFolder"

            $Env:Path | Should -Match "^TestDrive:\\AFolder;"
        }

        It "When run in a Github Actions environment, will add the Path to the ENV:GITHUB_PATH files" {
            $FILE = $ENV:GITHUB_PATH
            $ENV:GITHUB_PATH = "TestDrive:\AFolder\PATH.txt"
            & $Command -Path "TestDrive:\AFolder"
            $ENV:GITHUB_PATH = $FILE

            Get-Content "TestDrive:\AFolder\PATH.txt" | Should -Be "TestDrive:\AFolder"
        }

        It "When run in an Azure Pipelines environment, will output a `##vso[task.prependpath]` command" {
            $URI = $ENV:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
            $ENV:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI = "https://dev.azure.com/test"
            & $Command -Path "TestDrive:\AFolder" -InformationVariable HostOutput
            $ENV:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI = $URI

            $Env:Path | Should -Match "^TestDrive:\\AFolder;"
            $HostOutput | Should -Be "##vso[task.prependpath]TestDrive:\AFolder"
        }
    }

    Context "The path parameter handles file paths" {
        BeforeAll {
            Mock Test-Path { $Path -notmatch "^ENV:" } -Verifiable # -ParameterFilter { $PathType -eq "Leaf" }
            Mock Split-Path -Verifiable { "TestDrive:\NoSuchFolder" }
        }

        It "Splits off the file when you pass a file path" {
            & $Command -Path "TestDrive:\NoSuchFolder\NoSuchFile"

            Assert-VerifiableMock

            # Because we mocked Test-Path, it will trim the fake file name and add this to path:
            $Env:Path | Should -Match "^TestDrive:\\NoSuchFolder$([IO.Path]::PathSeparator)"
        }
    }

    Context "When SetForUserExperimental is set it permanently updates the USER PATH" {
        BeforeAll {
            New-Item "TestDrive:\AnotherFolder\lib\thing.1.0.0" -Force -ItemType Directory
            New-Item "TestDrive:\AnotherFolder\lib\thing.2.0.0" -Force -ItemType Directory
            $USERPATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $ChocolateyInstall = $Env:ChocolateyInstall
        }
        AfterAll {
            [System.Environment]::SetEnvironmentVariable("PATH", $USERPATH, "User")
            if($ChocolateyInstall) {
                $Env:ChocolateyInstall = $ChocolateyInstall
            }
        }

        It "Generally, prepends the path, but makes no other changes" {
            & $Command -Path "TestDrive:\AnotherFolder" -SetForUserExperimental

            $AFTERPATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $AFTERPATH | Should -Be "TestDrive:\AnotherFolder;$USERPATH"
        }

        It "For versioned chocolatey\lib paths, removes other versions" {
            $Env:ChocolateyInstall = "TestDrive:\AnotherFolder"

            & $Command -Path "TestDrive:\AnotherFolder\lib\thing.2.0.0" -SetForUserExperimental
            $AFTERPATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $AFTERPATH | Should -Be "TestDrive:\AnotherFolder\lib\thing.2.0.0;TestDrive:\AnotherFolder;$USERPATH"

            & $Command -Path "TestDrive:\AnotherFolder\lib\thing.1.0.0" -SetForUserExperimental
            $AFTERPATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $AFTERPATH | Should -Be "TestDrive:\AnotherFolder\lib\thing.1.0.0;TestDrive:\AnotherFolder;$USERPATH"
        }
    }
}