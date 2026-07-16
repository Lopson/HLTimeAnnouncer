# Tests if a Steam game is running.
function Test-SteamGameRunning {
    [OutputType([bool])]

    [bool]$result = $false;

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $SteamRegistry = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam";
        if ($SteamRegistry -and $SteamRegistry.RunningAppID -ne 0) {
            $result = $true;
        }
    }

    return $result;
}

# Tells us if a videogame is currently running in our system.
function Test-VideogameRunning {
    [OutputType([bool])]

    [bool]$result = (Test-SteamGameRunning);
    return $result;
}
