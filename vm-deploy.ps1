
Function elevateUAC {
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
		Write-Host "This script requires administrator rights. Auto elevating in 5 seconds.."
		Start-Sleep 5
		Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
		exit
	}
}


## Network Config

Function setNetworking {
	$networkCh = Read-Host -Prompt "Use Static/DHCP? (s/d)"
	if ($networkCh -eq "s") {
		Get-WmiObject win32_networkadapter -filter "netconnectionstatus = 2" | select Name
		$interface = Read-Host -Prompt "Interface Name"
		$ip = Read-Host -Prompt "IP Address"
		$netmask = Read-Host -Prompt "Netmask"
		$gateway = Read-Host -Prompt "Gateway Address"
		$netConfirmS = Read-Host -Prompt "Confirm? (y/n)"
		if ($netConfirmS -eq "y") {
			netsh interface ip set address name="$interface" static $ip $netmask $gateway
			Write-Host "Testing network connection.."
			ping $gateway
			if ($lastexitcode -eq "0") {
				Write-Host "Ping test successful. Returning to menu."
				menu
			}
			else {
				Write-Host "Connection Error - Please check network settings / firewall rules! Returning to menu."
				menu
			}
		}
	}
	if ($networkCh -eq "d") {
		Get-WmiObject win32_networkadapter -filter "netconnectionstatus = 2" | select Name
		$interface = Read-Host -Prompt "Interface Name"
		$netConfirmD = Read-Host -Prompt "Confirm? (y/n)"
		if ($netConfirmD -eq "y") {
			netsh interface ip set address "$interface" dhcp
			Write-Host "Testing network connection.."
			ping $gateway
			if ($lastexitcode -eq "0") {
				Write-Host "Ping test successful. Returning to menu."
				menu
			}
			else {
				Write-Host "Connection Error - Please check network settings / firewall rules! Returning to menu."
				menu
			}
		}
	}
}

## Domain

Function joinDomain {
	$domainName = Read-Host -Prompt "Domain Name?"
	Add-Computer –DomainName $domainName –Credential (Get-Credential)
	menu
}

## Package Management
Function checkChoco {
	Write-Host "Checking if chocolatey is installed."
	choco --version
	if ($lastexitcode -eq "0") {
		Write-Host "Chocolatey is installed!"
	} 
	else {
		Write-Host "Chocolatey is NOT installed. Running choco install script."
		$chocInstall = Read-Host -Prompt "Chocolatey is required for the rest of this proocedure. Do you want to install Chocolatey now? (y/n)"
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
	Write-Host
	gci .\Profiles\*.lst -Name
	Write-Host
	$softwareList = Read-Host -Prompt "Install with which list?"
	Write-Host "Software names are referenced from the Chocolatey repo."
	Write-Host "=== List Start ==="
	foreach ($item in gc ".\Profiles\$softwareList") {
		Write-Output "$item"
	}
	Write-Host "=== List End ==="
	Write-Host
	Write-Output "Is the list provided correct? Proceed to install?"
	$chocConfirm = Read-Host -Prompt "(y/n)"
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
		Write-Host "Returning to menu."
		menu
	}
}


Function installAD {
	## https://medium.com/@eeubanks/install-ad-ds-dns-and-dhcp-using-powershell-on-windows-server-2016-ac331e5988a7
	if (((Get-WindowsFeature -Name AD-Domain-Services).InstallState) -eq "Available") -and (((Get-WindowsFeature -Name DNS).InstallState) -eq "Available") {
		$domainName = Read-Host -Prompt "Provide a Domain Name for root forest."
		if (!$domainName) {
			Write-Output "Installing Active Directory / DNS roles.."
			Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
			Install-ADDSForest -DomainName "$domainName"
			Write-Output "Installation complete. Please configure settings from the Server Manager!"
			menu
		}
		else {
			Write-Host "Domain Name CANNOT be empty! Returning to menu."
			menu
		}
	}
	else {
		Write-Host "AD / DNS role is already installed! Returning to menu."
		menu
	}
}


Function installDHCP {
	## https://medium.com/@eeubanks/install-ad-ds-dns-and-dhcp-using-powershell-on-windows-server-2016-ac331e5988a7
	if (((Get-WindowsFeature -Name DHCP).InstallState) -eq "Available") {
		Install-WindowsFeature -Name DHCP -IncludeManagementTools
		Write-Output "Installation complete. Please configure settings from the Server Manager!"
		menu
	}
	else {
		Write-Host "DHCP role is already installed! Returning to menu."
		menu
	}	
}


Function installWeb {
	## https://docs.microsoft.com/en-us/powershell/module/servermanager/install-windowsfeature?view=winserver2012r2-ps
	if (((Get-WindowsFeature -Name Web-Server).InstallState) -eq "Available") {
		Install-WindowsFeature -Name Web-Server -IncludeManagementTools
		Write-Output "Installation complete. Please configure settings from the Server Manager!"
		menu
	}
	else {
		Write-Host "Web-Server role is already installed! Returning to menu."
		menu
	}	
}


# Server roles Menu
Function serverMenu {
	if (((Get-WmiObject win32_operatingsystem).name).contains("Server") -eq "True") {
		Write-Host
		Write-Host "1. Acive Directory / DNS"
		Write-Host "2. DHCP"
		Write-Host "3. IIS Web Server"
		Write-Host "0. Back to menu"
		Write-Host
		$serverCh = Read-Host -Prompt "Choose a server role."
		
		if ($serverCh -eq "1") {
			installAD
		}
		if ($serverCh -eq "2") {
			installDHCP
		}
		if ($serverCh -eq "3") {
			installWeb
		}	
		if ($serverCh -eq "0") {
			menu
		}
	}
	else {
		Write-Output "This isn't a Windows Server. Returning to menu."
		menu
	}
}

#Menu
Function menu {
	Write-Host 
	Write-Host "Script for quick deployment of new virtual machines. Installs software using Chocolatey package manager."
	Write-Host "1. Configure networking"
	Write-Host "2. Install software"
	Write-Host "3. Server Only - Configure Server Roles"
	Write-Host "4. Join Domain"
	Write-Host "0. Exit"
	Write-Host
	$menuCh = Read-Host -Prompt "Choose an option."
	
	if ($menuCh -eq "1") {
		setNetworking
	}
	if ($menuCh -eq "2") {
		installSoftware
	}
	if ($menuCh -eq "3") {
		serverMenu
	}	
	if ($menuCh -eq "4") {
		joinDomain
	}
	if ($menuCh -eq "0") {
		exit
	}	
}


Function init {
	elevateUAC
	menu
}

init