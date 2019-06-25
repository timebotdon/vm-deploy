
function elevateUAC {
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
		Write-Host "This script requires administrator rights. Auto elevating in 5 seconds.."
		Start-Sleep 5
		Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
		exit
	}
}

## Package Management
Function checkChoco {
	Write-Host "Checking if chocolatey is installed."
	choco --version
	if ($lastexitcode -eq "0") {
		write-host "Chocolatey is installed!"
	} 
	else {
		Write-Host "Chocolatey is NOT installed. Running choco install script."
		$chocInstall = Read-host -Prompt "Chocolatey is required for the rest of this proocedure. Do you want to install Chocolatey now? (y/n)"
		if ($chocInstall -eq "y") {
			Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		}
		else {
			Write-Host "Chcolatey is required to install packages! Returning to menu."
			menu
		}
	}
}

Function installSoftware {
	checkChoco
	Write-Host "Found the following software lists."
	Write-host
	gci .\Profiles\*.lst -Name
	Write-host
	$softwareList = read-host -Prompt "Install with which list?"
	Write-host "Software names are referenced from the Chocolatey repo."
	Write-host "=== List Start ==="
	foreach ($item in gc ".\Profiles\$softwareList") {
		Write-Output "$item"
	}
	Write-host "=== List End ==="
	Write-host
	Write-Output "Is the list provided correct? Proceed to install?"
	$chocConfirm = read-host -Prompt "(y/n)"
	if ($chocConfirm -eq "y") {
		Write-Output "Commencing software install.."
		foreach ($toInstall in gc ".\Profiles\$softwareList") {
			Write-Output "Installing $toInstall."
			choco install -y $toInstall
		}
		Write-Host "Installation complete."
		Write-Host "Initiating reboot."
		Start-Sleep 2
		Restart-Computer
	}
	else {
		Write-host "Return to menu."
		menu
	}
}


function menu {
	Write-host 
	Write-host "Script for quick deployment of new virtual machines. Installs software using Chocolatey package manager."
	Write-host "1. Install software"
	Write-host "0. Exit"
	Write-host
	$menuCh = read-host -Prompt "Choose an option."
	

	if ($menuCh -eq "1") {
		installSoftware
	}
	if ($menuCh -eq "0") {
		exit
	}	
}


function init {
	elevateUAC
	menu
}

init