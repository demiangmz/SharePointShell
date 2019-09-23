#----------------------------------------------------------------------------------
# Script:  SharePointFarmWarmUp.ps1
# Author:  Demian Gomez
# Date:  04/22/2015
# Version: 1.0
# Based on http://spbestwarmup.codeplex.com/ script
#-----------------------------------------------------------------------------------

#-------------------------------------------------
# Ensure the SharePoint Snappin has been loaded
#-------------------------------------------------

If ( (Get-PSSnapin -Name “Microsoft.SharePoint.PowerShell” -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PSSnapin “Microsoft.SharePoint.PowerShell”}

#-------------
#Aux Variables
#-------------


#-------------
#Script START
#-------------


Function WarmUp() {
	
	# Get URL list
	
	$was = Get-SPWebApplication -IncludeCentralAdministration
	$was | ? {$_.IsAdministrationWebApplication -eq $true} |% {$caTitle = Get-SPWeb $_.Url | Select Title}
	
	# Warm up SharePoint web applications
	Write-Host "Opening Web Applications..."
	$global:ie = New-Object -Com "InternetExplorer.Application"
	$global:ie.Navigate("about:blank")
	$global:ie.Visible = $true
	$global:ieproc = (Get-Process -Name iexplore)|? {$_.MainWindowHandle -eq $global:ie.HWND}
	
	foreach ($wa in $was) {
		$url = $wa.Url
		IENavigateTo $url
		IENavigateTo $url"_layouts/viewlsts.aspx"
		IENavigateTo $url"_vti_bin/UserProfileService.asmx"
		IENavigateTo $url"_vti_bin/sts/spsecuritytokenservice.svc"
	}
	
	# Warm up Service Applications
	Get-SPServiceApplication |% {$_.EndPoints |% {$_.ListenUris |% {IENavigateTo $_.AbsoluteUri}}}
	
	# Warm up custom URLs
	Write-Host "Opening Custom URLs..."
	IENavigateTo "http://localhost:32843/Topology/topology.svc"
    
    # Warm up Host Name Site Collections (HNSC)
	Write-Host "Opening Host Name Site Collections (HNSC)..."
	$hnsc = Get-SPSite -Limit All |? {$_.HostHeaderIsSiteName -eq $true} | Select Url
	foreach ($sc in $hnsc) {
		IENavigateTo $sc.Url
	}
    
    # Add your own URLs below.  Looks at Central Admin Site Title for full lifecycle support in a single script file.
    	
  IENavigateTo "https://sharepoint.com"


	switch -Wildcard ($caTitle) {
		"*PROD*" {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
		"*TEST*" {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
		"*DEV*" {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
		default {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
	}
	
	# Close IE window
	if ($global:ie) {
		Write-Host "Closing IE"
		$global:ie.Quit()
	}
	$global:ieproc | Stop-Process -Force -ErrorAction SilentlyContinue
	
	# Clean Temporary Files
	Remove-item "$env:systemroot\system32\config\systemprofile\appdata\local\microsoft\Windows\temporary internet files\content.ie5\*.*" -Recurse -ErrorAction SilentlyContinue
	Remove-item "$env:systemroot\syswow64\config\systemprofile\appdata\local\microsoft\Windows\temporary internet files\content.ie5\*.*" -Recurse -ErrorAction SilentlyContinue
    Remove-item "$env:systemroot\SysWOW64\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\IE*.*" -Recurse -ErrorAction SilentlyContinue 
}

Function IENavigateTo([string] $url, [int] $delayTime = 500) {
	# Navigate to a given URL
	if ($url) {
		if ($url.ToUpper().StartsWith("HTTP")) {
			Write-Host "  Navigating to $url"
			try {
				$global:ie.Navigate($url)
			} catch {
				try {
					$pid = $global:ieproc.id
				} catch {}
				Write-Host "  IE not responding.  Closing process ID $pid"
				$global:ie.Quit()
				$global:ieproc | Stop-Process -Force -ErrorAction SilentlyContinue
				$global:ie = New-Object -Com "InternetExplorer.Application"
				$global:ie.Navigate("about:blank")
				$global:ie.Visible = $true
				$global:ieproc = (Get-Process -Name iexplore)|? {$_.MainWindowHandle -eq $global:ie.HWND}
			}
			IEWaitForPage $delayTime
		}
	}
}

Function IEWaitForPage([int] $delayTime = 500) {
	# Wait for current page to finish loading
	$loaded = $false
	$loop = 0
	$maxLoop = 60
	while ($loaded -eq $false) {
		$loop++
		if ($loop -gt $maxLoop) {
			$loaded = $true
		}
		[System.Threading.Thread]::Sleep($delayTime) 
		# If the browser is not busy, the page is loaded
		if (-not $global:ie.Busy)
		{
			$loaded = $true
		}
	}
}

#Main
Start-Transcript C:\Scripts\WarmUpLog.txt
Write-Host "SP WarmUp script"

#Check Permission Level
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    break

} else {
    #Warm up
    $global:path = $MyInvocation.MyCommand.Path
    WarmUp
}
Stop-Transcript
$Log = Get-Content C:\Scripts\WarmUpLog.txt
$Log > C:\Scripts\WarmUpLog.txt


#-------------
#Script END
#-------------
