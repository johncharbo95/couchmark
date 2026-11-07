' ============================================================================
' Log.brs — debug log: print, plus a daily file on the USB drive
'
' Any component or Task can call:
'   LogInfo("ShowScanTask", "3 seasons, 30 episodes")
'   LogWarn(tag, message) / LogError(tag, message)
' Each call prints the line (Debug Console / telnet 8085, as before) and
' sends it to the one LogTask, which owns the file:
'
'   any thread --m.global.logLine--> MainScene (collects) --lines--> LogTask
'
' Only LogTask writes files, so lines from several threads never clobber
' each other (see docs/DEVELOPMENT.md, "Debug log"). The LogStore* functions
' below run on the LogTask thread only.
'
' Files: <volume>/Couchmark/logs/couchmark-YYYY-MM-DD.log on the first USB
' drive that can be written, else tmp:/couchmark-logs (lost on reboot).
' Roku has no "append to file", so the day's text is kept in memory and the
' whole file is rewritten; it's capped at LogMaxChars() (oldest lines go
' first) and only the newest LogKeepDays() files are kept.
'
' Device access goes through the small log* seams at the end, which
' tests/doubles/LogFiles.brs replaces (tests/Log.test.brs).
' ============================================================================

sub LogInfo(tag as String, message as String)
    LogWrite("INFO", tag, message)
end sub

sub LogWarn(tag as String, message as String)
    LogWrite("WARN", tag, message)
end sub

sub LogError(tag as String, message as String)
    LogWrite("ERROR", tag, message)
end sub

sub LogWrite(level as String, tag as String, message as String)
    line = LogFormatLine(LogTimestamp(logNow()), level, tag, message)
    print line
    logSend(line)
end sub

' ----------------------------------------------------------------------------
' Pure helpers (unit-tested)
' ----------------------------------------------------------------------------

function LogKeepDays() as Integer
    return 7
end function

' About 256 KB per day's file.
function LogMaxChars() as Integer
    return 262144
end function

' Lines are written at most this often (errors right away).
function LogFlushMs() as Integer
    return 1000
end function

function LogFallbackDir() as String
    return "tmp:/couchmark-logs"
end function

' { year, month, day, ... } -> "2026-10-24"
function LogDateText(t as Object) as String
    return t.year.ToStr() + "-" + logPad(t.month, 2) + "-" + logPad(t.day, 2)
end function

' { year, month, day, hour, minute, second, ms } -> "2026-10-24 21:05:03.042"
function LogTimestamp(t as Object) as String
    return LogDateText(t) + " " + logPad(t.hour, 2) + ":" + logPad(t.minute, 2) + ":" + logPad(t.second, 2) + "." + logPad(t.ms, 3)
end function

' "2026-10-24 21:05:03.042 INFO  [Tag] message" — always one line.
function LogFormatLine(timestamp as String, level as String, tag as String, message as String) as String
    while Len(level) < 5
        level = level + " "
    end while
    text = message.Replace(Chr(13) + Chr(10), " | ").Replace(Chr(10), " | ").Replace(Chr(13), " | ")
    return timestamp + " " + level + " [" + tag + "] " + text
end function

function LogFileName(dateText as String) as String
    return "couchmark-" + dateText + ".log"
end function

' True for names made by LogFileName ("couchmark-YYYY-MM-DD.log").
function LogIsLogFileName(name as String) as Boolean
    return Len(name) = 24 and Left(name, 10) = "couchmark-" and Mid(name, 21) = ".log"
end function

' Which files in a log folder to delete so that only the newest `keep`
' days remain, counting today's file (which may not exist yet). Other
' files are never touched.
function LogFilesToDelete(names as Object, todayName as String, keep as Integer) as Object
    logs = [todayName]
    for each name in names
        if LogIsLogFileName(name) and name <> todayName then logs.Push(name)
    end for
    logs.Sort()   ' the dates sort as text
    remove = []
    for i = 0 to logs.Count() - 1 - keep
        if logs[i] <> todayName then remove.Push(logs[i])
    end for
    return remove
end function

' The text, shortened to at most maxChars by dropping whole lines from the
' start. It's cut to 3/4 of the limit so this doesn't happen on every write.
function LogCapText(text as String, maxChars as Integer) as String
    if Len(text) <= maxChars then return text
    marker = "(older lines removed)" + Chr(10)
    cut = Len(text) - Int(maxChars * 3 / 4) + Len(marker)
    newline = Instr(cut, text, Chr(10))
    if newline = 0 then return marker
    return marker + Mid(text, newline + 1)
end function

' Folders to try, in order: <volume>/Couchmark/logs on each USB drive
' (ext1:, ext2:, ...), then the fallback in tmp:.
function LogDirCandidates(volumes as Object) as Object
    drives = []
    for each volume in volumes
        if Left(volume, 3) = "ext" then drives.Push(volume)
    end for
    drives.Sort()
    dirs = []
    for each volume in drives
        dirs.Push(volume + "/Couchmark/logs")
    end for
    dirs.Push(LogFallbackDir())
    return dirs
end function

' True if a batch contains an error line (then it's written right away).
function LogHasError(lines as Object) as Boolean
    for each line in lines
        if Instr(1, line, " ERROR [") > 0 then return true
    end for
    return false
end function

' Up to `limit` names joined with ", ", then "… (+N more)".
function LogNameList(names as Object, limit as Integer) as String
    text = ""
    for i = 0 to names.Count() - 1
        if i = limit
            text = text + " ... (+" + (names.Count() - limit).ToStr() + " more)"
            exit for
        end if
        if i > 0 then text = text + ", "
        text = text + names[i]
    end for
    return text
end function

' A Video node's error as one log message. `video` is the node (or, in
' tests, an associative array with the same fields). errorStr and
' errorInfo only exist on newer Roku OS versions.
function PlayerErrorText(video as Object, url as String) as String
    text = "playback error: " + url + " | errorMsg=" + logFieldText(video, "errorMsg") + " | errorCode=" + logFieldText(video, "errorCode")
    for each name in ["errorStr", "errorInfo"]
        value = logFieldText(video, name)
        if value <> "" then text = text + " | " + name + "=" + value
    end for
    return text
end function

' A field of a node or associative array as text ("" when missing).
function logFieldText(obj as Object, name as String) as String
    if Type(obj) = "roSGNode"
        if not obj.HasField(name) then return ""
        value = obj.GetField(name)
    else
        if not obj.DoesExist(name) then return ""
        value = obj[name]
    end if
    kind = Type(value)
    if kind = "Invalid" or kind = "roInvalid" then return ""
    if kind = "roString" or kind = "String" then return value
    return FormatJson(value)
end function

function logPad(value as Integer, width as Integer) as String
    text = value.ToStr()
    while Len(text) < width
        text = "0" + text
    end while
    return text
end function

' ----------------------------------------------------------------------------
' The file (LogTask thread only)
' ----------------------------------------------------------------------------

' State kept by LogTask between writes.
'   dir     folder being written ("" = none yet)
'   date    "YYYY-MM-DD" of the open file
'   text    the open file's whole contents
'   carry   lines written to tmp: this session, copied to the drive once
'           one can be written again (e.g. lines from before it mounted)
'   failed  folders that couldn't be written, skipped until drives change
function LogStoreNew() as Object
    return { dir: "", date: "", text: "", carry: "", failed: {}, volumes: "" }
end function

' Adds lines to today's file in the first folder that can be written.
' Returns false if nothing could be written (not even tmp:).
function LogStoreAppend(store as Object, lines as Object, dateText as String) as Boolean
    if lines.Count() = 0 then return true
    added = lines.Join(Chr(10)) + Chr(10)
    fallback = LogFallbackDir()

    volumes = logVolumes()
    volumesKey = volumes.Join(",")
    if volumesKey <> store.volumes
        ' A drive came or went: worth trying every folder again.
        store.volumes = volumesKey
        store.failed = {}
    end if

    for each dir in LogDirCandidates(volumes)
        if not store.failed.DoesExist(dir) and logStoreWrite(store, dir, dateText, added)
            if dir = fallback
                store.carry = LogCapText(store.carry + added, LogMaxChars())
            else
                store.carry = ""
            end if
            return true
        end if
        if dir <> fallback then store.failed[dir] = true
    end for
    return false
end function

' Writes the day's file in `dir` with `added` at the end. Opening a new
' file (other folder or new day) reads what's there and removes old days.
function logStoreWrite(store as Object, dir as String, dateText as String, added as String) as Boolean
    path = dir + "/" + LogFileName(dateText)
    isOpen = (dir = store.dir and dateText = store.date)
    if isOpen
        text = store.text + added
    else
        if not logMakeDirs(dir) then return false
        text = logReadFile(path)
        if dir <> LogFallbackDir() then text = text + store.carry
        text = text + added
    end if
    text = LogCapText(text, LogMaxChars())
    if not logWriteFile(path, text) then return false

    if not isOpen
        for each name in LogFilesToDelete(logListDir(dir), LogFileName(dateText), LogKeepDays())
            logDeleteFile(dir + "/" + name)
        end for
    end if
    store.dir = dir
    store.date = dateText
    store.text = text
    return true
end function

' ----------------------------------------------------------------------------
' Device seams (replaced in tests by tests/doubles/LogFiles.brs)
' ----------------------------------------------------------------------------

' Local time now as { year, month, day, hour, minute, second, ms }.
function logNow() as Object
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    return {
        year: now.GetYear(), month: now.GetMonth(), day: now.GetDayOfMonth()
        hour: now.GetHours(), minute: now.GetMinutes(), second: now.GetSeconds()
        ms: now.GetMilliseconds()
    }
end function

' Hands a line to MainScene (which passes it on to LogTask). Does nothing
' where there's no m.global (main.brs), or before MainScene added the field.
sub logSend(line as String)
    if m.global = invalid then return
    if m.global.HasField("logLine") then m.global.logLine = line
end sub

function logVolumes() as Object
    volumes = []
    for each volume in CreateObject("roFileSystem").GetVolumeList()
        volumes.Push(volume)
    end for
    return volumes
end function

' Creates dir and its parents if needed; true if it exists afterwards.
function logMakeDirs(dir as String) as Boolean
    fs = CreateObject("roFileSystem")
    if fs.Exists(dir) then return true
    parts = dir.Split("/")
    path = parts[0]
    for i = 1 to parts.Count() - 1
        path = path + "/" + parts[i]
        if not fs.Exists(path) then fs.CreateDirectory(path)
    end for
    return fs.Exists(dir)
end function

function logReadFile(path as String) as String
    return ReadAsciiFile(path)
end function

function logWriteFile(path as String, text as String) as Boolean
    return WriteAsciiFile(path, text)
end function

function logListDir(dir as String) as Object
    names = []
    for each name in CreateObject("roFileSystem").GetDirectoryListing(dir)
        names.Push(name)
    end for
    return names
end function

sub logDeleteFile(path as String)
    DeleteFile(path)
end sub
