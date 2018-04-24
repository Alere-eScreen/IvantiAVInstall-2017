#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Program Version: 1.0.0
 Author:         Devin Duanne, Abbott - devin.duanne@escreen.com
 License: 		 GNU GPLv3 https://opensource.org/licenses/GPL-3.0

 Remarks:
	This application follows instructions listed under https://community.ivanti.com/docs/DOC-66419
	Exit codes follow the Windows System Error Code guide https://msdn.microsoft.com/en-us/library/windows/desktop/ms681382(v=vs.85).aspx


 Script Function:
	Installs BitDefender AV for LANDesk 2017

 Instructions for use:
	1. Navigate to your avclientdb folder on your core server and zip the contents of that folder into a .zip, .rar, or .7z file. Copy this into the directory with this script.
		1.a. The default directory for the avclientdb folder is `\\YourCoreName\ldlogon\avclientbd\`
	2. Define the target architecture below
	3. Build the script using SciTE
	4. Name the executable according to the architecture it is built for
	5. Place on public-facing web servers for download

#ce ----------------------------------------------------------------------------


#include <MsgBoxConstants.au3>
#include <Process.au3>
#Include <File.au3>
#Include <Array.au3>

#Region Installer Configuration
dim $architecture = "x86" ; Arch of target device. Values: x86, x64
dim $silent = true ; Use true for unattended installs
#EndRegion

#Region Application Settings
; Do not tamper with
dim $logFilePath = "C:\Windows\Temp\LANDeskAV\install.log"
dim $workDir = "C:\Windows\Temp\LANDeskAV"
dim $tempAVDir = ($architecture = "x86") ? "C:\Program Files\LANDesk\LDClient\temp_av" : "C:\Program Files (x86)\LANDesk\LDClient\temp_av"
dim $antivirusDir = ($architecture = "x86") ? "C:\Program Files\LANDesk\LDClient\antivirus" : "C:\Program Files (x86)\LANDesk\LDClient\antivirus"
#EndRegion


; Prompt user to continue
If ($silent = false) Then
	dim $Result

	$Result = msgbox(36,"LANDesk 2017 BitDefender Installer. . .","The LANDesk 2017 antivirus agent (BitDefender) is about to be installed" & @CRLF & "on this computer." & @CRLF & @CRLF & "This installation will require a reboot.  Once started, the installation" & @CRLF & "will run automatically without human intervention." & @CRLF & @CRLF & "Click 'Yes' to continue or 'No' to exit")

	If $Result = 7 Then
		msgbox(64,"Canceled","The LANDesk 2017 antivirus agent Installer has been canceled." & @CRLF & @CRLF & "No changes were made to this computer.")
		Exit
	EndIf
EndIf


; Create a temporary working directory
If (DirGetSize($workDir) <> -1) Then
	DirRemove($workDir, 1)
EndIf

DirCreate($workDir)

; Create the log file
Local $logFile = FileOpen($logFilePath, 1)

; Creating install directories
_FileWriteLog($logFile, "Creating install directory: " & $tempAVDir)
DirCreate($tempAVDir)

_FileWriteLog($logFile, "Creating install directory: " & $antivirusDir)
DirCreate($antivirusDir)

; Place the AV Install files in the install directories
_FileWriteLog($logFile, "Writing avclientbd.exe to " & $tempAVDir & "\avclientbd.exe")
FileInstall(".\avclientbd.exe", $tempAVDir & "\avclientbd.exe")

_FileWriteLog($logFile, "Writing avclientbd.exe to " & $antivirusDir & "\avclientbd.exe")
FileInstall(".\avclientbd.exe", $antivirusDir & "\avclientbd.exe")

; Extract files and clean up
_FileWriteLog($logFile, "Extracting files to " & $tempAVDir)
RunWait($tempAVDir & "\avclientbd.exe")
FileDelete($tempAVDir & "\avclientbd.exe")

_FileWriteLog($logFile, "Extracting files to " & $antivirusDir)
RunWait($antivirusDir & "\avclientbd.exe")
FileDelete($antivirusDir & "\avclientbd.exe")

; Perform special operation for x64 clients
If ($architecture = "x64") Then
	_FileWriteLog($logFile, "Renaming LDAV64.exe -> LDAV.exe (with overwrite)")
	FileMove($antivirusDir & "\LDAV64.exe", $antivirusDir & "\LDAV.exe", 1)

	_FileWriteLog($logFile, "Renaming LDAVDB64.dll -> LDAVDB.dll (with overwrite)")
	FileMove($antivirusDir & "\LDAVDB64.dll", $antivirusDir & "\LDAVDB.dll")
EndIf

; Run the install process
If ($silent = True) Then
	RunWait($antivirusDir & "\LDAV.exe /install", @SW_HIDE)
Else
	RunWait($antivirusDir & "\LDAV.exe /install")
	dim $rebootResult = MsgBox(36, "Reboot Required", "A reboot is required to complete the install. Reboot now?")
	if ($rebootResult = 7) Then
		Exit(0)
	EndIf
EndIf

; Reboot
Shutdown(6)
Exit(0)
