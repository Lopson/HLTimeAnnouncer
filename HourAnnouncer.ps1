#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
[string[]]$VOICE_START = @("doop", "_period", "it", "is", "now");

function Read-HourOutLoud {
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 24)]
        [int]$CurrentHour
    )

    [string[]]$VoiceLines = $VOICE_START.Clone();

    switch ($CurrentHour) {
        0 { $VoiceLines += "zero", "hours"; }
        1 { $VoiceLines += "one", "hour"; }
        2 { $VoiceLines += "two", "hours"; }
        3 { $VoiceLines += "three", "hours"; }
        4 { $VoiceLines += "four", "hours"; }
        5 { $VoiceLines += "five", "hours"; }
        6 { $VoiceLines += "six", "hours"; }
        7 { $VoiceLines += "seven", "hours"; }
        8 { $VoiceLines += "eight", "hours"; }
        9 { $VoiceLines += "nine", "hours"; }
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

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        foreach ($word in $VoiceLines) {
            $WordPath = Join-Path $PSScriptRoot "vox" "$word.wav";
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

try {
    # Only run logic if we're at the top of the hour.
    # This is yet another piece of logic to minimize the number of instances
    # when Windows scheduler attempts to run this script after waking up
    # from sleep or when the scheduler runs this task twice in a row.
    [int]$CurrentMinute = ([datetime]::Now).Minute;
    if ($CurrentMinute -ne 0) {
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
    Read-HourOutLoud $CurrentHour;
}
finally {
    # Release the mutex if we acquired it (critical to avoid orphaned locks).
    if ($mutexAcquired) {
        $Mutex.ReleaseMutex();
    }

    # Clean up the mutex object.
    $Mutex.Dispose();
}
