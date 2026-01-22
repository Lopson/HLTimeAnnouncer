# Half-Life 1 VOX Voice Hour Announcer

I recently found this feature on macOS where you can have it announce the hours, and I looked for it on Windows but couldn't find it. Not wanting to install yet another program to make it happen, I decided to create my own little thing.

## Getting the audio files

I can't exactly redistribute the `.wav` files that this script relies on, but for now you can get them from [this other repository](https://github.com/sourcesounds/hl1). The list of files needed is:

- **Vox:** "_period", "doop", "eight", "eighteen", "fifteen", "five", "four", "fourteen", "hour", "hours", "is", "it", "nine", "nineteen", "now", "one", "seven", "seventeen", "six", "sixteen", "ten", "thirteen", "three", "twelve", "twenty", "two", "zero".
- **FVox:** "_period", "am", "bell", "eight", "eighteen", "eleven", "fifteen", "five", "four", "fourteen", "hours", "nine", "nineteen", "one", "pm", "seven", "seventeen", "six", "sixteen", "ten", "thirteen", "three", "time_is_now", "twelve", "twenty", "two".

Be sure to place all of the files inside a folder named `vox` and another named `fvox`. The folders should reside at the root of this repository. They must be `.wav` files, otherwise `System.Media.SoundPlayer` won't be able to play them back as far as I can tell.

## Setting it up

Just get a scheduled task running this thing every hour. Make sure the action is the following:

```cmd
wscript.exe "{PATH_TO_SCRIPT}\run_hidden.vbs"
```

Be sure to change the path to the VBS script accordingly. Yes, we still need this type of hack to make sure that a scheduled task's window remains completely hidden, it's insane, I know. 😑

There's a couple of variables that are relevant to this script's configuration:

- `$ANNOUNCER_TO_USE`: Defines the default announcer voice. Can be set to `vox` or `fvox`.
- `$FOLLOW_THEME`: On Windows 11, the announcer voice can change depending on the current system theme. If this is set to `$true`, then it'll use `vox` for light theme and `fvox` for dark theme.
- `$FORCE_RUN`: If set to `$true`, this will skip the check to see if the time the script is running at is minute 0 of a given hour.
