' @include components/lib/ScanReport.brs
' @include components/lib/MediaTypes.brs
' @include components/lib/Log.brs
' @double tests/doubles/Listing.brs

sub Main()
    names = ["S01E01.mkv", "S01E02.mp4", "S01E03.heic", "notes.nfo", ".DS_Store", "Season 2"]
    assertEqual(ListingReport("ext1:/Shows/X", names, { "Season 2": true }), "ext1:/Shows/X: 6 listed, 2 videos; skipped: S01E03.heic, notes.nfo, .DS_Store", "skipped files named, season folder ignored")
    assertEqual(ListingReport("ext1:/Shows/X/S1", ["a.mkv"], {}), "ext1:/Shows/X/S1: 1 listed, 1 videos", "nothing skipped")
    assertEqual(ListingReport("ext1:/Empty", [], {}), "ext1:/Empty: 0 listed, 0 videos", "empty folder")

    GetGlobalAA().listings = { "ext1:/Movies": ["A", "B", "C"], "ext2:/Movies": [] }
    assertEqual(ListingCounts(["ext1:/Movies", "ext2:/Movies"]), "ext1:/Movies: 3 listed, ext2:/Movies: 0 listed", "counts per folder")
    assertEqual(ListingCounts([]), "(no folders)", "no folders")
    finishTests()
end sub
