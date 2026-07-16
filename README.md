# Half-Life 1 VOX Voice Hour Announcer

I recently found this feature on macOS where you can have it announce the hours, and I looked for it on Windows but couldn't find it. Not wanting to install yet another program to make it happen, I decided to create my own little thing.

## Getting the audio files

I can't exactly redistribute the `.wav` files that this script relies on, but for now you can get them from [this other repository](https://github.com/sourcesounds/hl1). The list of files needed is:

- **Vox:** "_period", "doop", "eight", "eighteen", "fifteen", "five", "four", "fourteen", "hour", "hours", "is", "it", "nine", "nineteen", "now", "one", "seven", "seventeen", "six", "sixteen", "ten", "thirteen", "three", "twelve", "twenty", "two", "zero".
- **FVox:** "_period", "am", "bell", "eight", "eighteen", "eleven", "fifteen", "five", "four", "fourteen", "hours", "nine", "nineteen", "one", "pm", "seven", "seventeen", "six", "sixteen", "ten", "thirteen", "three", "time_is_now", "twelve", "twenty", "two".

Be sure to place all of the files inside a folder named `vox` and another named `fvox`. The folders should reside at the root of this repository. On Windows they must be `.wav` files, otherwise `System.Media.SoundPlayer` won't be able to play them back as far as I can tell.

Note that you don't have to rely on Half-Life 1 voices! You can create your own custom voice pack with whatever audio files you want. Simply make sure to create a `Definition.ps1` file in the folder containing the audio files that fills out this template:

```powershell
$Global:VoicePacks["vox"] = [VoicePack]::new(
    "FILE_EXTENSION_WITHOUT_DOT",
    @(LIST_OF_STRINGS_FOR_CHIME_FILENAMES),
    @(LIST_OF_STRINGS_FOR_READING_START_FILENAMES),
    @{
        0  = @(LIST_OF_STRINGS_FOR_HOUR_FILENAMES)
        1  = @(LIST_OF_STRINGS_FOR_HOUR_FILENAMES)
        ...
        23 = @(LIST_OF_STRINGS_FOR_HOUR_FILENAMES)
        24 = @(LIST_OF_STRINGS_FOR_HOUR_FILENAMES)
    }
);
```

## Setting it up

Just get a scheduled task running this thing every hour. An example can be found in this repository. Make sure the action is the following:

```cmd
wscript.exe "{PATH_TO_SCRIPT}\run_hidden.vbs"
```

Be sure to change the path to the VBS script accordingly. Yes, we still need this type of hack to make sure that a scheduled task's window remains completely hidden, it's insane, I know. 😑

There's a couple of variables that are relevant to this script's configuration:

- `$ANNOUNCERS_FOLDER`: The name of the root's subfolder containing voice packs.
- `$ANNOUNCER_TO_USE`: Defines the default announcer voice. Can be set to `vox` or `fvox`.
- `$FOLLOW_THEME`: On Windows 11, the announcer voice can change depending on the current system theme. If this is set to `$true`, then it'll use `vox` for light theme and `fvox` for dark theme.
- `$FORCE_RUN`: If set to `$true`, this will skip the check to see if the time the script is running at is minute 0 of a given hour.
- `$READ_OUT_LOUD`: If set to `$true`, the script will play the top of the hour chime and read out the hour. If set to `$false`, it'll only play the chime.
- `$READ_DURING_MEDIA_PLAYBACK`: Only relevant if `$READ_OUT_LOUD` is set to `$true`. If this one is set to `$true`, the script will read out the hour if media is being played back on the machine; setting this to `$false` does the opposite.
- `$READ_DURING_VIDEOGAMES`: Only relevant if `$READ_OUT_LOUD` is set to `$true`. If this one is set to `$true`, the script will read out the hour if a videogame is being played; setting this to `$false` does the opposite.
- `$READ_DURING_DND`: Only relevant if `$READ_OUT_LOUD` is set to `$true`. If this one is set to `$true`, the script will read out the hour if Do Not Disturb is enabled; setting this to `$false` does the opposite.
