' @include components/lib/Library.brs
' @include components/lib/Progress.brs
' @include components/lib/Format.brs
' @double tests/doubles/Registry.brs

sub Main()
    testContinueTarget()
    testEpisodeBadge()
    testMovies()
    testMarkMovie()
    testMarkEpisodes()
    testUpNextCountdown()
    finishTests()
end sub

sub testUpNextCountdown()
    assertEqual(UpNextCountdown(100, 1320, true), -1, "mid-episode: no card")
    assertEqual(UpNextCountdown(1309.5, 1320, true), -1, "10.5 s left: not yet")
    assertEqual(UpNextCountdown(1310, 1320, true), 10, "10 s left: card appears")
    assertEqual(UpNextCountdown(1310.8, 1320, true), 10, "9.2 s left shows 10")
    assertEqual(UpNextCountdown(1319.9, 1320, true), 1, "never shows 0")
    assertEqual(UpNextCountdown(1315, 1320, false), -1, "last episode: no card")
    assertEqual(UpNextCountdown(15, 20, true), -1, "short clip: no card")
    assertEqual(UpNextCountdown(5, 0, true), -1, "length unknown: no card")
end sub

sub testMarkMovie()
    assertEqual(MovieToggleAction(invalid), "watch", "never played: mark watched")
    assertEqual(MovieToggleAction({ part: 0, parts: 1, pos: 500, dur: 3600, watched: false }), "watch", "partly watched: mark watched")
    assertEqual(MovieToggleAction({ part: 0, parts: 1, pos: 0, dur: 0, watched: true }), "unwatch", "finished: mark unwatched")
    assertEqual(MovieToggleAction({ part: 0, parts: 1, pos: 500, dur: 3600, watched: true }), "watch", "re-watching: mark watched")
end sub

sub testMarkEpisodes()
    all = ["a", "b", "c", "d"]
    assertEqual(EpisodeIds(episodes(), 1, 2), ["b", "c"], "slice of ids")
    assertEqual(EpisodeIds(episodes(), 1, -1), ["b", "c"], "ids to the end")

    record = { lastEp: "", watched: {}, partials: [] }
    ProgressSetPartial(record, "b", 300, 1500)
    assertEqual(ToggleEpisodesWatched(record, ["b"], all), true, "partly watched episode: now watched")
    assertTrue(record.watched.DoesExist("b"), "b watched")
    assertEqual(ProgressFindPartial(record, "b"), invalid, "its resume point is cleared")
    assertEqual(record.lastEp, "b", "continue moves past it")

    assertEqual(ToggleEpisodesWatched(record, ["b"], all), false, "watched episode: now unwatched")
    assertTrue(not record.watched.DoesExist("b"), "b unwatched")
    assertEqual(record.lastEp, "", "unmarking the last-played episode resets continue")

    ' A season where only some episodes are watched: all become watched.
    record = { lastEp: "", watched: { a: true }, partials: [] }
    assertEqual(ToggleEpisodesWatched(record, ["a", "b"], all), true, "partly watched season: all watched")
    assertEqual(record.watched.Count(), 2, "both watched")
    assertEqual(ToggleEpisodesWatched(record, ["a", "b"], all), false, "fully watched season: all unwatched")
    assertEqual(record.watched.Count(), 0, "none watched")

    ' Marking an earlier season never moves "continue" backwards.
    record = { lastEp: "d", watched: {}, partials: [] }
    ToggleEpisodesWatched(record, ["a", "b"], all)
    assertEqual(record.lastEp, "d", "continue stays at the later episode")

    assertEqual(ToggleEpisodesWatched(record, [], all), false, "no episodes: nothing happens")

    ' Continue Watching tile: a watched episode being re-watched stays watched.
    record = { lastEp: "b", watched: { b: true }, partials: [] }
    ProgressSetPartial(record, "b", 300, 1500)
    assertEqual(ToggleEpisodesWatched(record, ["b"], all, true), true, "force: stays watched")
    assertEqual(ProgressFindPartial(record, "b"), invalid, "force: resume point cleared")
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
