param([string] $profile = " ")

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

Function installSoftwareDirect($profile) {
	checkChoco
	Write-Output "Commencing software install.."
	foreach ($item in gc "$profile") {
		Write-Output "Installing $item."
		choco install -y $p
	}
	Write-Host "Installation complete."
	Write-Host "Initiating reboot."
	Start-Sleep 3
	Restart-Computer
}