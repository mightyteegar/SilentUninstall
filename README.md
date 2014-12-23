SilentUninstall
===============

NAME: SilentUninstall.ps1

SYNOPSIS: Uninstall one or more programs given a search query

COPYRIGHT: (c) 2014 Dave Baker, teegar (AT) gmail

LICENSE: You may freely use and modify this script as you like to suit your own needs.
You may not distribute the script unless given explicit permission by the author.  

## SYNTAX ##

     SilentUninstall.ps1 <search> [-u] [-nosim] [-verbose]

Search terms with multiple words should be enclosed in quotes -- examples:
     SilentUninstall.ps1 cisco
     SilentUninstall.ps1 "cisco anyconnect"   

Searches are for EXACT terms, so a search for "Microsoft Office" would return 
"Microsoft Office 2013" and "Update for Microsoft Office", but NOT "Microsoft
Update KB851215 for Office 2013"

Without the -u flag, simply returns a list of programs that would be uninstalled. It is 
STRONGLY RECOMMENDED to run the program without the -u flag first, to see what would actually
be uninstalled.  

Provide the -u flag to SIMULATE uninstalling all found programs. To actually perform
an uninstall, add the -nosim flag. **WARNING: Use with caution -- there is NO confirmation!**

     SilentUninstall.ps1 cisco -u          -- SIMULATES uninstalling EVERY program found with  
                                        the word "cisco" in the name, one at a time.

     SilentUninstall.ps1 cisco -u -nosim   -- ACTUALLY uninstalls EVERY program found with the word 
                                        "cisco" in the name, one at a time.

The -nosim flag exists to reduce the possibility of an accidental uninstallation.  

The -verbose option turns on some (extremely) rudimentary error reporting.  

## METHODOLOGY ##
Iterate "Uninstall" registry subkeys within the following key(s):
- HKLM:\software\microsoft\windows\currentversion\uninstall
- HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall 
       (on 64-bit systems)
Check the given search term against the name of the software package.  If
a package matches the term, list it on screen.  If the -u flag is provided,
uninstall the program using one of the methods below, in order of preference:
  1. (MSI installers only) Execute MsiExec with the /quiet flag
  2. If the program registry key has a "QuietUninstallString" value, 
     use that to uninstall the program
  3. Otherwise use the "UninstallString" value
     (In a future version, check against a known table of programs and
     "silent" uninstall switches and use the appropriate switch if a
     recognized program is found, e.g. Steam or VLC)

## PURPOSE ##
The ultimate goal of this script is to uninstall programs silently, e.g.
without any GUI feedback or user intervention.  MSI-installed programs
are of course easy to uninstall silently; the trickier part is accomplishing
this goal for programs installed using non-MSI installers like Inno or 
Nullsoft's NSIS packager. "Silent" switches are available for almost every
uninstall executable in the wild, and over time I will build out a table
of known programs and corresponding "silent" switches for their uninstall
executables.  This script could be used in conjunction with an RMM platform
such as Kaseya or N-Able, to automate uninstalls without interrupting or
requiring input from the end user.  
