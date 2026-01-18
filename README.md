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

Be sure to change the path to the VBS script accordingly. Yes, we still need this type of hack to make sure that a scheduled task's window remains completely hidden, it's insane, I know. 😑 Also, be sure to change the variable `$ANNOUNCER_TO_USE` in the PS1 file so as to select the announcer you want to use.
