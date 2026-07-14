<#
.NOTES
    Author: Adam J. Kessel
    Date: May 19, 2026
    Copyright: (c) 2026 Adam J. Kessel.

    This is free and open-source software, subject to the 2-Clause BSD License.  https://opensource.org/license/bsd-2-clause
#>
#Requires -version 5.1

if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
    $wnfCode = @"
using System;
using System.Runtime.InteropServices;

public class WnfDnd
{
    [DllImport("ntdll.dll")]
    public static extern int NtQueryWnfStateData(
          ref ulong StateName,
          IntPtr TypeId,
          IntPtr ExplicitScope,
          out uint ChangeStamp,
          IntPtr Buffer,
          ref uint BufferSize);

    public static int GetState()
    {
        // The specific WNF state name for Do Not Disturb / Focus Assist
        ulong WNF_SHEL_QUIETHOURS_ACTIVE_PROFILE_CHANGED = 0xD83063EA3BF1C75UL;

        uint changeStamp = 0;
        uint bufferSize = 4;
        IntPtr buffer = Marshal.AllocHGlobal((int)bufferSize);

        try
        {
            int result = NtQueryWnfStateData(
                ref WNF_SHEL_QUIETHOURS_ACTIVE_PROFILE_CHANGED,
                IntPtr.Zero,
                IntPtr.Zero,
                out changeStamp,
                buffer,
                ref bufferSize);

            // 0 represents STATUS_SUCCESS
            if (result == 0 && bufferSize >= 4)
            {
                return Marshal.ReadInt32(buffer);
            }

            return -1; // Indicates an error or unknown state
        }
        finally
        {
            Marshal.FreeHGlobal(buffer);
        }
    }
}
"@

    # Compile the C# code into the current PowerShell session.
    Add-Type -TypeDefinition $wnfCode -Language CSharp;
};

enum DndStatus : int {
    disabled
    priorityOnly
    alarmsOnly
    undefined
}

function Get-DndStatus {
    [OutputType([DndStatus])]
    param()

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows)) {
        [int]$dndStatus = [WnfDnd]::GetState();
        switch ($dndStatus) {
            0       { return [DndStatus]::disabled;     }
            1       { return [DndStatus]::priorityOnly; }
            2       { return [DndStatus]::alarmsOnly;   }
            default { return [DndStatus]::undefined;    }
        }
    }
    
    return [DndStatus]::undefined;
}
