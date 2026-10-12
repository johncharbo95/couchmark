' @include components/lib/NaturalSort.brs

sub Main()
    items = [{ name: "Episode 10.mp4" }, { name: "Episode 2.mp4" }, { name: "Episode 1.mp4" }]
    NaturalSortByName(items, false)
    assertEqual(names(items), ["Episode 1.mp4", "Episode 2.mp4", "Episode 10.mp4"], "numbers sort by value")

    items = [{ name: "b" }, { name: "A" }, { name: "c" }]
    NaturalSortByName(items, false)
    assertEqual(names(items), ["A", "b", "c"], "case-insensitive")

    eps = [{ name: "Zed S01E02.mkv" }, { name: "Alpha S01E10.mkv" }, { name: "show.1x03.mkv" }, { name: "Bonus.mkv" }, { name: "Pilot s1e1.mkv" }]
    NaturalSortByName(eps, true)
    assertEqual(names(eps), ["Pilot s1e1.mkv", "Zed S01E02.mkv", "show.1x03.mkv", "Alpha S01E10.mkv", "Bonus.mkv"], "episode codes first, then the rest")

    assertEqual(EpisodeCode("The.Office.S02.E05.mkv"), { season: 2, episode: 5 }, "S02.E05")
    assertEqual(EpisodeCode("show 3x12"), { season: 3, episode: 12 }, "3x12")
    assertEqual(EpisodeCode("Movie 1920x1080.mkv"), invalid, "a resolution is not an episode code")
    assertEqual(EpisodeCode("Pilot.mkv"), invalid, "no code")

    finishTests()
end sub

function names(items as Object) as Object
    result = []
    for each item in items
        result.Push(item.name)
    end for
    return result
end function
