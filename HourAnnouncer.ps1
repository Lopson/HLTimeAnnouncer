#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

# Source the configuration file.
. (Get-ChildItem (Join-Path $PSScriptRoot "Configuration.ps1")).FullName;

# Source all auxiliary functions.
foreach ($private in (
        Get-ChildItem (Join-Path $PSScriptRoot "Private") `
            -ErrorAction SilentlyContinue)
) {
    . $private.FullName;
}

# Source all voice pack definitions.
foreach ($voiceFile in (
        Get-ChildItem (Join-Path $PSScriptRoot $ANNOUNCERS_FOLDER) `
            -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue)
) {
    . $voiceFile.FullName;
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
        switch ($Announcer) {
           "vox"  { $VoiceLines += $VOX_READING_START;  }
           "fvox" { $VoiceLines += $FVOX_READING_START; }
        }

        # Build the list of voice lines to use.
        switch ($CurrentHour) {
            0  { $VoiceLines += "zero", "hours"; }
            1  {
                switch ($Announcer) {
                    "vox"  { $VoiceLines += "one", "hour";  }
                    # fvox announcer doesn't have voice line for "hour".
                    "fvox" { $VoiceLines += "one", "hours"; }
                }
            }
            2  { $VoiceLines += "two", "hours";             }
            3  { $VoiceLines += "three", "hours";           }
            4  { $VoiceLines += "four", "hours";            }
            5  { $VoiceLines += "five", "hours";            }
            6  { $VoiceLines += "six", "hours";             }
            7  { $VoiceLines += "seven", "hours";           }
            8  { $VoiceLines += "eight", "hours";           }
            9  { $VoiceLines += "nine", "hours";            }
            10 { $VoiceLines += "ten", "hours";             }
            11 { $VoiceLines += "eleven", "hours";          }
            12 { $VoiceLines += "twelve", "hours";          }
            13 { $VoiceLines += "thirteen", "hours";        }
            14 { $VoiceLines += "fourteen", "hours";        }
            15 { $VoiceLines += "fifteen", "hours";         }
            16 { $VoiceLines += "sixteen", "hours";         }
            17 { $VoiceLines += "seventeen", "hours";       }
            18 { $VoiceLines += "eighteen", "hours";        }
            19 { $VoiceLines += "nineteen", "hours";        }
            20 { $VoiceLines += "twenty", "hours";          }
            21 { $VoiceLines += "twenty", "one", "hours";   }
            22 { $VoiceLines += "twenty", "two", "hours";   }
            23 { $VoiceLines += "twenty", "three", "hours"; }
            24 { $VoiceLines += "twenty", "four", "hours";  }
        }
    }

    foreach ($word in $VoiceLines) {
        $WordPath = Join-Path $PSScriptRoot $ANNOUNCERS_FOLDER $Announcer "$word.wav";
        if (-not (Test-Path -LiteralPath $WordPath -PathType "Leaf")) {
            throw [System.IO.FileNotFoundException] (
                "Couldn't find file $WordPath");
        }
        
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
