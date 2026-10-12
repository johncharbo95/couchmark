' ============================================================================
' Text.brs — user-facing strings shared by several components
' Include with: <script type="text/brightscript" uri="pkg:/components/lib/Text.brs" />
' ============================================================================

' The folder layout Couchmark expects, as shown on help screens.
function UsbLayoutHelp() as String
    nl = Chr(10)
    return "Couchmark looks for these folders at the top of the USB drive:" + nl + nl + "      Movies / <Movie Name> / video files" + nl + "      Shows / <Show Name> / <Season> / episode files" + nl + "      Other / photos, videos and subfolders" + nl + nl + "You don't need all three. Folder names are shown as titles."
end function
