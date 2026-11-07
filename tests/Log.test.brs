' @include components/lib/Log.brs
' @double tests/doubles/LogFiles.brs

sub Main()
    testFormatting()
    testRotation()
    testCapping()
    testCandidates()
    testStore()
    finishTests()
end sub

sub testFormatting()
    t = { year: 2026, month: 3, day: 7, hour: 9, minute: 5, second: 2, ms: 42 }
    assertEqual(LogDateText(t), "2026-03-07", "date is zero-padded")
    assertEqual(LogTimestamp(t), "2026-03-07 09:05:02.042", "timestamp with milliseconds")
    assertEqual(LogFileName("2026-03-07"), "couchmark-2026-03-07.log", "file name for a date")

    assertEqual(LogFormatLine("T", "INFO", "Scan", "3 shows"), "T INFO  [Scan] 3 shows", "level padded to 5")
    assertEqual(LogFormatLine("T", "ERROR", "Player", "x"), "T ERROR [Player] x", "error level")
    assertEqual(LogFormatLine("T", "WARN", "A", "one" + Chr(10) + "two" + Chr(13) + Chr(10) + "three"), "T WARN  [A] one | two | three", "always one line")

    ' LogWrite prints and sends the formatted line.
    resetFakeFs([])
    LogError("Player", "boom")
    assertEqual(GetGlobalAA().sent, ["2026-03-07 09:05:02.042 ERROR [Player] boom"], "LogError sends one line")
    assertTrue(LogHasError(GetGlobalAA().sent), "error line detected")
    assertTrue(not LogHasError(["2026-03-07 09:05:02.042 INFO  [ERROR] x"]), "a tag called ERROR isn't an error")

    video = { errorMsg: "unsupported", errorCode: -5 }
    assertEqual(PlayerErrorText(video, "ext1:/a.mkv"), "playback error: ext1:/a.mkv | errorMsg=unsupported | errorCode=-5", "older OS: msg and code")
    video.errorStr = "decoder:pump"
    video.errorInfo = { category: "mediaerror" }
    assertEqual(PlayerErrorText(video, "u"), "playback error: u | errorMsg=unsupported | errorCode=-5 | errorStr=decoder:pump | errorInfo={" + Chr(34) + "category" + Chr(34) + ":" + Chr(34) + "mediaerror" + Chr(34) + "}", "newer OS: errorStr and errorInfo too")

    assertEqual(LogNameList(["a", "b"], 5), "a, b", "short name list")
    assertEqual(LogNameList(["a", "b", "c", "d"], 2), "a, b ... (+2 more)", "long name list is cut")
end sub

sub testRotation()
    assertTrue(LogIsLogFileName("couchmark-2026-03-07.log"), "log file name recognised")
    assertTrue(not LogIsLogFileName("couchmark-2026-03-07.txt"), "other extension")
    assertTrue(not LogIsLogFileName("notes.log"), "other file")

    names = ["couchmark-2026-03-01.log", "couchmark-2026-03-05.log", "notes.txt", "couchmark-2026-03-03.log", "couchmark-2026-03-02.log"]
    today = "couchmark-2026-03-07.log"
    assertEqual(LogFilesToDelete(names, today, 3), ["couchmark-2026-03-01.log", "couchmark-2026-03-02.log"], "keeps today + the 2 newest")
    assertEqual(LogFilesToDelete(names, today, 7), [], "nothing to delete")
    names.Push(today)
    assertEqual(LogFilesToDelete(names, today, 1), ["couchmark-2026-03-01.log", "couchmark-2026-03-02.log", "couchmark-2026-03-03.log", "couchmark-2026-03-05.log"], "today is never deleted")
end sub

sub testCapping()
    assertEqual(LogCapText("short" + Chr(10), 100), "short" + Chr(10), "under the cap: unchanged")

    text = ""
    for i = 10 to 99
        text = text + "line " + i.ToStr() + Chr(10)   ' 8 chars per line
    end for
    capped = LogCapText(text, 400)
    assertTrue(Len(capped) <= 300, "cut to 3/4 of the cap")
    assertTrue(Len(capped) > 250, "but not much more")
    assertEqual(Left(capped, 22), "(older lines removed)" + Chr(10), "marker first")
    assertEqual(Right(capped, 8), "line 99" + Chr(10), "newest line kept")
    assertEqual(Mid(capped, 23, 5), "line ", "starts at a whole line")
end sub

sub testCandidates()
    assertEqual(LogDirCandidates(["tmp:", "ext2:", "pkg:", "ext1:"]), ["ext1:/Couchmark/logs", "ext2:/Couchmark/logs", "tmp:/couchmark-logs"], "drives in order, then tmp")
    assertEqual(LogDirCandidates(["tmp:"]), ["tmp:/couchmark-logs"], "no drive: tmp only")
end sub

sub testStore()
    usbFile = "ext1:/Couchmark/logs/couchmark-2026-03-07.log"
    tmpFile = "tmp:/couchmark-logs/couchmark-2026-03-07.log"
    nl = Chr(10)

    ' Writes to the drive, and keeps appending to the same file.
    resetFakeFs(["ext1:", "tmp:"])
    store = LogStoreNew()
    assertTrue(LogStoreAppend(store, ["a", "b"], "2026-03-07"), "write succeeds")
    assertEqual(logReadFile(usbFile), "a" + nl + "b" + nl, "lines on the drive")
    LogStoreAppend(store, ["c"], "2026-03-07")
    assertEqual(logReadFile(usbFile), "a" + nl + "b" + nl + "c" + nl, "appended")

    ' A new launch continues the day's existing file.
    store = LogStoreNew()
    LogStoreAppend(store, ["d"], "2026-03-07")
    assertEqual(logReadFile(usbFile), "a" + nl + "b" + nl + "c" + nl + "d" + nl, "existing file continued")

    ' Read-only drive: falls back to tmp:.
    resetFakeFs(["ext1:", "tmp:"])
    GetGlobalAA().fakeFs.readOnly["ext1:"] = true
    store = LogStoreNew()
    assertTrue(LogStoreAppend(store, ["x"], "2026-03-07"), "fallback write succeeds")
    assertEqual(logReadFile(tmpFile), "x" + nl, "written to tmp")
    assertEqual(store.dir, "tmp:/couchmark-logs", "store uses tmp")

    ' Second read-only drive skipped, first writable one used.
    resetFakeFs(["ext1:", "ext2:", "tmp:"])
    GetGlobalAA().fakeFs.readOnly["ext1:"] = true
    store = LogStoreNew()
    LogStoreAppend(store, ["y"], "2026-03-07")
    assertEqual(store.dir, "ext2:/Couchmark/logs", "next drive used")

    ' No drive at first (not mounted yet), then it appears: lines written
    ' to tmp meanwhile are copied to the drive.
    resetFakeFs(["tmp:"])
    store = LogStoreNew()
    LogStoreAppend(store, ["early"], "2026-03-07")
    assertEqual(logReadFile(tmpFile), "early" + nl, "early line in tmp")
    GetGlobalAA().fakeFs.volumes = ["ext1:", "tmp:"]
    LogStoreAppend(store, ["later"], "2026-03-07")
    assertEqual(logReadFile(usbFile), "early" + nl + "later" + nl, "tmp lines carried to the drive")
    LogStoreAppend(store, ["more"], "2026-03-07")
    assertEqual(logReadFile(usbFile), "early" + nl + "later" + nl + "more" + nl, "carried only once")

    ' Drive unplugged: tmp; plugged back in: the missed lines follow.
    GetGlobalAA().fakeFs.volumes = ["tmp:"]
    LogStoreAppend(store, ["gone"], "2026-03-07")
    GetGlobalAA().fakeFs.volumes = ["ext1:", "tmp:"]
    LogStoreAppend(store, ["back"], "2026-03-07")
    assertEqual(logReadFile(usbFile), "early" + nl + "later" + nl + "more" + nl + "gone" + nl + "back" + nl, "lines from while unplugged are kept")

    ' Nothing writable at all: false, no crash.
    resetFakeFs([])
    store = LogStoreNew()
    assertTrue(not LogStoreAppend(store, ["z"], "2026-03-07"), "no folder can be written")

    ' A new day opens a new file and removes the oldest days.
    resetFakeFs(["ext1:", "tmp:"])
    files = GetGlobalAA().fakeFs.files
    for day = 1 to 8
        files["ext1:/Couchmark/logs/couchmark-2026-02-" + logPad(day, 2) + ".log"] = "old" + nl
    end for
    files["ext1:/Couchmark/logs/readme.txt"] = "keep me"
    store = LogStoreNew()
    LogStoreAppend(store, ["new day"], "2026-03-07")
    remaining = logListDir("ext1:/Couchmark/logs")
    logs = []
    for each name in remaining
        if LogIsLogFileName(name) then logs.Push(name)
    end for
    assertEqual(logs.Count(), 7, "7 days kept")
    assertTrue(logReadFile("ext1:/Couchmark/logs/couchmark-2026-02-01.log") = "", "oldest removed")
    assertTrue(logReadFile("ext1:/Couchmark/logs/couchmark-2026-02-02.log") = "", "second oldest removed")
    assertEqual(logReadFile("ext1:/Couchmark/logs/readme.txt"), "keep me", "other files untouched")
    LogStoreAppend(store, ["next"], "2026-03-08")
    assertEqual(logReadFile("ext1:/Couchmark/logs/couchmark-2026-03-08.log"), "next" + nl, "new file at midnight")
    assertEqual(logReadFile(usbFile), "new day" + nl, "yesterday's file unchanged")
end sub
