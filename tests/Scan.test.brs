' @include components/lib/Scan.brs
' @include components/lib/MediaTypes.brs
' @include components/lib/NaturalSort.brs
' @include components/lib/Progress.brs
' @include components/lib/Format.brs
' @include components/lib/Library.brs
' @double tests/doubles/Folders.brs
' @double tests/doubles/Registry.brs

sub Main()
    testFullSeason()
    testShowLayout()
    testScanFiles()
    testFilePlayerItems()
    finishTests()
end sub

' A real 24-episode season from a user's drive (only 12 showed up).
sub testFullSeason()
    names = [
        "How.I.Met.Your.Mother.S04E01.Do_I_Know_You.HDTV_XviD-FoV.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E02.PROPER.HDTV.XviD-SAiNTS.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E03.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E04.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E05.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E06.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E07.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E08.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E09.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E10.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E11.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E12.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E13.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E14.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E15.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E16.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E17.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E18.HDTV.XviD-XOR.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E19.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E20.HDTV.XviD-2HD.mkv"
        "How.I.Met.Your.Mother.S04E21.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E22.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E23.HDTV.XviD-LOL.[VTV].mkv"
        "How.I.Met.Your.Mother.S04E24.HDTV.XviD-LOL.[VTV].mkv"
    ]
    setTree({
        "ext1:/Shows/HIMYM": ["Season 4", "Season 5"]
        "ext1:/Shows/HIMYM/Season 4": names
        "ext1:/Shows/HIMYM/Season 5": []
    })
    show = ScanShow(["ext1:/Shows/HIMYM"])
    assertEqual(show.items.Count(), 24, "every episode is found")
    assertEqual(show.seasons, [{ title: "Season 4", first: 0, count: 24 }], "one season; the empty one is left out")
    assertEqual(show.items[12].code, "S04E13", "in episode order")
    assertEqual(show.items[23].label, "S04E24", "release tags dropped from the label")
end sub

sub testShowLayout()
    setTree({
        "ext1:/Shows/Lost": ["Season 10", "Season 2", "Pilot.mkv", "notes.txt", ".DS_Store", "Thumbs.db"]
        "ext1:/Shows/Lost/Season 2": ["S02E10.mp4", "S02E02.mp4", "._S02E02.mp4"]
        "ext1:/Shows/Lost/Season 10": ["S10E01.mkv"]
        "ext2:/Shows/Lost": ["Season 2"]
        "ext2:/Shows/Lost/Season 2": ["S02E01.mp4"]
    })
    show = ScanShow(["ext1:/Shows/Lost", "ext2:/Shows/Lost"])
    titles = []
    for each season in show.seasons
        titles.Push(season.title + ":" + season.count.ToStr())
    end for
    assertEqual(titles, ["Episodes:1", "Season 2:3", "Season 10:1"], "loose episodes first, seasons naturally sorted and merged across drives")
    assertEqual(show.items[1].url, "ext2:/Shows/Lost/Season 2/S02E01.mp4", "episode from the second drive in order")
    assertEqual(show.items[1].id, ProgressEpisodeId("Season 2/S02E01.mp4"), "id from the season folder + file name")
end sub

sub testScanFiles()
    setTree({
        "ext1:": ["Shows", "zz.avi", "a 10.mp4", "a 2.mp4", "cover.jpg", ".Trashes", "System Volume Information"]
        "ext1:/Shows": []
        "ext1:/System Volume Information": []
        "ext2:": ["Shows", "Movies", "a 2.mp4"]
        "ext2:/Shows": []
        "ext2:/Movies": []
    })
    found = ScanFiles(["ext1:", "ext2:"])
    rows = []
    for each entry in found
        rows.Push(entry.title + "|" + entry.kind)
    end for
    assertEqual(rows, ["Movies|folder", "Shows|folder", "a 2.mp4|video", "a 10.mp4|video", "cover.jpg|photo", "zz.avi|"], "folders first, then files; junk hidden; unsupported kept")
    assertEqual(found[1].paths, ["ext1:/Shows", "ext2:/Shows"], "same folder on two drives is merged")
    assertEqual(found[2].path, "ext1:/a 2.mp4", "a duplicate file name shows once")
end sub

sub testFilePlayerItems()
    videos = [{ name: "Show.S01E02.Diversity.Day.mkv", path: "ext1:/Shows/The Office/Season 1/Show.S01E02.Diversity.Day.mkv" }]
    show = FilePlayerItems(videos, { kind: "show", title: "The Office", prefix: "Season 1/" })
    assertEqual(show[0].id, ProgressEpisodeId("Season 1/Show.S01E02.Diversity.Day.mkv"), "show folder: same episode id as the show page")
    assertEqual(show[0].code, "S01E02", "show folder: episode code")

    parts = FilePlayerItems([{ name: "a.mp4", path: "x/a.mp4" }, { name: "b.mp4", path: "x/b.mp4" }], { kind: "movie", title: "X", prefix: "" })
    assertEqual(parts[1].label, "Part 2 of 2", "movie folder: parts")

    plain = FilePlayerItems([{ name: "Holiday.2024.mp4", path: "ext1:/Holiday.2024.mp4" }], { kind: "file", title: "Files", prefix: "" })
    assertEqual(plain, [{ url: "ext1:/Holiday.2024.mp4", label: "Holiday.2024", id: "", code: "" }], "elsewhere: file name, no id")
end sub
