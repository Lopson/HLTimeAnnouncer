#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
[string[]]$VOX_VOICE_START = @("doop");
[string[]]$VOX_READING_START = @("_period", "it", "is", "now");
[string[]]$FVOX_VOICE_START = @("bell");
[string[]]$FVOX_READING_START = @("_period", "time_is_now");
[string]$ANNOUNCER_TO_USE = "fvox";
[bool]$FOLLOW_THEME = $true;
[bool]$FORCE_RUN = $true;
[bool]$READ_OUT_LOUD = $true;
[bool]$READ_DURING_MEDIA_PLAYBACK = $false;

# Function for getting the current status of all media playback applications
# on Windows platforms. This relies on System Media Transport Controls, which
# are the elements that Windows uses to show media playback information on the
# taskbar and the lock screen.
function Get-SMTCSessions {
    # Invoke Powershell 5 to run all of the Windows RT code we need.
    # We're resorting to this because no matter how hard I tried, I couldn't
    # get the newer Core versions to handle `IAsyncOperation` implementations.
    return powershell {
        [void][Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType=WindowsRuntime];
        Add-Type -AssemblyName "System.Runtime.WindowsRuntime";

        # https://superuser.com/a/1342416
        $asTaskGeneric = (
            [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
                $_.Name -eq 'AsTask' -and
                $_.GetParameters().Count -eq 1 -and
                $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
            }
        )[0];

        function Await {
            param(
                $WinRtTask,
                $ResultType
            )
            
            $asTask = $asTaskGeneric.MakeGenericMethod($ResultType);
            $netTask = $asTask.Invoke($null, @($WinRtTask));
            [void]$netTask.Wait(-1);
            $netTask.Result;
        }

        # Get the SMTC session manager.
        $WindowsSessionManager = Await -WinRtTask (
            [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) `
            -ResultType ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]);

        # Get current SMTC sessions.
        $SMTCSessions = $WindowsSessionManager.GetSessions();

        # NOTE Since the Powershell Block to Powershell Host transfer of
        # data doesn't seem to like all of the oddball data types that the
        # SMTC stuff generates, we're getting all of the data and putting
        # it into a PSCustomObject.
        $result = [System.Collections.ArrayList]@();
        foreach ($SMTCSession in $SMTCSessions) {
            $mediaProperties = Await -WinRtTask ($SMTCSession.TryGetMediaPropertiesAsync()) `
                -ResultType ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties]);

            [void]$result.Add(
                [PSCustomObject]([ordered]@{
                    PlaybackApp = $SMTCSession.SourceAppUserModelId
                    # Available statuses: https://learn.microsoft.com/en-us/uwp/api/windows.media.control.globalsystemmediatransportcontrolssessionplaybackstatus?view=winrt-28000
                    PlaybackStatus = $SMTCSession.GetPlaybackInfo().PlaybackStatus
                    MediaTitle = $mediaProperties.Title
                    MediaArtist = $mediaProperties.Artist
                    MediaAlbumTrackCount = $mediaProperties.AlbumTrackCount
                    # NOTE For some reason getting the genres is returning a COM object?
                    # MediaGenres = $mediaProperties.Genres.ToString()
                    MediaPlaybackType = $mediaProperties.PlaybackType
                    MediaSubtitle = $mediaProperties.Subtitle
                    MediaThumbnail = $mediaProperties.Thumbnail
                    MediaTrackNumber = $mediaProperties.TrackNumber
                })  
            );
        }

        return $result;
    };
}

# Function to see if our OS is currently detecting media being played back.
function Get-MediaActiveStatus {
    [OutputType([bool])]

    [bool]$result = $false;
    
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        foreach ($smtcSession in $(Get-SMTCSessions)) {
            # NOTE Should we be using the enum in Microsoft.Windows.SDK.NET.Ref?
            # Yes. Do we want to add a dependency to this? No.
            if ($smtcSession.PlaybackStatus -eq 4) {
                $result = $true;
            }
        }
    }

    return $result;
}

enum SystemThemes : int {
    light
    dark
    undefined
}

# Function to check if we're in light or dark mode. We're using this to figure
# out if the sun has set, which we can then use to kick in a nighttime-specific
# voice bank.
function Get-CurrentSystemTheme {
    [OutputType([SystemThemes])]

    $result = [SystemThemes]::undefined;
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        if ((Get-ItemProperty -Path `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                -Name "SystemUsesLightTheme").SystemUsesLightTheme -eq 0) {
            $result = [SystemThemes]::dark;
        }
        else {
            $result = [SystemThemes]::light;
        }
    }

    return $result;
}

# The function that performs the hour announcement playback.
function Read-HourOutLoud {
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 24)]
        [int]$CurrentHour,

        [ValidateSet("vox", "fvox")]
        [string]$Announcer = "vox"
    )

    # Determine which start of announcement we'll be using.
    switch ($Announcer) {
        "vox"  { [string[]]$VoiceLines = $VOX_VOICE_START.Clone();  }
        "fvox" { [string[]]$VoiceLines = $FVOX_VOICE_START.Clone(); }
    }

    # fvox announcer doesn't have voice line for zero.
    if ($CurrentHour -eq 0 -and $Announcer -eq "fvox") {
        $CurrentHour = 24;
    }

    [bool]$isMediaPlayingBack = Get-MediaActiveStatus;
    if ($READ_OUT_LOUD -and (
            -not $isMediaPlayingBack -or (
                $isMediaPlayingBack -and $READ_DURING_MEDIA_PLAYBACK))) {
        switch ($Announcer) {
           "vox"  { $VoiceLines += $VOX_READING_START;  }
           "fvox" { $VoiceLines += $FVOX_READING_START; }
        }

        # Build the list of voice lines to use.
        switch ($CurrentHour) {
            0  { $VoiceLines += "zero", "hours"; }
            1  {
                switch ($Announcer) {
                    "vox"  { $VoiceLines += "one", "hour"; }
                    # fvox announcer doesn't have voice line for "hour".
                    "fvox" { $VoiceLines += "one", "hours"; }
                }
            }
            2  { $VoiceLines += "two", "hours"; }
            3  { $VoiceLines += "three", "hours"; }
            4  { $VoiceLines += "four", "hours"; }
            5  { $VoiceLines += "five", "hours"; }
            6  { $VoiceLines += "six", "hours"; }
            7  { $VoiceLines += "seven", "hours"; }
            8  { $VoiceLines += "eight", "hours"; }
            9  { $VoiceLines += "nine", "hours"; }
            10 { $VoiceLines += "ten", "hours"; }
            11 { $VoiceLines += "eleven", "hours"; }
            12 { $VoiceLines += "twelve", "hours"; }
            13 { $VoiceLines += "thirteen", "hours"; }
            14 { $VoiceLines += "fourteen", "hours"; }
            15 { $VoiceLines += "fifteen", "hours"; }
            16 { $VoiceLines += "sixteen", "hours"; }
            17 { $VoiceLines += "seventeen", "hours"; }
            18 { $VoiceLines += "eighteen", "hours"; }
            19 { $VoiceLines += "nineteen", "hours"; }
            20 { $VoiceLines += "twenty", "hours"; }
            21 { $VoiceLines += "twenty", "one", "hours"; }
            22 { $VoiceLines += "twenty", "two", "hours"; }
            23 { $VoiceLines += "twenty", "three", "hours"; }
            24 { $VoiceLines += "twenty", "four", "hours"; }
        }
    }

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        foreach ($word in $VoiceLines) {
            $WordPath = Join-Path $PSScriptRoot $Announcer "$word.wav";
            if (-not (Test-Path -LiteralPath $WordPath -PathType "Leaf")) {
                throw [System.IO.FileNotFoundException] (
                    "Couldn't find file $WordPath");
            }

            (New-Object System.Media.SoundPlayer $WordPath).PlaySync();
        }
    }
}

[string]$MutexName = "Global\HLTimeAnnouncerMutex";
[System.Threading.Mutex]$Mutex = New-Object System.Threading.Mutex(
    $false, $MutexName);

if ($FOLLOW_THEME) {
    if ((Get-CurrentSystemTheme) -in @(
            [SystemThemes]::light, [SystemThemes]::undefined)) {
        [string]$ANNOUNCER_TO_USE = "vox";
    }
    elseif ((Get-CurrentSystemTheme) -eq [SystemThemes]::dark) {
        [string]$ANNOUNCER_TO_USE = "fvox";
    }
}

try {
    # Only run logic if we're at the top of the hour.
    # This is yet another piece of logic to minimize the number of instances
    # when Windows scheduler attempts to run this script after waking up
    # from sleep or when the scheduler runs this task twice in a row.
    [int]$CurrentMinute = ([datetime]::Now).Minute;
    if ($CurrentMinute -ne 0 -and -not $FORCE_RUN) {
        exit;
    }

    # Attempt to acquire the mutex.
    # Wait 0ms to avoid blocking; return immediately.
    # $false = do not exit context (required for non-GUI apps like PowerShell)
    $MutexAcquired = $Mutex.WaitOne(0, $false);

    # Mutex not acquired, another instance of script is already running. Exit.
    if (-not $MutexAcquired) {
        exit 1;
    }

    # Run the announcer logic.
    [int]$CurrentHour = ([datetime]::Now).Hour;
    Read-HourOutLoud $CurrentHour -Announcer $ANNOUNCER_TO_USE;
}
finally {
    # Release the mutex if we acquired it (critical to avoid orphaned locks).
    if ($mutexAcquired) {
        $Mutex.ReleaseMutex();
    }

    # Clean up the mutex object.
    $Mutex.Dispose();
}
