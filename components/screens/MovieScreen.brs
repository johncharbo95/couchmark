' ============================================================================
' MovieScreen.brs
'
' On first focus, lists the movie's video files ("parts"), then shows
' Resume / Play from beginning. Refreshes when it reappears after playback.
' ============================================================================

sub init()
    m.buttons = m.top.FindNode("buttons")
    m.infoLabel = m.top.FindNode("infoLabel")
    m.progressBar = m.top.FindNode("progressBar")
    m.progressFill = m.top.FindNode("progressFill")
    m.loading = m.top.FindNode("loading")

    m.buttons.ObserveField("itemSelected", "onButtonSelected")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")
    m.top.ObserveField("visible", "onVisibleChange")

    m.parts = invalid
    m.started = false
end sub

sub onFocusedChildChange()
    if not m.top.HasFocus() then return
    if not m.started
        m.started = true
        m.loading.message = "Opening " + m.top.title + "…"
        m.loading.visible = true
        m.task = CreateObject("roSGNode", "FolderScanTask")
        m.task.paths = [m.top.path]
        m.task.mode = "videos"
        m.task.ObserveField("content", "onPartsScanned")
        m.task.control = "run"
    end if
    m.buttons.SetFocus(true)
end sub

sub onVisibleChange()
    if m.top.visible and m.parts <> invalid then refresh()
end sub

sub onPartsScanned(event as Object)
    m.loading.visible = false
    content = event.GetData()
    if m.top.art = "" then m.top.art = content.hdPosterUrl
    m.parts = []
    for each child in content.GetChildren(-1, 0)
        m.parts.Push({ path: child.url })
    end for
    refresh()
end sub

' Rebuilds the info line and the buttons from the saved progress.
sub refresh()
    if m.parts.Count() = 0
        m.infoLabel.text = "No playable video files in this folder (.mp4 .m4v .mov .mkv .ts .webm)"
        m.buttons.content = invalid
        return
    end if

    m.record = ProgressGetMovie(m.top.title)
    m.canResume = MovieInProgress(m.record) and m.record.part < m.parts.Count()

    info = ""
    if m.parts.Count() > 1 then info = m.parts.Count().ToStr() + " parts"
    if m.canResume
        info = MovieResumeText(m.record)
    else if m.record <> invalid and m.record.watched
        info = "Watched"
    end if
    m.infoLabel.text = info

    m.progressBar.visible = m.canResume
    if m.canResume then m.progressFill.width = 500 * MovieFraction(m.record)

    content = CreateObject("roSGNode", "ContentNode")
    if m.canResume
        content.CreateChild("ContentNode").title = "Resume"
        content.CreateChild("ContentNode").title = "Play from beginning"
    else
        content.CreateChild("ContentNode").title = "Play"
    end if
    m.buttons.content = content
end sub

sub onButtonSelected()
    startIndex = 0
    startPos = 0
    if m.canResume and m.buttons.itemSelected = 0
        startIndex = m.record.part
        startPos = m.record.pos
    end if

    m.top.navigate = {
        screen: "PlayerScreen"
        fields: { kind: "movie", title: m.top.title, items: MoviePlayerItems(m.parts), startIndex: startIndex, startPos: startPos }
    }
end sub
