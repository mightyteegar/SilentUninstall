<#
# NAME: SilentUninstall.ps1
# SYNOPSIS: Uninstall one or more programs given a search query
# COPYRIGHT: Dave Baker, Maybank Systems, (c) 2014
#
#
# SYNTAX
# SilentUninstall.ps1 <search> [-u] [-nosim] [-verbose]
#
# Search terms with multiple words should be enclosed in quotes -- examples:
# > SilentUninstall.ps1 cisco
# > SilentUninstall.ps1 "cisco anyconnect"   
# 
# Searches are for EXACT terms, so a search for "Microsoft Office" would return 
# "Microsoft Office 2013" and "Update for Microsoft Office", but NOT "Microsoft
# Update KB851215 for Office 2013"
# 
# Without the -u flag, simply returns a list of programs that would be uninstalled. It is 
# STRONGLY RECOMMENDED to run the program without the -u flag first, to see what would actually
# be uninstalled.  
# 
# Provide the -u flag to SIMULATE uninstalling all found programs. To actually perform
# an uninstall, add the -nosim flag. **WARNING: Use with # caution -- there is NO confirmation!**
#
# > SilentUninstall.ps1 cisco -u          -- SIMULATES uninstalling EVERY program found with  
#                                         the word "cisco" in the name, one at a time.
#
# > SilentUninstall.ps1 cisco -u -nosim   -- ACTUALLY uninstalls EVERY program found with the word 
#                                         "cisco" in the name, one at a time.
#
# The -nosim flag exists to reduce the possibility of an accidental uninstallation.  
#
# The -verbose option turns on some (extremely) rudimentary error reporting.  
#
# 
# METHODOLOGY
# Iterate "Uninstall" registry subkeys within the following key(s):
# - HKLM:\software\microsoft\windows\currentversion\uninstall
# - HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall 
#        (on 64-bit systems)
# Check the given search term against the name of the software package.  If
# a package matches the term, list it on screen.  If the -u flag is provided,
# uninstall the program using one of the methods below, in order of preference:
#   1. (MSI installers only) Execute MsiExec with the /quiet flag
#   2. If the program registry key has a "QuietUninstallString" value, 
#      use that to uninstall the program
#   3. Otherwise use the "UninstallString" value
#      (In a future version, check against a known table of programs and
#      "silent" uninstall switches and use the appropriate switch if a
#      recognized program is found, e.g. Steam or VLC)
#
# PURPOSE
# The ultimate goal of this script is to uninstall programs silently, e.g.
# without any GUI feedback or user intervention.  MSI-installed programs
# are of course easy to uninstall silently; the trickier part is accomplishing
# this goal for programs installed using non-MSI installers like Inno or 
# Nullsoft's NSIS packager. "Silent" switches are available for almost every
# uninstall executable in the wild, and over time I will build out a table
# of known programs and corresponding "silent" switches for their uninstall
# executables.  This script could be used in conjunction with an RMM platform
# such as Kaseya or N-Able, to automate uninstalls without interrupting or
# requiring input from the end user.  
#
#
#
#>

Param(
    [string]$program = "",
	[switch]$uninstall,
	[switch]$nosimulate,
    [switch]$verbose
)   

Function performUninstall($regPath) {

    foreach ($subkey in $regPath) {
		
        try {
            $entries = Get-ItemProperty $subkey.pspath
        }
        
        catch [System.InvalidCastException] {
            if ($verbose) {
                write-host "Error reading key entry, skipping" -Foregroundcolor yellow
            }
        }
        
        foreach ($entry in $entries) {
            $strUninsPath = ""
            $programName = $entry.DisplayName
            if ($entry.DisplayName -match "$program")  {
                
				if ($entry.QuietUninstallString) {
                    $strUninsPath = $entry.QuietUninstallString.Replace('"',"")
                    
                }
                elseif ($entry.UninstallString) {
                    $strUninsPath = $entry.UninstallString.Replace('"',"")
                    
                }
                else {
                    $strUninsPath = "_UNDEFINED_"
                }
				
                
                if ($strUninsPath.ToLower().StartsWith("msiexec")) {
                    $boolIsMSI = "Yes"
                }
                else {
                    $boolIsMSI = "No"
                }
                    
                 
                write-host $("=" * 80)
                write-host "Program Name: $programName"
                write-host "Uninstall String: $strUninsPath"
                write-host "MSI Uninstall: $boolIsMSI"
                write-host $("=" * 80)
                write-host ""
                
                if ($uninstall) { 
                    if ($boolIsMSI -eq "No") { 
					
                        $path_regex = "[a-z]\:\\.*\.exe\s?"
						$switch_regex = "[\-/]\-?[a-z0-9]+\s?"

						$uninsExe = ""
						$uninsSwitches = ""
						
						if ($strUninsPath -match $path_regex) { 
								$uninsExe += $matches[0].TrimEnd()
								$strUninsPath = $strUninsPath.Replace($uninsExe,"")
						}
						
						if ($strUninsPath -match $switch_regex) { 
							$strUninsPath | select-string $switch_regex -allmatches | foreach {$uninsSwitches += $_.matches.value} | out-null
						}

					
							write-host "Uninstalling program $programName . . ."						
							
							if ($uninsSwitches -ne "") {
								
								write-host "$uninsExe $uninsSwitches"
								write-host "$script_action start-process -path `"$uninsExe`" -arg `"$uninsSwitches`""
								if ($nosimulate) {
									start-process "$uninsExe" -arg "$uninsSwitches" -wait
								}
							}
							else {  
								
								write-host "$uninsExe"
								write-host "$script_action start-process -path `"$uninsExe`""
								if ($nosimulate) {
									start-process "$uninsExe" -wait
								}
								
							}
			
							write-host "Uninstall complete.  Check Programs and Features to confirm."
							
						}
                    else { 
                        
                        $arrMSIString = $strUninsPath.split()
                        $strMSIProdCode = $arrMSIString[1].Replace("/I","")
                        $strMSIProdCode = $strMSIProdCode.Replace("/X","")
                        
                        write-host "Uninstalling program $programName with MSI Product Code $strMSIProdCode . . ."
                        if ($nosimulate) {
							start-process "msiexec" -arg "/x $strMSIProdCode /quiet" -wait
						}
						else {
							write-host "SIMULATE start-process `"msiexec`" -arg `"/x $strMSIProdCode /quiet`" -wait"
						}

						write-host "Uninstall complete.  Check Programs and Features to confirm."
                        
                    }
                }
            }
        }
    }
}

if ($program -eq "") {
    $program = "PROGRAM_UNDEFINED"
}

if ($nosimulate) {
	$script_action = "EXECUTE"
}
else {
	$script_action = "SIMULATE"
}

# Get architecture and enumerate appropriate registry uninstall path(s)

$strOsArch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

$regUninstPath = Get-ChildItem -path hklm:\software\microsoft\windows\currentversion\uninstall
if ($strOsArch.Contains("64")) { $reg64BitUninstPath = Get-ChildItem -path hklm:\software\wow6432node\microsoft\windows\currentversion\uninstall }

write-host ""
write-host "Searched for:    $program"
write-host "OS Architecture: $strOsArch"
write-host ""

if ($reg64BitUninstPath) {
    performUninstall($reg64BitUninstPath)
}

performUninstall($regUninstPath)
write-host ""

# TODO LIST
# - Maintain a list of "silent" uninstall switches like /silent, /S, -s, /quiet etc.
#   for known non-MSI programs like e.g. Steam.  When a recognized program is run, 
#   tack on the appropriate "silent" switch.  
#
#  STEAM   uninstall.exe /S      
#  VLC     uninstall.exe /S      2.1.5
#  7-ZIP   Uninstall.exe /S      (32 bit version only; 64-bit uses MSI)
#
# - Handle programs that are in Programs and Features list, but don't show up in 
#   search results ... where are the uninstall reg keys for these programs?  
# - More and better error handling and reporting
# - Ability to email results when finished
