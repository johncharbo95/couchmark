' @include components/lib/ShowNav.brs

sub Main()
    ' Keys the lists didn't use.
    assertEqual(ShowNextArea("continue", "down", true), "episodes", "Down from Continue")
    assertEqual(ShowNextArea("seasons", "right", true), "episodes", "Right from seasons")
    assertEqual(ShowNextArea("episodes", "left", true), "seasons", "Left from episodes")
    assertEqual(ShowNextArea("seasons", "up", true), "continue", "Up from top season")
    assertEqual(ShowNextArea("episodes", "up", true), "continue", "Up from top episode")
    assertEqual(ShowNextArea("episodes", "up", false), "", "Up without a Continue button")
    assertEqual(ShowNextArea("seasons", "left", true), "", "Left from seasons does nothing")
    assertEqual(ShowNextArea("episodes", "right", true), "", "Right from episodes does nothing")
    assertEqual(ShowNextArea("continue", "up", true), "", "Up from Continue does nothing")

    seasons = [{ first: 0, count: 10 }, { first: 10, count: 8 }, { first: 18, count: 1 }]
    assertEqual(SeasonOfItem(seasons, 0), 0, "first episode")
    assertEqual(SeasonOfItem(seasons, 9), 0, "last of season 1")
    assertEqual(SeasonOfItem(seasons, 10), 1, "first of season 2")
    assertEqual(SeasonOfItem(seasons, 18), 2, "one-episode season")
    assertEqual(SeasonOfItem(seasons, 99), 0, "unknown index: first season")

    s2 = seasons[1]
    none = [false, false, false, false, false, false, false, false]
    assertEqual(SeasonEntryRow(s2, 13, none, -1), 3, "Continue episode in this season")
    assertEqual(SeasonEntryRow(s2, 2, none, -1), 0, "Continue elsewhere, nothing watched: first")
    some = [true, true, true, false, false, false, false, false]
    assertEqual(SeasonEntryRow(s2, 2, some, -1), 3, "first unwatched")
    assertEqual(SeasonEntryRow(s2, -1, some, -1), 3, "no Continue: first unwatched")
    all = [true, true, true, true, true, true, true, true]
    assertEqual(SeasonEntryRow(s2, -1, all, -1), 0, "all watched: first episode")
    assertEqual(SeasonEntryRow(s2, 13, some, 6), 6, "re-opening the selected season keeps the row")
    assertEqual(SeasonEntryRow(s2, 13, some, 20), 3, "stale row is ignored")
    assertEqual(SeasonEntryRow({ first: 0, count: 0 }, -1, [], -1), 0, "empty season")

    finishTests()
end sub
