' ============================================================================
' MediaDateTask.brs
' ============================================================================

sub init()
    m.top.functionName = "readDates"
end sub

sub readDates()
    media = ScanMedia(m.top.paths).media
    total = media.Count()

    items = []
    order = []
    for i = 0 to total - 1
        entry = media[i]
        info = MediaInfo(entry.path, entry.kind)
        items.Push({ path: entry.path, kind: entry.kind, name: entry.name, date: info.date, source: info.source, rotation: info.rotation })

        ' Sort key: zero-padded date, then the natural name order for ties
        ' (e.g. burst photos taken in the same second).
        key = info.date.ToStr()
        while Len(key) < 12
            key = "0" + key
        end while
        order.Push({ key: key + NaturalSortKey(entry.name, false), index: i })

        if i mod 10 = 0 then m.top.progress = i.ToStr() + " / " + total.ToStr()
    end for

    order.SortBy("key")
    sorted = []
    for each entry in order
        sorted.Push(items[entry.index])
    end for

    print "[MediaDateTask] "; total; " items in "; FormatJson(m.top.paths)
    m.top.items = sorted
end sub
