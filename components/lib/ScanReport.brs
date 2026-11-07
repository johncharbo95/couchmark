' ============================================================================
' ScanReport.brs — text for the debug log about what a scan saw on the drive
'
' When an episode or movie is "missing", the log should show what the
' folder really contained and why files were left out. Kept separate from
' Scan.brs so scanning itself stays unchanged.
' Needs: MediaTypes.brs, Log.brs (LogNameList)
' ============================================================================

' One folder's raw listing compared with the videos kept, e.g.
'   "ext1:/Shows/X/Season 1: 14 listed, 12 videos; skipped: a.nfo, b.srt"
' `ignore` holds names not worth reporting (e.g. season folders).
function ListingReport(folder as String, names as Object, ignore as Object) as String
    videos = 0
    skipped = []
    for each name in names
        if MediaKind(name) = "video"
            videos = videos + 1
        else if not ignore.DoesExist(name)
            skipped.Push(name)
        end if
    end for
    text = folder + ": " + names.Count().ToStr() + " listed, " + videos.ToStr() + " videos"
    if skipped.Count() > 0 then text = text + "; skipped: " + LogNameList(skipped, 30)
    return text
end function

' How many entries each folder's raw listing has, e.g.
'   "ext1:/Movies: 12 listed, ext2:/Movies: 3 listed"
function ListingCounts(folders as Object) as String
    parts = []
    for each folder in folders
        parts.Push(folder + ": " + reportListDir(folder).Count().ToStr() + " listed")
    end for
    if parts.Count() = 0 then return "(no folders)"
    return parts.Join(", ")
end function

' Device seam (tests/doubles/Listing.brs): a folder's raw listing.
function reportListDir(folder as String) as Object
    names = []
    for each name in CreateObject("roFileSystem").GetDirectoryListing(folder + "/")
        names.Push(name)
    end for
    return names
end function
