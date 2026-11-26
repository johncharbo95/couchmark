' ============================================================================
' NaturalSort.brs — "human" ordering of file and folder names
'
' Plain alphabetical sorting puts "Episode 10" before "Episode 2" because it
' compares character by character. We fix that by building a *sort key* for
' each name in which every run of digits is zero-padded to the same width:
'     "Episode 2"  -> "episode 0000000002"
'     "Episode 10" -> "episode 0000000010"
' Sorting the keys alphabetically then gives the natural order.
'
' Usage:
'     items = [ { name: "b 10" }, { name: "b 2" } ]
'     NaturalSortByName(items, false)
' ============================================================================

' Sorts an array of associative arrays in place by their "name" field.
' episodeAware = true also recognises S01E02 / 1x02 codes (see below).
sub NaturalSortByName(items as Object, episodeAware as Boolean)
    for each item in items
        item.sortKey = NaturalSortKey(item.name, episodeAware)
    end for
    items.SortBy("sortKey")
end sub

function NaturalSortKey(name as String, episodeAware as Boolean) as String
    key = padNumbers(LCase(name))

    if episodeAware
        ' Files with an episode code sort by season/episode first, so
        ' "Pilot S01E01.mp4" comes before "Another S01E02.mp4".
        ' "0" / "1" prefixes put coded files before un-coded ones.
        code = EpisodeCode(name)
        if code <> invalid
            return "0" + padNumbers(code.season.ToStr()) + padNumbers(code.episode.ToStr()) + key
        end if
        return "1" + key
    end if

    return key
end function

' Finds an episode code such as "S01E02", "s1e2", "S01.E02" or "1x02".
' Returns { season: 1, episode: 2 } or invalid.
function EpisodeCode(name as String) as Dynamic
    if m.episodeRegex = invalid
        ' Group 1/2 = SxxEyy form, group 3/4 = NxNN form. "i" = ignore case.
        m.episodeRegex = CreateObject("roRegex", "s(\d{1,3})[ ._-]?e(\d{1,4})|\b(\d{1,2})x(\d{1,4})\b", "i")
    end if

    match = m.episodeRegex.Match(name)
    if match.Count() = 0 then return invalid

    ' Groups that didn't take part in the match come back empty.
    if Len(match[1]) > 0
        return { season: match[1].ToInt(), episode: match[2].ToInt() }
    end if
    return { season: match[3].ToInt(), episode: match[4].ToInt() }
end function

' Replaces every run of digits with a 10-character zero-padded version.
function padNumbers(text as String) as String
    result = ""
    digits = ""
    for i = 1 to Len(text)
        c = Mid(text, i, 1)
        if c >= "0" and c <= "9"
            digits = digits + c
        else
            if digits <> "" then result = result + padDigits(digits)
            digits = ""
            result = result + c
        end if
    end for
    if digits <> "" then result = result + padDigits(digits)
    return result
end function

function padDigits(digits as String) as String
    if Len(digits) >= 10 then return digits
    return Right("0000000000" + digits, 10)
end function
