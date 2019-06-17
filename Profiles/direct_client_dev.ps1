
function elevateUAC {
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
		Write-Host "This script requires administrator rights. Auto elevating in 5 seconds.."
		Start-Sleep 5
		powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
		exit
	}
}

Function installSoftware {
    $software = @(

        #software list
		googlechrome
		sysmon
		nxlog
		7zip.install
		adobereader
		officeproplus2013
		flashplayerplugin
		dotnet4.5.2
		notepadplusplus
		javaruntime
		putty.install
		winscp
		git
		curl
		python2
		python3
		
		
    )
    foreach ($item in $software) {
		choco install "$item"
        Write-Output "Installing $item."
    }
}

function init {
	elevateUAC
	Write-host "This simple script installs software using chocolatey package manager."
	installSoftware
	Write-Host "Installation complete."
	Write-Host "Initiating reboot."
    Stop-Transcript
    Start-Sleep 2
    Restart-Computer
}

init