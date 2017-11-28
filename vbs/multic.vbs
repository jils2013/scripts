# $language = "VBScript"
# $interface = "1.0"

' Session list file sample 
'hosta|10.0.1.2|root|pwd1 
'hostb|10.0.1.3|root|pwd2 
'hostc|10.0.1.4|root|pwd3 
'hostd|10.0.1.5|root|pwd4

'useage
'1.hosta,hostb,hostc
'2.hoste?,hostf??:using userset/passset,The number of question marks corresponds to the array index
'3.C:using string in clipboard using format as Session-list-file

Dim szSessionsFile, userset, passset
szSessionsFile = "Z:\SecureCRT-Scripts\SessionList.txt"

userset = Array("root","root","root")
passset = Array("123","456","789")

Sub Main()

	Dim objFso, objShell, objTextStream, inputStr, szSession

	Set objFso = CreateObject("Scripting.FileSystemObject")
	Set objShell = CreateObject("WScript.Shell")

	Set connTab = CreateObject("Scripting.Dictionary") 

'	Set tmpPath = objFso.GetSpecialFolder(2)
	tmpPath = objShell.ExpandEnvironmentStrings("%Temp%")
'	tmpPath = objShell.SpecialFolders("Desktop")
	tmpFile = tmpPath & "\SessionList.txt"

	if crt.Arguments.Count <> 0 then
		inputStr = crt.Arguments
	else
		inputStr = crt.Dialog.Prompt("Input are required:", "MultiSessions", "", False)
		if Trim(inputStr) = "" then
			exit sub
		end if
	end if

'	tmpFilename = objFso.GetTempName
'	tmpFile = tmpPath  & "\" & tmpFilename
'	crt.Dialog.MessageBox tmpPath & tmpFile
'	Set cliptmpfile=tmpPath.CreateTextFile(tmpFilename)
'	cliptmpfile.writeline(crt.clipboard.text)
'	cliptmpfile.close()	

	SessionsFileGet = 0
	connList = Split(inputStr,",")

	for each input in connList: Do
		conn = Trim(input)
		connreplaced = Replace(conn,"?","")
		if conn <> "" And connreplaced <> "" then
			sn = Len(conn) - Len(connreplaced)
			if sn > 0 then
				GetConntionTab userset(sn - 1),passset(sn - 1),Replace(conn,"?","")
			elseif conn = "C" then
'				crt.Dialog.MessageBox crt.clipboard.text
				for each line in Split(crt.clipboard.text,vbCrLf)
					conninfo = GetConnInfo(line)
					if ubound(conninfo) = 3 then
						error = error & GetConntionTab(conninfo(0),conninfo(1),conninfo(2))
					end if
				next
			else
				if SessionsFileGet = 0 then
					if Not objFso.FileExists(szSessionsFile) then
							crt.Dialog.MessageBox "Session list file not found:" & vbcrlf & _
								vbcrlf & _
								szSessionsFile & vbcrlf & vbcrlf & _
								"Create a session list file as described in the description of " & _
								"this script code and then run the script again."
							SessionsFileGet = 9
							exit Do
					end if

'					Copy session list file to tmpPath
					objFso.CopyFile szSessionsFile,tmpFile,True	
					SessionsFileGet = 1
				end if
				if SessionsFileGet = 1 and Not connTab.exists(Ucase(conn)) then
					connTab.Add Ucase(conn),"1"
'					crt.Dialog.MessageBox conn & " using session.txt"
				end if
			end if
		end if
	Loop While False: next

	if SessionsFileGet = 1 then
		Set objTextStream = objFso.OpenTextFile(tmpFile, 1, false)
		Do While Not objTextStream.AtEndOfStream and connTab.Count <> 0
			szSession = Trim(objTextStream.ReadLine)
'			Don't add empty lines/sessions
			conninfo = GetConnInfo(szSession)
			if ubound(conninfo) = 3 then
				if connTab.exists(Ucase(conninfo(3))) then
					connTab.remove(Ucase(conninfo(3)))
					error = error & GetConntionTab(conninfo(0),conninfo(1),conninfo(2))
				end if
			end if
		Loop
	end if
	if connTab.Count <> 0 then
		error = error & "Host(s) not found in session list file:" & vbcrlf & join(connTab.keys(),",")
	end if
	if error <> "" Then 
		crt.Dialog.MessageBox error
	end if

End Sub

Function GetConnInfo(szSession)
	Dim Sections
	Sections = Split(szSession, "|")
	if ubound(Sections) >= 3 then
		if Sections(1) = "/" then
			GetConnInfo = Array(Sections(2),Sections(3),Sections(0),Sections(0))
		else
			GetConnInfo = Array(Sections(2),Sections(3),Sections(1),Sections(0))
		end if
		else
		GetConnInfo = Array(0)
	end if
End Function

Function GetConntionTab(username,password,hostname)
'	crt.Dialog.MessageBox hostname & username & password
	On Error Resume Next
	crt.Session.ConnectInTab "/SSH2 /L " + username + " /PASSWORD " + password + " " + hostname,false
	if Err.Number <> 0 Then 
		GetConntionTab = hostname & ":" & Err.Description
	else
		GetConntionTab = Nothing
	end if
End Function
