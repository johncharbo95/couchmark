' ============================================================================
' ShowScanTask.brs — see ScanShow in lib/Scan.brs
' ============================================================================

sub init()
    m.top.functionName = "scan"
end sub

sub scan()
    show = ScanShow(m.top.paths)
    show.art = FindArtwork(m.top.paths)
    print "[ShowScanTask] "; show.seasons.Count(); " seasons, "; show.items.Count(); " episodes in "; FormatJson(m.top.paths)
    m.top.show = show
end sub
