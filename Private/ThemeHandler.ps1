enum SystemThemes : int {
    light
    dark
    undefined
}

# Function to check if we're in light or dark mode. We're using this to figure
# out if the sun has set, which we can then use to kick in a nighttime-specific
# voice bank.
function Get-CurrentSystemTheme {
    [OutputType([SystemThemes])]

    $result = [SystemThemes]::undefined;
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        if ((Get-ItemProperty -Path `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                -Name "SystemUsesLightTheme").SystemUsesLightTheme -eq 0) {
            $result = [SystemThemes]::dark;
        }
        else {
            $result = [SystemThemes]::light;
        }
    }

    return $result;
}
