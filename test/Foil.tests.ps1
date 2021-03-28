﻿Import-Module Foil

Describe "basic package search operations" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'gets a list of latest installed packages' {
			Get-ChocoPackage | Where-Object {$_.Name -contains 'chocolatey'} | Should -Not -BeNullOrEmpty
		}
		It 'searches for the latest version of a package' {
			Get-ChocoPackage -Name $package | Where-Object {$_.Name -contains $package}  | Should -Not -BeNullOrEmpty
		}
		It 'searches for all versions of a package' {
			Get-ChocoPackage -Name $package -AllVersions | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'searches for the latest version of a package with a wildcard pattern' {
			Get-ChocoPackage -Name "$package*" | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "DSC-compliant package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for the latest version of a package' {
			Get-ChocoPackage -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-ChocoPackage -Name $package -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-ChocoPackage -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-ChocoPackage -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with additional parameters' {
		$package = 'sysinternals'

		It 'searches for the latest version of a package' {
			Get-ChocoPackage -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-ChocoPackage -Name $package -Force -ParamsGlobal -Parameters "/InstallDir:$env:ProgramFiles\sysinternals /QuickLaunchShortcut:false" | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed parameters to the package' {
			Get-ChildItem -Path (Join-Path -Path $env:ProgramFiles -ChildPath 'sysinternals') -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-ChocoPackage -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-ChocoPackage -Name $package | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "pipline-based package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for and silently installs the latest version of a package' {
			Get-ChocoPackage -Name $package | Install-ChocoPackage -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-ChocoPackage -Name $package | Uninstall-ChocoPackage | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with additional parameters' {
		$package = 'sysinternals'

		It 'searches for and silently installs the latest version of a package' {
			Get-ChocoPackage -Name $package | Install-ChocoPackage -Force -ParamsGlobal -Parameters "/InstallDir:$env:ProgramFiles\sysinternals /QuickLaunchShortcut:false" | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
		It 'correctly passed parameters to the package' {
			Get-ChildItem -Path (Join-Path -Path $env:ProgramFiles -ChildPath 'sysinternals') -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-ChocoPackage -Name $package | Uninstall-ChocoPackage | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "multi-source support" {
	BeforeAll {
		$altSource = 'LocalChocoSource'
		$altLocation = $PSScriptRoot
		$package = 'cpu-z'

		Save-Package $package -Source 'http://chocolatey.org/api/v2' -Path $altLocation
		Unregister-ChocoSource -Name $altSource -ErrorAction SilentlyContinue
	}
	AfterAll {
		Remove-Item "$altLocation\*.nupkg" -Force -ErrorAction SilentlyContinue
		Unregister-ChocoSource -Name $altSource -ErrorAction SilentlyContinue
	}

	It 'refuses to register a source with no location' {
		Register-ChocoSource -Name $altSource -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $altSource} | Should -BeNullOrEmpty
	}
	It 'registers an alternative package source' {
		Register-ChocoSource -Name $altSource -Location $altLocation | Where-Object {$_.Name -eq $altSource} | Should -Not -BeNullOrEmpty
	}
	It 'searches for and installs the latest version of a package from an alternate source' {
		Get-ChocoPackage -Name $package -source $altSource | Install-ChocoPackage -Force | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
	}
	It 'finds and uninstalls a package installed from an alternate source' {
		Get-ChocoPackage -Name $package | Uninstall-ChocoPackage | Where-Object {$_.Name -contains $package} | Should -Not -BeNullOrEmpty
	}
	It 'unregisters an alternative package source' {
		Unregister-ChocoSource -Name $altSource
		Get-ChocoSource | Where-Object {$_.Name -eq $altSource} | Should -BeNullOrEmpty
	}
}

Describe "version filters" {
	$package = 'ninja'
	# Keep at least one version back, to test the 'latest' feature
	$version = '1.10.1'

	AfterAll {
		Uninstall-ChocoPackage -Name $package -ErrorAction SilentlyContinue
	}

	Context 'required version' {
		It 'searches for and silently installs a specific package version' {
			Get-ChocoPackage -Name $package -Version $version | Install-ChocoPackage -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-ChocoPackage -Name $package -Version $version | UnInstall-ChocoPackage -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
	}
}