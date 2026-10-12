' ============================================================================
' Progress.brs — remembers playback positions in the Roku registry
'
' The registry is Roku's small persistent key/value store (~16 KB per app,
' shared by all sections). To stay well under that, each movie and each show
' gets ONE short entry in the "progress" section.
'
' MOVIES
'   key:   "m" + first 8 hex chars of MD5(lower-case movie folder name)
'   value: "lastUsed|part|parts|pos|dur|watched|title"
'           lastUsed  seconds since 1970, used to forget old entries first
'           part      0-based index of the file being played (multi-part movies)
'           parts     how many files the movie has
'           pos       resume position in seconds within that part (0 = none)
'           dur       duration of that part in seconds (for the progress bar)
'           watched   1 once the movie has been finished (past 90%)
'           title     the folder name, so the home screen's Continue Watching
'                     row can be built without scanning the whole drive
'
' Example: "1760270000|0|1|3734|7200|0|The Matrix"  = resume at 1:02:14.
'
' SHOWS
'   key:   "s" + first 8 hex chars of MD5(lower-case show folder name)
'   value: "lastUsed|lastEp|watched|partials|title"
'           lastEp    id of the episode played most recently
'           watched   comma-separated ids of watched episodes
'           partials  comma-separated "id:pos:dur" of partly-watched episodes,
'                     most recent first, at most 10
'           title     the show folder name
'   An episode id is 6 hex chars of MD5("season folder/file name"), see
'   ProgressEpisodeId(). Renaming other files doesn't disturb existing ids.
' Example: "1760270000|0b12ef|77ac10,0b12ef|c4d2e1:612:2580|The Office"
'
' (Records written by version 0.1 have no title; they still work, they just
'  don't appear in Continue Watching until the title is played again.)
'
' When the total size passes progressMaxBytes(), least-recently-used entries
' are deleted.
' ============================================================================

function progressMaxBytes() as Integer
    return 13000
end function

function progressSection() as Object
    return CreateObject("roRegistrySection", "progress")
end function

' Short, stable registry key for a title. kind: "m" = movie, "s" = show.
function ProgressKey(kind as String, name as String) as String
    return kind + Left(md5Hex(LCase(name)), 8)
end function

' Id of an episode, from its path relative to the show folder,
' e.g. "Season 2/S02E05 The Episode.mkv".
function ProgressEpisodeId(relativePath as String) as String
    return Left(md5Hex(LCase(relativePath)), 6)
end function

' Returns { part, parts, pos, dur, watched, title, lastUsed } or invalid if
' never played.
function ProgressGetMovie(name as String) as Dynamic
    section = progressSection()
    key = ProgressKey("m", name)
    if not section.Exists(key) then return invalid
    return parseMovie(section.Read(key))
end function

function parseMovie(value as String) as Dynamic
    fields = value.Split("|")
    if fields.Count() < 6 then return invalid
    return {
        lastUsed: fields[0].ToInt()
        part: fields[1].ToInt()
        parts: fields[2].ToInt()
        pos: fields[3].ToInt()
        dur: fields[4].ToInt()
        watched: fields[5] = "1"
        title: joinFrom(fields, 6)
    }
end function

' record = { part, parts, pos, dur, watched } (same shape as ProgressGetMovie)
sub ProgressSaveMovie(name as String, record as Object)
    watched = "0"
    if record.watched then watched = "1"

    value = nowSeconds().ToStr() + "|" + record.part.ToStr() + "|" + record.parts.ToStr() + "|" + record.pos.ToStr() + "|" + record.dur.ToStr() + "|" + watched + "|" + name
    progressWrite(ProgressKey("m", name), value)
end sub

' ----------------------------------------------------------------------------
' Shows
' ----------------------------------------------------------------------------

' Always returns a record (empty if the show was never played):
'   { lastEp: "id", watched: { id: true, ... }, partials: [ { id, pos, dur }, ... ],
'     title, lastUsed }
function ProgressGetShow(name as String) as Object
    section = progressSection()
    key = ProgressKey("s", name)
    if not section.Exists(key) then return { lastEp: "", watched: {}, partials: [], title: name, lastUsed: 0 }
    return parseShow(section.Read(key))
end function

function parseShow(value as String) as Object
    record = { lastEp: "", watched: {}, partials: [], title: "", lastUsed: 0 }
    fields = value.Split("|")
    if fields.Count() < 4 then return record

    record.lastUsed = fields[0].ToInt()
    record.title = joinFrom(fields, 4)
    record.lastEp = fields[1]
    for each id in fields[2].Split(",")
        if id <> "" then record.watched[id] = true
    end for
    for each entry in fields[3].Split(",")
        values = entry.Split(":")
        if values.Count() = 3
            record.partials.Push({ id: values[0], pos: values[1].ToInt(), dur: values[2].ToInt() })
        end if
    end for
    return record
end function

sub ProgressSaveShow(name as String, record as Object)
    watchedIds = []
    for each id in record.watched
        watchedIds.Push(id)
    end for

    partialTexts = []
    for each partial in record.partials
        partialTexts.Push(partial.id + ":" + partial.pos.ToStr() + ":" + partial.dur.ToStr())
    end for

    value = nowSeconds().ToStr() + "|" + record.lastEp + "|" + watchedIds.Join(",") + "|" + partialTexts.Join(",") + "|" + name
    progressWrite(ProgressKey("s", name), value)
end sub

' Returns { id, pos, dur } for a partly-watched episode, or invalid.
function ProgressFindPartial(record as Object, id as String) as Dynamic
    for each partial in record.partials
        if partial.id = id then return partial
    end for
    return invalid
end function

' Records a resume point (most recent first, keeping at most 10).
sub ProgressSetPartial(record as Object, id as String, position as Integer, duration as Integer)
    ProgressRemovePartial(record, id)
    record.partials.Unshift({ id: id, pos: position, dur: duration })
    while record.partials.Count() > 10
        record.partials.Pop()
    end while
end sub

sub ProgressRemovePartial(record as Object, id as String)
    for i = record.partials.Count() - 1 to 0 step -1
        if record.partials[i].id = id then record.partials.Delete(i)
    end for
end sub

' ----------------------------------------------------------------------------
' Continue Watching
' ----------------------------------------------------------------------------

' Every saved movie and show that has a title, most recently played first:
'   [ { kind: "movie" | "show", record: <ProgressGetMovie/Show result> }, ... ]
function ProgressListRecent() as Object
    result = []
    order = []
    section = progressSection()
    for each key in section.GetKeyList()
        value = section.Read(key)
        record = invalid
        kind = ""
        if Left(key, 1) = "m"
            record = parseMovie(value)
            kind = "movie"
        else if Left(key, 1) = "s"
            record = parseShow(value)
            kind = "show"
        end if
        if record <> invalid and record.title <> ""
            ' Zero-padded text sorts the same as the number would.
            sortKey = record.lastUsed.ToStr()
            while Len(sortKey) < 12
                sortKey = "0" + sortKey
            end while
            ' Sort a flat list of keys and look the records up afterwards
            ' (keeps the sort simple: no nested objects in sorted items).
            order.Push({ key: sortKey, index: result.Count() })
            result.Push({ kind: kind, record: record })
        end if
    end for
    order.SortBy("key")

    newestFirst = []
    for i = order.Count() - 1 to 0 step -1
        newestFirst.Push(result[order[i].index])
    end for
    return newestFirst
end function

' ----------------------------------------------------------------------------
' Housekeeping
' ----------------------------------------------------------------------------

' Deletes all saved progress (Settings > Clear watch history).
sub ProgressClearAll()
    section = progressSection()
    for each key in section.GetKeyList()
        section.Delete(key)
    end for
    section.Flush()
end sub

' ----------------------------------------------------------------------------
' Internals
' ----------------------------------------------------------------------------

sub progressWrite(key as String, value as String)
    section = progressSection()
    section.Write(key, value)
    progressPrune(section)
    section.Flush()
end sub

' Deletes the oldest entries until the section fits in the budget.
sub progressPrune(section as Object)
    entries = []
    total = 0
    for each key in section.GetKeyList()
        value = section.Read(key)
        total = total + Len(key) + Len(value)
        entries.Push({ key: key, size: Len(key) + Len(value), lastUsed: value.Split("|")[0].ToInt() })
    end for
    if total <= progressMaxBytes() then return

    entries.SortBy("lastUsed")
    ' Never delete the newest entry (the one just written).
    for i = 0 to entries.Count() - 2
        if total <= progressMaxBytes() then exit for
        print "[Progress] pruning old entry "; entries[i].key
        section.Delete(entries[i].key)
        total = total - entries[i].size
    end for
end sub

' fields[start] + "|" + fields[start+1] ... (titles may contain "|")
function joinFrom(fields as Object, start as Integer) as String
    parts = []
    for i = start to fields.Count() - 1
        parts.Push(fields[i])
    end for
    return parts.Join("|")
end function

function md5Hex(text as String) as String
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(text)
    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    return digest.Process(bytes)
end function

function nowSeconds() as Integer
    clock = CreateObject("roDateTime")
    return clock.AsSeconds()
end function
