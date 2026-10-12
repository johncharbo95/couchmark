' @include components/lib/Progress.brs
' @double tests/doubles/Registry.brs

sub Main()
    testMovieRoundTrip()
    testShowRoundTrip()
    testPartials()
    testRecentList()
    testPruning()
    testClearAll()
    finishTests()
end sub

sub testMovieRoundTrip()
    resetRegistry()
    assertEqual(ProgressGetMovie("The Matrix"), invalid, "unknown movie")
    ProgressSaveMovie("The Matrix", { part: 1, parts: 2, pos: 845, dur: 3600, watched: false })
    record = ProgressGetMovie("the matrix")
    assertEqual(record.part, 1, "part (lookup ignores case)")
    assertEqual(record.parts, 2, "parts")
    assertEqual(record.pos, 845, "position")
    assertEqual(record.dur, 3600, "duration")
    assertEqual(record.watched, false, "watched")
    assertEqual(record.title, "The Matrix", "title is stored")
end sub

sub testShowRoundTrip()
    resetRegistry()
    record = ProgressGetShow("Weird | Show")
    assertEqual(record.lastEp, "", "new show: no last episode")
    record.lastEp = "aaa111"
    record.watched["bbb222"] = true
    ProgressSetPartial(record, "aaa111", 600, 1500)
    ProgressSaveShow("Weird | Show", record)

    loaded = ProgressGetShow("Weird | Show")
    assertEqual(loaded.lastEp, "aaa111", "last episode")
    assertTrue(loaded.watched.DoesExist("bbb222"), "watched episode")
    assertEqual(ProgressFindPartial(loaded, "aaa111"), { id: "aaa111", pos: 600, dur: 1500 }, "resume point")
    assertEqual(loaded.title, "Weird | Show", "title containing | survives")
end sub

sub testPartials()
    record = { lastEp: "", watched: {}, partials: [] }
    for i = 1 to 12
        ProgressSetPartial(record, "ep" + i.ToStr(), i * 60, 1500)
    end for
    assertEqual(record.partials.Count(), 10, "at most 10 resume points")
    assertEqual(record.partials[0].id, "ep12", "most recent first")
    assertEqual(ProgressFindPartial(record, "ep1"), invalid, "oldest dropped")
    ProgressSetPartial(record, "ep5", 999, 1500)
    assertEqual(record.partials[0], { id: "ep5", pos: 999, dur: 1500 }, "updating moves to the front")
    ProgressRemovePartial(record, "ep5")
    assertEqual(ProgressFindPartial(record, "ep5"), invalid, "removed")
end sub

sub testRecentList()
    resetRegistry()
    ProgressSaveMovie("Old Movie", { part: 0, parts: 1, pos: 100, dur: 200, watched: false })
    ProgressSaveShow("A Show", { lastEp: "x", watched: {}, partials: [], title: "" })
    ProgressSaveMovie("New Movie", { part: 0, parts: 1, pos: 100, dur: 200, watched: false })
    ' A record from version 0.1 (no title) is skipped.
    progressSection().Write("m00000000", "5|0|1|100|200|0")

    titles = []
    for each entry in ProgressListRecent()
        titles.Push(entry.kind + ":" + entry.record.title)
    end for
    assertEqual(titles, ["movie:New Movie", "show:A Show", "movie:Old Movie"], "newest first, untitled skipped")
end sub

sub testPruning()
    resetRegistry()
    ' About 100 bytes per entry against a 13000-byte budget: old ones must go.
    longName = "A Movie With A Rather Long Folder Name To Fill The Registry Quickly"
    for i = 1 to 200
        ProgressSaveMovie(longName + " " + i.ToStr(), { part: 0, parts: 1, pos: 100, dur: 200, watched: false })
    end for
    total = 0
    registry = GetGlobalAA().registry
    for each key in registry
        total = total + Len(key) + Len(registry[key])
    end for
    assertTrue(total <= progressMaxBytes(), "registry stays within the budget")
    assertTrue(ProgressGetMovie(longName + " 200") <> invalid, "newest entry kept")
    assertEqual(ProgressGetMovie(longName + " 1"), invalid, "oldest entry pruned")
end sub

sub testClearAll()
    ProgressSaveMovie("X", { part: 0, parts: 1, pos: 100, dur: 200, watched: false })
    ProgressClearAll()
    assertEqual(GetGlobalAA().registry.Count(), 0, "clear watch history empties the section")
end sub
