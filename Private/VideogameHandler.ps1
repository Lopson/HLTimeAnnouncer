# Tests if a Steam game is running.
function Test-SteamGameRunning {
    [OutputType([bool])]
    param()

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $SteamRegistry = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam";
        if ($SteamRegistry -and $SteamRegistry.RunningAppID -ne 0) {
            return $true;
        }
    }

    return $false;
}

# C# code required to be able to detect fullscreen applications on Windows.
if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows)) {
    $SHQueryUserNotificationStateCode = @"
using System.Runtime.InteropServices;

// https://learn.microsoft.com/en-us/windows/win32/api/shellapi/ne-shellapi-query_user_notification_state
public enum QUERY_USER_NOTIFICATION_STATE {
    QUNS_NOT_PRESENT = 1,
    QUNS_BUSY = 2,
    QUNS_RUNNING_D3D_FULL_SCREEN = 3,
    QUNS_PRESENTATION_MODE = 4,
    QUNS_ACCEPTS_NOTIFICATIONS = 5,
    QUNS_QUIET_TIME = 6,
    QUNS_APP = 7
};

public class NotificationState {
    [DllImport("shell32.dll")]
    public static extern int SHQueryUserNotificationState(
        out QUERY_USER_NOTIFICATION_STATE pquns);
}
"@;

    Add-Type -TypeDefinition $SHQueryUserNotificationStateCode -Language CSharp;
}

# Tries to figure out if there's any fullscreen applications currently
# running in the host system.
function Test-RunningFullscreenApps {
    [OutputType([bool])]
    param()

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $state = [QUERY_USER_NOTIFICATION_STATE]::QUNS_NOT_PRESENT;
        $hresult = [NotificationState]::SHQueryUserNotificationState([ref]$state);

        if( $hresult -lt 0 ) {
            throw "SHQueryUserNotificationState failed";
        }
        
        switch($state) {
            "QUNS_NOT_PRESENT"             { return $false; }
            "QUNS_BUSY"                    { return $true;  }
            "QUNS_RUNNING_D3D_FULL_SCREEN" { return $true;  }
            "QUNS_PRESENTATION_MODE"       { return $true;  }
            "QUNS_ACCEPTS_NOTIFICATIONS"   { return $false; }
            "QUNS_QUIET_TIME"              { return $false; }
            "QUNS_APP"                     { return $false; }
            default                        { return $false; }
        }
    }

    return $false;
}

# Tells us if a videogame is currently running in our system.
function Test-VideogameRunning {
    [OutputType([bool])]

    [bool]$result = (Test-RunningFullscreenApps -or Test-SteamGameRunning);
    return $result;
}
