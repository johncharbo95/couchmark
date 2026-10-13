' ============================================================================
' BuildInfo.brs — which commit is running (development builds only)
'
' When you launch from VS Code (F5), tools/build-info.js writes
' build-info.json (commit, message, branch, uncommitted changes, time) and
' the launch config includes it in the app. Release zips don't contain the
' file, so nothing is shown there.
' ============================================================================

' The build info, or invalid when this isn't a development build.
function ReadBuildInfo() as Dynamic
    text = ReadAsciiFile("pkg:/build-info.json")
    if text = "" then return invalid
    return ParseJson(text)
end function

' One line for the screen, e.g.
'   "DEV  9ad7f63  Fix the thing  ·  dev  ·  built 2026-10-12 11:42"
' or "" when info is missing or incomplete.
function BuildInfoText(info as Dynamic) as String
    if Type(info) <> "roAssociativeArray" then return ""
    if not info.DoesExist("commit") or not info.DoesExist("message") then return ""

    text = "DEV  " + info.commit + "  " + info.message
    if info.DoesExist("dirty") and info.dirty = true then text = text + "  (+ uncommitted changes)"
    if info.DoesExist("branch") and info.branch <> "" then text = text + "  ·  " + info.branch
    if info.DoesExist("builtAt") and info.builtAt <> "" then text = text + "  ·  built " + info.builtAt
    return text
end function
