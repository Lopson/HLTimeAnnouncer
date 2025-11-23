Set objShell = CreateObject("WScript.Shell")
objShell.Run """C:\Program Files\PowerShell\7\pwsh.exe"" -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File ""{PATH_TO_SCRIPT}\HourAnnouncer.ps1""", 0, False
