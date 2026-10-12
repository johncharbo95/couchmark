' ============================================================================
' Progress.brs — remembers playback positions in the Roku registry
'
' The registry is Roku's small persistent key/value store (~16 KB per app,
' shared by all sections). To stay well under that, each movie gets ONE short
' entry in the "progress" section:
'
'   key:   "m" + first 8 hex chars of MD5(lower-case movie folder name)
'   value: "lastUsed|part|parts|pos|dur|watched"
'           lastUsed  seconds since 1970, used to forget old entries first
'           part      0-based index of the file being played (multi-part movies)
'           parts     how many files the movie has
'           pos       resume position in seconds within that part (0 = none)
'           dur       duration of that part in seconds (for the progress bar)
'           watched   1 once the movie has been finished (past 90%)
'
' Example: "1760270000|0|1|3734|7200|0"  = resume at 1:02:14 of a 2 h movie.
' When the total size passes PROGRESS_MAX_BYTES, least-recently-used entries
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
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(LCase(name))
    digest = CreateObject("roEVPDigest")
    digest.Setup("md5")
    return kind + Left(digest.Process(bytes), 8)
end function

' Returns { part, parts, pos, dur, watched } or invalid if never played.
function ProgressGetMovie(name as String) as Dynamic
    section = progressSection()
    key = ProgressKey("m", name)
    if not section.Exists(key) then return invalid

    fields = section.Read(key).Split("|")
    if fields.Count() < 6 then return invalid
    return {
        part: fields[1].ToInt()
        parts: fields[2].ToInt()
        pos: fields[3].ToInt()
        dur: fields[4].ToInt()
        watched: fields[5] = "1"
    }
end function

' record = { part, parts, pos, dur, watched } (same shape as ProgressGetMovie)
sub ProgressSaveMovie(name as String, record as Object)
    watched = "0"
    if record.watched then watched = "1"

    value = nowSeconds().ToStr() + "|" + record.part.ToStr() + "|" + record.parts.ToStr() + "|" + record.pos.ToStr() + "|" + record.dur.ToStr() + "|" + watched
    progressWrite(ProgressKey("m", name), value)
end sub

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

function nowSeconds() as Integer
    clock = CreateObject("roDateTime")
    return clock.AsSeconds()
end function
