' ============================================================================
' PlayerScreen.brs
'
' REMOTE KEYS
'   OK / Play-Pause   pause or resume (OK on a button presses that button)
'   Left / Right      back / forward 10 s   (on the button row: move)
'   ↺ Instant replay  back 10 s
'   ◀◀ / ▶▶           back / forward 30 s
'   Up / Down         show controls; Down moves to the button row
'   Back              stop and return (position is saved)
' Buttons: [Previous] [Back 10] [Play/Pause] [Forward 10] [Next]
' (Previous/Next only when there are several parts / episodes.)
'
' PROGRESS (see lib/Progress.brs for the stored format)
'   - Saved every 10 s while playing, and when leaving.
'   - Past 90% of a movie's last part, or of an episode: watched ✓, resume
'     point cleared.
'   - Less than 15 s in: no resume point.
'   - When an item ends and another follows, "Up next" counts down 10 s.
' ============================================================================

sub init()
    m.video = m.top.FindNode("video")
    m.spinner = m.top.FindNode("spinner")
    m.controls = m.top.FindNode("controls")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.subtitleLabel = m.top.FindNode("subtitleLabel")
    m.barFill = m.top.FindNode("barFill")
    m.knob = m.top.FindNode("knob")
    m.elapsedLabel = m.top.FindNode("elapsedLabel")
    m.remainingLabel = m.top.FindNode("remainingLabel")
    m.buttonRow = m.top.FindNode("buttonRow")
    m.buttonLabel = m.top.FindNode("buttonLabel")
    m.upNext = m.top.FindNode("upNext")
    m.hideTimer = m.top.FindNode("hideTimer")

    m.spinner.poster.uri = "pkg:/images/spinner.png"

    m.video.ObserveField("state", "onVideoStateChange")
    m.video.ObserveField("position", "onPositionChange")
    m.upNext.ObserveField("choice", "onUpNextChoice")
    m.hideTimer.ObserveField("fire", "onHideTimer")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")

    m.started = false
    m.lastSavedAt = 0
    m.pendingSeek = -1      ' target of a seek that hasn't finished yet
    m.focusRow = "bar"      ' "bar" (scrubber) or "buttons"
    m.button = 0            ' focused button index
end sub

sub onFocusedChildChange()
    ' Fields are set after init(), so playback starts on first focus.
    if m.started or not m.top.HasFocus() then return
    m.started = true
    m.items = m.top.items
    buildButtons()
    playItem(m.top.startIndex, m.top.startPos)
end sub

sub playItem(index as Integer, startPos as Integer)
    m.index = index
    m.lastSavedAt = startPos
    m.pendingSeek = -1
    item = m.items[index]

    content = CreateObject("roSGNode", "ContentNode")
    content.url = item.url
    content.title = m.top.title
    format = StreamFormatFor(item.url)
    if format <> "" then content.streamFormat = format
    content.playStart = startPos

    m.titleLabel.text = m.top.title
    m.subtitleLabel.text = item.label

    print "[Player] playing "; item.url; " from "; startPos; "s"
    m.video.content = content
    m.video.control = "play"
    updateButtons()
    showControls()
end sub

function hasNext() as Boolean
    return m.index < m.items.Count() - 1
end function

' ----------------------------------------------------------------------------
' Keys
' ----------------------------------------------------------------------------

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    ' While "Up next" is showing, it handles the keys itself.
    if m.upNext.visible then return false

    if key = "back"
        leave()
    else if key = "play"
        togglePause()
    else if key = "replay"
        seekBy(-10)
    else if key = "rewind"
        seekBy(-30)
    else if key = "fastforward"
        seekBy(30)
    else if key = "OK"
        if m.controls.visible and m.focusRow = "buttons"
            pressButton(m.buttons[m.button].id)
        else
            togglePause()
        end if
    else if key = "left" or key = "right"
        delta = 1
        if key = "left" then delta = -1
        if m.controls.visible and m.focusRow = "buttons"
            moveButton(delta)
        else
            seekBy(10 * delta)
        end if
    else if key = "down"
        if m.controls.visible then setFocusRow("buttons")
        showControls()
    else if key = "up"
        setFocusRow("bar")
        showControls()
    end if

    ' The player owns the whole remote while it's open.
    return true
end function

sub togglePause()
    if m.video.state = "paused"
        m.video.control = "resume"
    else
        m.video.control = "pause"
    end if
    showControls()
end sub

' Seeks relative to the current position. Several quick presses add up,
' because each one starts from the previous target, not the (lagging)
' playback position.
sub seekBy(seconds as Integer)
    base = m.video.position
    if m.pendingSeek >= 0 then base = m.pendingSeek
    target = base + seconds
    duration = m.video.duration
    if duration > 0 and target > duration - 2 then target = duration - 2
    if target < 0 then target = 0

    m.pendingSeek = target
    m.video.seek = target
    showControls()
    updateBar(target)
end sub

sub leave()
    m.hideTimer.control = "stop"
    saveProgress(false)
    m.video.control = "stop"
    m.top.navigate = { action: "back" }
end sub

' ----------------------------------------------------------------------------
' Controls overlay
' ----------------------------------------------------------------------------

' Creates the button row: Previous/Next only when there's more than one item.
sub buildButtons()
    nextLabel = "Next part"
    previousLabel = "Previous part"
    if m.top.kind = "show"
        nextLabel = "Next episode"
        previousLabel = "Previous episode"
    end if

    m.buttons = []
    if m.items.Count() > 1 then m.buttons.Push({ id: "previous", icon: "ic_prev", label: previousLabel })
    m.buttons.Push({ id: "back10", icon: "ic_back10", label: "Back 10 seconds" })
    m.buttons.Push({ id: "playpause", icon: "ic_pause", label: "Pause" })
    m.buttons.Push({ id: "forward10", icon: "ic_fwd10", label: "Forward 10 seconds" })
    if m.items.Count() > 1 then m.buttons.Push({ id: "next", icon: "ic_next", label: nextLabel })

    spacing = 150
    left = (1920 - ((m.buttons.Count() - 1) * spacing + 112)) / 2
    for i = 0 to m.buttons.Count() - 1
        group = m.buttonRow.CreateChild("Group")
        group.translation = [left + i * spacing, 0]
        ring = group.CreateChild("Poster")
        ring.uri = "pkg:/images/btn_focus.png"
        ring.width = 112
        ring.height = 112
        ring.visible = false
        icon = group.CreateChild("Poster")
        icon.uri = "pkg:/images/" + m.buttons[i].icon + ".png"
        icon.width = 64
        icon.height = 64
        icon.translation = [24, 24]
        m.buttons[i].group = group
        m.buttons[i].ring = ring
        m.buttons[i].iconNode = icon
        if m.buttons[i].id = "playpause" then m.button = i
    end for
end sub

' Refreshes focus ring, play/pause icon, dimmed buttons and the label.
sub updateButtons()
    if m.buttons = invalid then return
    paused = (m.video.state = "paused")
    for i = 0 to m.buttons.Count() - 1
        button = m.buttons[i]
        button.ring.visible = (m.focusRow = "buttons" and i = m.button)
        if button.id = "playpause"
            if paused
                button.iconNode.uri = "pkg:/images/ic_play.png"
                button.label = "Play"
            else
                button.iconNode.uri = "pkg:/images/ic_pause.png"
                button.label = "Pause"
            end if
        end if
        button.group.opacity = 1.0
        if button.id = "next" and not hasNext() then button.group.opacity = 0.35
    end for

    m.buttonLabel.text = ""
    if m.focusRow = "buttons" then m.buttonLabel.text = m.buttons[m.button].label
    if m.focusRow = "bar" then m.knob.scale = [1.3, 1.3] else m.knob.scale = [1.0, 1.0]
end sub

sub setFocusRow(row as String)
    m.focusRow = row
    updateButtons()
end sub

sub moveButton(delta as Integer)
    m.button = m.button + delta
    if m.button < 0 then m.button = 0
    if m.button > m.buttons.Count() - 1 then m.button = m.buttons.Count() - 1
    updateButtons()
    showControls()
end sub

sub pressButton(id as String)
    if id = "back10"
        seekBy(-10)
    else if id = "forward10"
        seekBy(10)
    else if id = "playpause"
        togglePause()
    else if id = "previous"
        ' First item: restart it. Otherwise go to the previous item.
        if m.index > 0
            switchTo(m.index - 1)
        else
            seekBy(-100000)
        end if
    else if id = "next"
        if hasNext() then switchTo(m.index + 1)
    end if
end sub

sub switchTo(index as Integer)
    saveProgress(false)
    playItem(index, 0)
end sub

sub showControls()
    m.controls.visible = true
    updateBar(-1)
    updateButtons()
    ' Stay visible while paused; otherwise hide after a few seconds.
    m.hideTimer.control = "stop"
    if m.video.state <> "paused" then m.hideTimer.control = "start"
end sub

sub onHideTimer()
    if m.video.state = "paused" then return
    m.controls.visible = false
    m.focusRow = "bar"
end sub

' Draws the progress bar. position < 0 = use the current playback position.
sub updateBar(position as Float)
    if position < 0
        position = m.video.position
        if m.pendingSeek >= 0 then position = m.pendingSeek
    end if
    duration = m.video.duration
    fraction = 0.0
    if duration > 0 then fraction = position / duration
    if fraction > 1 then fraction = 1

    m.barFill.width = 1728 * fraction
    m.knob.translation = [1728 * fraction - 14, -10]
    m.elapsedLabel.text = FormatTime(Int(position))
    m.remainingLabel.text = FormatRemainingOfTotal(Int(position), Int(duration))
end sub

' ----------------------------------------------------------------------------
' Progress
' ----------------------------------------------------------------------------

sub onPositionChange()
    position = m.video.position

    ' A seek has finished once playback reaches its target.
    if m.pendingSeek >= 0 and Abs(position - m.pendingSeek) < 2 then m.pendingSeek = -1
    if m.controls.visible then updateBar(-1)

    if Abs(position - m.lastSavedAt) >= 10
        m.lastSavedAt = position
        saveProgress(false)
    end if
end sub

' finished = true when the current item played to the end.
sub saveProgress(finished as Boolean)
    position = Int(m.video.position)
    duration = Int(m.video.duration)
    if duration <= 0 and not finished then return   ' not loaded yet / failed

    nearEnd = finished or position >= duration * 0.9
    if m.top.kind = "show"
        saveEpisodeProgress(position, duration, nearEnd)
    else
        saveMovieProgress(position, duration, nearEnd, finished)
    end if
end sub

sub saveMovieProgress(position as Integer, duration as Integer, nearEnd as Boolean, finished as Boolean)
    name = m.top.title
    parts = m.items.Count()
    previous = ProgressGetMovie(name)
    wasWatched = (previous <> invalid and previous.watched)

    if nearEnd and not hasNext()
        ProgressSaveMovie(name, { part: 0, parts: parts, pos: 0, dur: 0, watched: true })
    else if finished
        ' A part ended: resume at the start of the next part.
        ProgressSaveMovie(name, { part: m.index + 1, parts: parts, pos: 0, dur: 0, watched: wasWatched })
    else if m.index = 0 and position < 15
        ' Barely started: clear any old resume point but keep the ✓.
        if previous <> invalid
            ProgressSaveMovie(name, { part: 0, parts: parts, pos: 0, dur: 0, watched: wasWatched })
        end if
    else
        ProgressSaveMovie(name, { part: m.index, parts: parts, pos: position, dur: duration, watched: wasWatched })
    end if
end sub

sub saveEpisodeProgress(position as Integer, duration as Integer, nearEnd as Boolean)
    id = m.items[m.index].id
    record = ProgressGetShow(m.top.title)
    record.lastEp = id

    if nearEnd
        record.watched[id] = true
        ProgressRemovePartial(record, id)
    else if position >= 15
        ProgressSetPartial(record, id, position, duration)
    else
        ProgressRemovePartial(record, id)
    end if
    ProgressSaveShow(m.top.title, record)
end sub

' ----------------------------------------------------------------------------
' Playback events
' ----------------------------------------------------------------------------

sub onVideoStateChange()
    state = m.video.state
    print "[Player] state "; state

    m.spinner.visible = (state = "buffering")
    if m.spinner.visible then m.spinner.control = "start" else m.spinner.control = "stop"
    if m.controls.visible then showControls()   ' play/pause icon, auto-hide

    if state = "finished"
        m.controls.visible = false
        saveProgress(true)
        if hasNext()
            m.upNext.heading = "Up next"
            m.upNext.title = m.items[m.index + 1].label
            m.upNext.visible = true
            m.upNext.start = true
            m.upNext.SetFocus(true)
        else
            m.top.navigate = { action: "back" }
        end if

    else if state = "error"
        m.top.navigate = {
            screen: "MessageScreen"
            replace: true
            fields: {
                title: "Can't play this video"
                message: m.items[m.index].url + Chr(10) + Chr(10) + "Your Roku may not support this file's format or codec (Couchmark can't convert videos)." + Chr(10) + Chr(10) + "Details: " + m.video.errorMsg + " (" + m.video.errorCode.ToStr() + ")"
            }
        }
    end if
end sub

sub onUpNextChoice()
    m.upNext.visible = false
    m.top.SetFocus(true)
    if m.upNext.choice = "play"
        playItem(m.index + 1, 0)
    else
        m.top.navigate = { action: "back" }
    end if
end sub
