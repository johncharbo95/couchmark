' ============================================================================
' LogTask.brs — collects log lines and writes the day's file (lib/Log.brs)
'
' Every write rewrites the whole file, so lines are batched: at most one
' write per LogFlushMs(), except that a batch with an error is written at
' once (the app may be about to crash).
' ============================================================================

sub init()
    m.top.functionName = "writeLoop"
end sub

sub writeLoop()
    port = CreateObject("roMessagePort")
    m.top.ObserveField("lines", port)
    m.top.ready = true

    store = LogStoreNew()
    pending = []
    sinceWrite = CreateObject("roTimespan")
    while true
        msg = Wait(500, port)
        if Type(msg) = "roSGNodeEvent"
            lines = msg.GetData()
            if Type(lines) = "roArray" then pending.Append(lines)
        end if

        if pending.Count() > 0 and (sinceWrite.TotalMilliseconds() >= LogFlushMs() or LogHasError(pending))
            if m.top.enabled
                ' If nothing can be written (not even tmp:), the batch is dropped.
                target = ""
                if LogStoreAppend(store, pending, LogDateText(logNow())) then target = store.dir
                if m.top.target <> target then m.top.target = target
            end if
            pending = []
            sinceWrite.Mark()
        end if
    end while
end sub
