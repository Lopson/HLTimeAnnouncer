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
