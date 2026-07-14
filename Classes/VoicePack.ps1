class VoicePack {
    [string]$FileExtension;
    [string[]]$VoiceStart;
    [string[]]$ReadingStart;
    [hashtable]$HourLines;

    VoicePack (
        [string]$FileExtension,
        [string[]]$VoiceStart,
        [string[]]$ReadingStart,
        [hashtable]$HourLines
    ) {
        $this.FileExtension = $FileExtension;
        $this.VoiceStart = $VoiceStart;
        $this.ReadingStart = $ReadingStart;
        $this.HourLines = $HourLines;
    }
}
