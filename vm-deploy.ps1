
function elevateUAC {
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
		Write-Host "This script requires administrator rights. Auto elevating in 5 seconds.."
		timeout /t 5 /nobreak
		Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
		exit
	}
}


## Network Config

Function setNetworking {
	$networkCh = read-host -Prompt "Use Static/DHCP? (s/d)"
	if ($networkCh -eq "s") {
		Get-WmiObject win32_networkadapter -filter "netconnectionstatus = 2" | select Name
		$interface = read-host -Prompt "Interface Name"
		$ip = read-host -Prompt "IP Address"
		$netmask = read-host -Prompt "Netmask"
		$gateway = read-host -Prompt "Gateway Address"
		$confirm = read-host -Prompt "Confirm? (y/n)"
		if ($confirm -eq "y") {
			netsh interface ip set address name="$interface" static $ip $netmask $gateway
			Write-host "Testing network connection.."
			ping $gateway
			if ($lastexitcode -eq "0") {
				Write-host "Test successful, network is ready."
			}
			else {
				Write-host "Connection Error. Please check network settings / firewall rules!"
			}
		}
	}
	if ($networkCh -eq "d") {
		Get-WmiObject win32_networkadapter -filter "netconnectionstatus = 2" | select Name
		$interface = read-host -Prompt "Interface Name"
		$confirm = read-host -Prompt "Confirm? (y/n)"
		if ($confirm -eq "y") {
			netsh interface ip set address "$interface" dhcp
			Write-host "Testing network connection.."
			ping $gateway
			if ($lastexitcode -eq "0") {
				Write-host "Test successful, network is ready."
			}
			else {
				Write-host "Connection Error. Please check network settings / firewall rules!"
			}
		}
	}
	menu
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
		Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	}
}


## Domain

Function joinDomain {
	$domainName = read-host -Prompt "Domain Name?"
	Add-Computer –DomainName $domainName –Credential (Get-Credential)
	menu
}



Function installSoftware {
	checkChoco
	$softwareList = read-host -Prompt "Provide Software list path."
	Write-host
	Write-host === List Start ===
	Write-host Software names are referenced from Chocolatey repo.
	foreach ($item in gc "$softwareList") {
		Write-Output "$item"
	}
	Write-host === List End ===
	Write-host
	Write-Output "Is this list provided correct?"
	$confirm2 = read-host -Prompt "(y/n)"
	if ($confirm -eq "y") {
		Write-Output "Commencing software install.."
		foreach ($item in gc $software) {
			choco install -y "$item" 
			Write-Output "Installing $item."
		}
		Write-Host "Installation complete."
		Write-Host "Initiating reboot."
		Start-Sleep 2
		Restart-Computer
	}
	else {
		Write-host Return to menu.
		menu
	}
}


function menu {
	Write-host 
	Write-host "Script for quick deployment of new virtual machines. Installs software using Chocolatey package manager."
	Write-host "1. Configure networking"
	Write-host "2. Install software"
	Write-host "3. Join Domain"
	Write-host "0. Exit"
	Write-host
	$menuCh = read-host -Prompt "Choose an option."
	
	if ($menuCh -eq "1") {
		setNetworking
	}
	if ($menuCh -eq "2") {
		installSoftware
	}
	if ($menuCh -eq "3") {
		joinDomain
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