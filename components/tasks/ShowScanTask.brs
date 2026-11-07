' ============================================================================
' ShowScanTask.brs — see ScanShow in lib/Scan.brs
' ============================================================================

sub init()
    m.top.functionName = "scan"
end sub

sub scan()
    show = ScanShow(m.top.paths)
    show.art = FindArtwork(m.top.paths)
    LogInfo("ShowScanTask", show.seasons.Count().ToStr() + " seasons, " + show.items.Count().ToStr() + " episodes in " + FormatJson(m.top.paths))
    logListings()
    m.top.show = show
end sub

' For the debug log: what each show / season folder really contains, so a
' missing episode can be explained (wrong extension, junk name, ...).
sub logListings()
    seasons = ScanFolders(m.top.paths)
    seasonNames = {}
    for each season in seasons
        seasonNames[season.name] = true
    end for
    for each folder in m.top.paths
        LogInfo("ShowScanTask", ListingReport(folder, reportListDir(folder), seasonNames))
    end for
    for each season in seasons
        for each folder in season.paths
            LogInfo("ShowScanTask", ListingReport(folder, reportListDir(folder), {}))
        end for
    end for
end sub
