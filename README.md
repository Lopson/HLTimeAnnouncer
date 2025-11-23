# Half-Life 1 VOX Voice Announcer

I recently found this feature on macOS where you can have it announce the hours, and I looked for it on Windows but couldn't find it. Not wanting to install yet another program to make it happen, I decided to create my own little thing.

## Getting the audio files

I can't exactly redistribute the `.wav` files that this script relies on, but for now you can get them from [this other repository](https://github.com/sourcesounds/hl1). The list of files needed is: "_period", "doop", "eight", "eighteen", "fifteen", "five", "four", "fourteen", "hour", "hours", "is", "it", "nine", "nineteen", "now", "one", "seven", "seventeen", "six", "sixteen", "ten", "thirteen", "three", "twelve", "twenty", "two", "zero".

## Setting it up

Just get a scheduled task running this thing every hour. Make sure the action is the following:

```cmd
wscript.exe "{PATH_TO_SCRIPT}\run_hidden.vbs"
```

Be sure to change the path to the PowerShell interpreter accordingly.
