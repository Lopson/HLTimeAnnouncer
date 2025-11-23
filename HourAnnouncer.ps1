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

    foreach ($word in $VoiceLines) {
        $WordPath = Join-Path $PSScriptRoot "vox" "$word.wav";
        if (-not (Test-Path -LiteralPath $WordPath -PathType "Leaf")) {
            throw [System.IO.FileNotFoundException] (
                "Couldn't find file $WordPath");
        }

        (New-Object System.Media.SoundPlayer $WordPath).PlaySync();
    }    
}

[int]$CurrentHour = ([datetime]::Now).Hour;
Read-HourOutLoud $CurrentHour;
