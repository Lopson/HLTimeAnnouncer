#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

# Source the configuration file.
. (Get-ChildItem (Join-Path $PSScriptRoot "Configuration.ps1")).FullName;

# Source all classes.
foreach ($class in (
        Get-ChildItem (Join-Path $PSScriptRoot "Classes") `
            -ErrorAction SilentlyContinue)
) {
    . $class.FullName;
}

# Source all auxiliary functions.
foreach ($private in (
        Get-ChildItem (Join-Path $PSScriptRoot "Private") `
            -Filter "*.ps1" -ErrorAction SilentlyContinue)
) {
    . $private.FullName;
}

# Source all voice pack definitions.
[hashtable]$Global:VoicePacks = @{};
foreach ($voiceFile in (
        Get-ChildItem (Join-Path $PSScriptRoot $ANNOUNCERS_FOLDER) `
            -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue)
) {
    . $voiceFile.FullName;
}

# Setup argument validation for usable packs.
class ValidVoicePacks : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return $Global:VoicePacks.Keys;
    }
}

# The function that performs the hour announcement playback.
function Read-HourOutLoud {
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 24)]
        [int]$CurrentHour,

        [Parameter(Mandatory = $true)]
        [ValidateSet([ValidVoicePacks])]
        [string]$Announcer
    )

    # Determine which start of announcement we'll be using.
    [string[]]$VoiceLines = $Global:VoicePacks[$Announcer].VoiceStart;

    [bool]$isMediaPlayingBack = Get-MediaActiveStatus;
    [bool]$isVideogameRunning = Test-VideogameRunning;
    [bool]$isDndActive = Get-DndStatus -eq [DndStatus]::disabled ? $false : $true;
    if ($READ_OUT_LOUD -and (
            -not $isMediaPlayingBack -or (
                $isMediaPlayingBack -and $READ_DURING_MEDIA_PLAYBACK)) -and (
            -not $isVideogameRunning -or (
                $isVideogameRunning -and $READ_DURING_VIDEOGAMES)) -and (
            -not $isDndActive -or (
                $isDndActive -and $READ_DURING_DND))
    ) {
        # Get the start of the reading out loud portion.
        $VoiceLines += $Global:VoicePacks[$Announcer].ReadingStart;

        # Get the voice lines to use.
        $VoiceLines += $Global:VoicePacks[$Announcer].HourLines[$CurrentHour];
    }

    foreach ($word in $VoiceLines) {
        $WordPath = (Join-Path $PSScriptRoot `
            $ANNOUNCERS_FOLDER $Announcer `
            "$word.$($Global:VoicePacks[$Announcer].FileExtension)");
        
        if (-not (Test-Path -LiteralPath $WordPath -PathType "Leaf")) {
            throw [System.IO.FileNotFoundException] (
                "Couldn't find file $WordPath");
        }
        
        # Play back each of the audio files.
        if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
                [System.Runtime.InteropServices.OSPlatform]::Windows)) {
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
