' @include components/lib/Library.brs
' @include components/lib/Progress.brs
' @include components/lib/Format.brs
' @double tests/doubles/Registry.brs

sub Main()
    testContinueTarget()
    testEpisodeBadge()
    testMovies()
    finishTests()
end sub

function episodes() as Object
    return [
        { id: "a", code: "S01E01", label: "S01E01  ·  Pilot", url: "a.mkv" }
        { id: "b", code: "S01E02", label: "S01E02  ·  Two", url: "b.mkv" }
        { id: "c", code: "", label: "Special", url: "c.mkv" }
    ]
end function

sub testContinueTarget()
    list = episodes()
    record = { lastEp: "", watched: {}, partials: [] }
    assertEqual(ContinueTarget(record, list), { text: "Start watching S01E01", index: 0, pos: 0 }, "never watched")

    record.lastEp = "a"
    record.watched["a"] = true
    assertEqual(ContinueTarget(record, list).text, "Next: S01E02", "finished last episode: next one")

    record.lastEp = "b"
    ProgressSetPartial(record, "b", 845, 1500)
    assertEqual(ContinueTarget(record, list), { text: "Continue S01E02 at 14:05", index: 1, pos: 845 }, "resume point")

    ProgressRemovePartial(record, "b")
    assertEqual(ContinueTarget(record, list).text, "Continue S01E02", "stopped within 15 s")

    record.lastEp = "c"
    record.watched["b"] = true
    record.watched["c"] = true
    assertEqual(ContinueTarget(record, list), invalid, "everything watched")

    record = { lastEp: "gone", watched: { a: true }, partials: [] }
    assertEqual(ContinueTarget(record, list).text, "Next: S01E02", "last episode deleted: first unwatched")

    assertEqual(ContinueTarget(record, []), invalid, "no episodes")
end sub

sub testEpisodeBadge()
    record = { lastEp: "", watched: { a: true }, partials: [] }
    ProgressSetPartial(record, "b", 750, 1500)
    assertEqual(EpisodeBadge(record, "a").badge, "watched", "watched")
    assertEqual(EpisodeBadge(record, "b"), { badge: "partial", progress: 0.5 }, "partial")
    assertEqual(EpisodeBadge(record, "c").badge, "", "unwatched")
    ProgressSetPartial(record, "a", 100, 1000)
    assertEqual(EpisodeBadge(record, "a").badge, "partial", "re-watching shows progress, not the check")
end sub

sub testMovies()
    parts = [{ path: "ext1:/Movies/X/1.mkv" }, { path: "ext1:/Movies/X/2.mkv" }]
    items = MoviePlayerItems(parts)
    assertEqual(items[1], { url: "ext1:/Movies/X/2.mkv", label: "Part 2 of 2", id: "" }, "multi-part labels")
    assertEqual(MoviePlayerItems([parts[0]])[0].label, "", "single file: no label")

    record = { part: 1, parts: 2, pos: 900, dur: 3600, watched: false }
    assertTrue(MovieInProgress(record), "in progress")
    assertNear(MovieFraction(record), 0.625, 0.0001, "part 2 of 2 at 25% is 62.5% overall")
    assertEqual(MovieResumeText(record), "Part 2 of 2  ·  45 min left", "resume text")
    assertEqual(MovieBadge(invalid).badge, "", "never played")
    assertEqual(MovieBadge({ part: 0, parts: 1, pos: 0, dur: 0, watched: true }).badge, "watched", "finished")
end sub
