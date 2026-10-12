' ============================================================================
' PlayerScreen.brs
'
' Progress rules (see lib/Progress.brs for the stored format):
'   - Saved every 10 s while playing, and when leaving with Back.
'   - Past 90% of the last part: the movie counts as watched and its resume
'     point is cleared (so the list shows ✓ instead of a progress bar).
'   - Less than 15 s into the first part: not worth resuming, nothing saved.
'   - When a part ends and another follows, "Up next" counts down 10 s.
' ============================================================================

sub init()
    m.video = m.top.FindNode("video")
    m.upNext = m.top.FindNode("upNext")

    m.video.ObserveField("state", "onVideoStateChange")
    m.video.ObserveField("position", "onPositionChange")
    m.upNext.ObserveField("choice", "onUpNextChoice")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")

    m.started = false
    m.lastSavedAt = 0
end sub

sub onFocusedChildChange()
    if not m.top.HasFocus() then return

    ' Fields are set after init(), so playback starts on first focus.
    if not m.started
        m.started = true
        playPart(m.top.startPart, m.top.startPos)
    else if m.upNext.visible
        m.upNext.SetFocus(true)
    else
        m.video.SetFocus(true)
    end if
end sub

sub playPart(index as Integer, startPos as Integer)
    m.part = index
    m.lastSavedAt = startPos
    path = m.top.parts[index]

    content = CreateObject("roSGNode", "ContentNode")
    content.url = path
    content.title = m.top.title
    if partCount() > 1
        content.title = m.top.title + "  ·  Part " + (index + 1).ToStr() + " of " + partCount().ToStr()
    end if
    format = StreamFormatFor(path)
    if format <> "" then content.streamFormat = format
    content.playStart = startPos

    print "[Player] playing "; path; " from "; startPos; "s"
    m.video.content = content
    m.video.control = "play"
    m.video.SetFocus(true)
end sub

function partCount() as Integer
    return m.top.parts.Count()
end function

' ----------------------------------------------------------------------------
' Progress
' ----------------------------------------------------------------------------

sub onPositionChange()
    position = m.video.position
    if Abs(position - m.lastSavedAt) >= 10
        m.lastSavedAt = position
        saveProgress()
    end if
end sub

sub saveProgress()
    position = Int(m.video.position)
    duration = Int(m.video.duration)
    if duration <= 0 then return   ' not loaded yet / failed

    isLastPart = (m.part = partCount() - 1)
    previous = ProgressGetMovie(m.top.title)
    wasWatched = (previous <> invalid and previous.watched)

    if isLastPart and position >= duration * 0.9
        ProgressSaveMovie(m.top.title, { part: 0, parts: partCount(), pos: 0, dur: 0, watched: true })
    else if m.part = 0 and position < 15
        ' Barely started: clear any old resume point but keep the ✓.
        if previous <> invalid
            ProgressSaveMovie(m.top.title, { part: 0, parts: partCount(), pos: 0, dur: 0, watched: wasWatched })
        end if
    else
        ProgressSaveMovie(m.top.title, { part: m.part, parts: partCount(), pos: position, dur: duration, watched: wasWatched })
    end if
end sub

' ----------------------------------------------------------------------------
' Playback events
' ----------------------------------------------------------------------------

sub onVideoStateChange()
    state = m.video.state
    print "[Player] state "; state

    if state = "finished"
        if m.part < partCount() - 1
            ' Remember that the next part is where to resume.
            ProgressSaveMovie(m.top.title, { part: m.part + 1, parts: partCount(), pos: 0, dur: 0, watched: false })
            m.upNext.heading = "Up next"
            m.upNext.title = "Part " + (m.part + 2).ToStr() + " of " + partCount().ToStr()
            m.upNext.visible = true
            m.upNext.start = true
            m.upNext.SetFocus(true)
        else
            ProgressSaveMovie(m.top.title, { part: 0, parts: partCount(), pos: 0, dur: 0, watched: true })
            m.top.navigate = { action: "back" }
        end if

    else if state = "error"
        fileName = m.top.parts[m.part]
        m.top.navigate = {
            screen: "MessageScreen"
            replace: true
            fields: {
                title: "Can't play this video"
                message: fileName + Chr(10) + Chr(10) + "Your Roku may not support this file's format or codec (Couchmark can't convert videos)." + Chr(10) + Chr(10) + "Details: " + m.video.errorMsg + " (" + m.video.errorCode.ToStr() + ")"
            }
        }
    end if
end sub

sub onUpNextChoice()
    m.upNext.visible = false
    if m.upNext.choice = "play"
        playPart(m.part + 1, 0)
    else
        m.top.navigate = { action: "back" }
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "back"
        ' Save before MainScene removes this screen.
        if not m.upNext.visible then saveProgress()
        m.video.control = "stop"
        m.top.navigate = { action: "back" }
        return true
    end if
    return false
end function
