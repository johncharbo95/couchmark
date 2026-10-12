' ============================================================================
' Library.brs — movie and show helpers shared by screens and tasks
' Needs: Progress.brs, Format.brs
' ============================================================================

' ----------------------------------------------------------------------------
' Movies
' ----------------------------------------------------------------------------

' PlayerScreen items for a movie's parts (from ScanVideos):
'   [ { url, label: "Part 2 of 3" (or "" for a single file), id: "" } ]
function MoviePlayerItems(parts as Object) as Object
    items = []
    for i = 0 to parts.Count() - 1
        label = ""
        if parts.Count() > 1 then label = "Part " + (i + 1).ToStr() + " of " + parts.Count().ToStr()
        items.Push({ url: parts[i].path, label: label, id: "" })
    end for
    return items
end function

' True when a movie record has a resume point.
function MovieInProgress(record as Dynamic) as Boolean
    if record = invalid then return false
    return record.pos > 0 or record.part > 0
end function

' How far through the whole movie (0.0 – 1.0), counting finished parts.
function MovieFraction(record as Object) as Float
    partFraction = 0.0
    if record.dur > 0 then partFraction = record.pos / record.dur
    parts = record.parts
    if parts < 1 then parts = 1
    return (record.part + partFraction) / parts
end function

' What ✱ (mark watched / unwatched) does to a movie: "unwatch" when it's
' finished (✓), otherwise "watch" (also when it's partly watched).
function MovieToggleAction(record as Dynamic) as String
    if record <> invalid and record.watched and not MovieInProgress(record) then return "unwatch"
    return "watch"
end function

' Badge for a movie tile/row: { badge: "" | "watched" | "partial", progress }
function MovieBadge(record as Dynamic) as Object
    if MovieInProgress(record) then return { badge: "partial", progress: MovieFraction(record) }
    if record <> invalid and record.watched then return { badge: "watched", progress: 0.0 }
    return { badge: "", progress: 0.0 }
end function

' "Part 2 of 3 · 45 min left", "45 min left" or "Resume at 1:02:14"
function MovieResumeText(record as Object) as String
    text = "Resume at " + FormatTime(record.pos)
    if record.dur > record.pos then text = FormatRemaining(record.dur - record.pos) + " left"
    if record.parts > 1 then text = "Part " + (record.part + 1).ToStr() + " of " + record.parts.ToStr() + "  ·  " + text
    return text
end function

' ----------------------------------------------------------------------------
' Shows
' ----------------------------------------------------------------------------

' Short name for an episode: "S02E05" when the file has a code, else its title.
function EpisodeShortLabel(item as Object) as String
    if item.code <> "" then return item.code
    return item.label
end function

' ✱ on episodes (one episode, or every episode of a season):
'   - if they are all watched already: mark them unwatched
'   - otherwise: mark them all watched
' Resume points of those episodes are cleared either way. "Continue" moves
' forward past episodes marked watched (never backwards), and unmarking the
' last-played episode resets it.
' ids: the episodes to change, in watching order. allIds: every episode of
' the show in watching order. forceWatch: always mark watched (Continue
' Watching tile: "I've seen this"). Changes record in place (save it
' afterwards); returns true if the episodes are now watched.
function ToggleEpisodesWatched(record as Object, ids as Object, allIds as Object, forceWatch = false as Boolean) as Boolean
    if ids.Count() = 0 then return false

    allWatched = true
    for each id in ids
        if not record.watched.DoesExist(id) then allWatched = false
    end for
    watch = forceWatch or not allWatched

    for each id in ids
        ProgressRemovePartial(record, id)
        if watch
            record.watched[id] = true
        else
            record.watched.Delete(id)
            if record.lastEp = id then record.lastEp = ""
        end if
    end for
    if watch and indexOf(allIds, ids[ids.Count() - 1]) > indexOf(allIds, record.lastEp)
        record.lastEp = ids[ids.Count() - 1]
    end if
    return watch
end function

' The ids of items[first] .. items[first + count - 1] (count -1 = to the end).
function EpisodeIds(items as Object, first as Integer, count as Integer) as Object
    if count < 0 then count = items.Count() - first
    ids = []
    for i = first to first + count - 1
        ids.Push(items[i].id)
    end for
    return ids
end function

' Position of value in list, or -1.
function indexOf(list as Object, value as String) as Integer
    for i = 0 to list.Count() - 1
        if list[i] = value then return i
    end for
    return -1
end function

' Badge for one episode: { badge: "" | "watched" | "partial", progress }.
' A resume point wins over ✓ (you're re-watching it).
function EpisodeBadge(record as Object, id as String) as Object
    partial = ProgressFindPartial(record, id)
    if partial <> invalid
        fraction = 0.0
        if partial.dur > 0 then fraction = partial.pos / partial.dur
        return { badge: "partial", progress: fraction }
    end if
    if record.watched.DoesExist(id) then return { badge: "watched", progress: 0.0 }
    return { badge: "", progress: 0.0 }
end function

' Where "Continue" should take you, or invalid when there's nothing to offer
' (show finished). Returns { text, index, pos }.
function ContinueTarget(record as Object, items as Object) as Dynamic
    if items.Count() = 0 then return invalid

    index = -1
    if record.lastEp <> ""
        for i = 0 to items.Count() - 1
            if items[i].id = record.lastEp
                index = i
                exit for
            end if
        end for
    end if

    ' Never played, or the last episode is gone from the drive:
    ' start at the first episode not yet watched.
    if index < 0
        for i = 0 to items.Count() - 1
            if not record.watched.DoesExist(items[i].id)
                verb = "Start watching "
                if record.watched.Count() > 0 then verb = "Next: "
                return targetAt(record, items, i, verb)
            end if
        end for
        return invalid
    end if

    ' Last episode was finished: offer the one after it.
    if record.watched.DoesExist(record.lastEp) and ProgressFindPartial(record, record.lastEp) = invalid
        if index + 1 >= items.Count() then return invalid
        return targetAt(record, items, index + 1, "Next: ")
    end if

    return targetAt(record, items, index, "Continue ")
end function

function targetAt(record as Object, items as Object, index as Integer, verb as String) as Object
    item = items[index]
    resumeAt = 0
    text = verb + EpisodeShortLabel(item)

    partial = ProgressFindPartial(record, item.id)
    if partial <> invalid
        resumeAt = partial.pos
        text = "Continue " + EpisodeShortLabel(item) + " at " + FormatTime(resumeAt)
    end if
    return { text: text, index: index, pos: resumeAt }
end function
