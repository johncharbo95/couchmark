' ============================================================================
' SlideshowScreen.brs
'
' REMOTE KEYS
'   OK / Play-Pause     pause or resume
'   Left / ◀◀           previous item
'   Right / ▶▶          next item
'   Up / Down / *       show the date / name / position for a few seconds
'   Back                leave the slideshow
'
' FLOW
'   MediaDateTask lists the folder and sorts by date taken → showItem(0).
'   Photo: shown for the "photo duration" setting, then the next item,
'          arriving with the chosen transition (lib/Transitions.brs).
'   Video: plays to the end (or until Right), then the next item.
'   After the last item the slideshow starts again from the first.
' ============================================================================

sub init()
    m.video = m.top.FindNode("video")
    m.info = m.top.FindNode("info")
    m.dateLabel = m.top.FindNode("dateLabel")
    m.nameLabel = m.top.FindNode("nameLabel")
    m.counterLabel = m.top.FindNode("counterLabel")
    m.pauseIcon = m.top.FindNode("pauseIcon")
    m.loading = m.top.FindNode("loading")
    m.photoTimer = m.top.FindNode("photoTimer")
    m.infoTimer = m.top.FindNode("infoTimer")

    ' The two image slots. "path" = what the slot's poster holds.
    ' Each slot also knows the interpolators that animate it.
    m.slots = [slotNodes("A"), slotNodes("B")]
    m.stage = m.top.FindNode("stage")
    m.transition = m.top.FindNode("transition")
    m.transition.ObserveField("state", "onTransitionState")
    m.transitioning = false
    m.front = 0             ' slot currently on screen
    m.waitingSlot = -1      ' slot we're waiting on to finish loading

    for each slot in m.slots
        slot.poster.ObserveField("loadStatus", "onPosterStatus")
    end for
    m.video.ObserveField("state", "onVideoState")
    m.photoTimer.ObserveField("fire", "onPhotoTimer")
    m.infoTimer.ObserveField("fire", "onInfoTimer")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")

    m.items = invalid       ' set once MediaDateTask is done
    m.settings = SettingsGet()
    m.clock = CreateObject("roTimespan")
    m.paused = false
    m.failures = 0
    m.started = false
end sub

sub onFocusedChildChange()
    if m.started or not m.top.HasFocus() then return
    m.started = true

    m.loading.message = "Sorting by date taken…"
    m.loading.visible = true
    m.task = CreateObject("roSGNode", "MediaDateTask")
    m.task.paths = m.top.paths
    m.task.ObserveField("progress", "onTaskProgress")
    m.task.ObserveField("items", "onItemsReady")
    m.task.control = "run"
end sub

sub onTaskProgress()
    m.loading.message = "Reading dates…  " + m.task.progress
end sub

sub onItemsReady(event as Object)
    m.loading.visible = false
    m.items = event.GetData()
    if m.items.Count() = 0
        m.top.navigate = {
            screen: "MessageScreen"
            replace: true
            fields: { title: m.top.title, message: "There are no photos or videos in this folder that Couchmark can show." }
        }
        return
    end if
    showItem(0)
    showInfo()
end sub

' ----------------------------------------------------------------------------
' Showing items
' ----------------------------------------------------------------------------

sub showItem(index as Integer)
    finishTransition()
    m.index = index
    m.photoTimer.control = "stop"
    m.waitingSlot = -1
    item = m.items[index]
    updateInfo()

    if item.kind = "video"
        playVideo(item)
        return
    end if

    ' Photo: use the hidden slot (it may already hold this photo, preloaded).
    backIndex = 1 - m.front
    if m.slots[backIndex].path <> item.path then loadPhoto(backIndex, item)

    status = m.slots[backIndex].poster.loadStatus
    if status = "ready"
        revealPhoto(backIndex)
    else if status = "failed"
        skipBroken()
    else
        m.waitingSlot = backIndex   ' onPosterStatus reveals it when loaded
    end if
end sub

' Loads a photo into a slot, sized and rotated for its EXIF orientation.
sub loadPhoto(slotIndex as Integer, item as Object)
    slot = m.slots[slotIndex]
    poster = slot.poster
    slot.path = item.path

    if item.rotation = 90 or item.rotation = 270
        ' Sideways photo: lay the poster out 1080 wide x 1920 tall and turn
        ' it a quarter turn around its centre, so it fills the screen height.
        poster.width = 1080
        poster.height = 1920
        poster.translation = [420, -420]
        poster.scaleRotateCenter = [540, 960]
        ' rotation is in radians, counter-clockwise.
        if item.rotation = 90 then poster.rotation = -1.5707963 else poster.rotation = 1.5707963
    else
        poster.width = 1920
        poster.height = 1080
        poster.translation = [0, 0]
        poster.scaleRotateCenter = [960, 540]
        if item.rotation = 180 then poster.rotation = 3.1415927 else poster.rotation = 0
    end if
    ' Decode at screen size, not camera size (saves memory, loads faster).
    poster.loadWidth = poster.width
    poster.loadHeight = poster.height
    poster.uri = item.path
end sub

sub onPosterStatus(event as Object)
    if m.waitingSlot < 0 then return
    slot = m.slots[m.waitingSlot]
    if not slot.poster.IsSameNode(event.GetRoSGNode()) then return

    status = event.GetData()
    if status = "ready"
        revealPhoto(m.waitingSlot)
    else if status = "failed"
        skipBroken()
    end if
end sub

' Brings the loaded slot on screen with the chosen transition.
sub revealPhoto(slotIndex as Integer)
    m.waitingSlot = -1
    m.failures = 0
    incoming = m.slots[slotIndex]
    outgoing = m.slots[1 - slotIndex]

    ' After a video the old photo is stale: hide it and fade in over black.
    if m.video.visible then outgoing.group.visible = false
    stopVideo()

    plan = TransitionPlan(m.settings.transition, TransitionSeconds(m.settings.speed), Rnd(5) - 1)
    if not outgoing.group.visible and plan.duration > 0 then plan = TransitionPlan("fade", plan.duration, 0)

    ' Draw the incoming slot on top of the outgoing one.
    m.stage.RemoveChild(incoming.group)
    m.stage.AppendChild(incoming.group)
    m.front = slotIndex

    if plan.duration = 0
        incoming.group.visible = true
        endTransition()
    else
        setKeys(incoming, plan.incoming)
        setKeys(outgoing, plan.outgoing)
        applyValues(incoming, plan.incoming, 0)   ' start position before showing
        incoming.group.visible = true
        m.transition.duration = plan.duration
        m.transitioning = true
        m.transition.control = "start"
    end if

    startPhotoTimer()
end sub

' ----------------------------------------------------------------------------
' Transitions
' ----------------------------------------------------------------------------

function slotNodes(letter as String) as Object
    return {
        group: m.top.FindNode("slot" + letter)
        inner: m.top.FindNode("inner" + letter)
        poster: m.top.FindNode("poster" + letter)
        path: ""
        opacityAnim: m.top.FindNode(LCase(letter) + "Opacity")
        translationAnim: m.top.FindNode(LCase(letter) + "Translation")
        scaleAnim: m.top.FindNode(LCase(letter) + "Scale")
        innerAnim: m.top.FindNode(LCase(letter) + "Inner")
    }
end function

' Copies a plan's [start, end] values into the slot's interpolators.
sub setKeys(slot as Object, values as Object)
    slot.opacityAnim.keyValue = values.opacity
    slot.translationAnim.keyValue = values.translation
    slot.scaleAnim.keyValue = values.scale
    slot.innerAnim.keyValue = values.inner
end sub

' Sets a slot directly to a plan's start (which = 0) or end (which = 1).
sub applyValues(slot as Object, values as Object, which as Integer)
    slot.group.opacity = values.opacity[which]
    slot.group.translation = values.translation[which]
    slot.group.scale = values.scale[which]
    slot.inner.translation = values.inner[which]
end sub

sub onTransitionState()
    if m.transition.state = "stopped" and m.transitioning then endTransition()
end sub

' Skipping ahead mid-transition: jump to its end state.
sub finishTransition()
    if not m.transitioning then return
    m.transition.control = "stop"
    endTransition()
end sub

' The incoming photo is fully on screen: hide and reset the old slot, then
' it's free to preload the next photo.
sub endTransition()
    m.transitioning = false
    applyValues(m.slots[m.front], stillSlot(), 1)
    outgoing = m.slots[1 - m.front]
    outgoing.group.visible = false
    applyValues(outgoing, stillSlot(), 1)
    preloadNext()
end sub

sub playVideo(item as Object)
    content = CreateObject("roSGNode", "ContentNode")
    content.url = item.path
    format = StreamFormatFor(item.path)
    if format <> "" then content.streamFormat = format
    m.video.content = content
    m.video.visible = true
    m.video.control = "play"
    preloadNext()
end sub

sub stopVideo()
    if m.video.visible
        m.video.control = "stop"
        m.video.visible = false
    end if
end sub

' Loads the next photo into the hidden slot while the current item shows.
sub preloadNext()
    nextItem = m.items[nextIndex()]
    backIndex = 1 - m.front
    if nextItem.kind = "photo" and m.slots[backIndex].path <> nextItem.path
        loadPhoto(backIndex, nextItem)
    end if
end sub

' A file couldn't be shown: move on, unless nothing in the folder works.
sub skipBroken()
    m.failures = m.failures + 1
    print "[Slideshow] skipping "; m.items[m.index].path
    if m.failures >= m.items.Count()
        m.top.navigate = {
            screen: "MessageScreen"
            replace: true
            fields: { title: m.top.title, message: "None of the files in this folder could be shown. Your Roku may not support their format." }
        }
        return
    end if
    showItem(nextIndex())
end sub

function nextIndex() as Integer
    return (m.index + 1) mod m.items.Count()
end function

function previousIndex() as Integer
    return (m.index - 1 + m.items.Count()) mod m.items.Count()
end function

' ----------------------------------------------------------------------------
' Timing & pause
' ----------------------------------------------------------------------------

sub startPhotoTimer()
    m.remainingMs = m.settings.photoSeconds * 1000
    if not m.paused then runPhotoTimer()
end sub

sub runPhotoTimer()
    seconds = m.remainingMs / 1000
    if seconds < 0.3 then seconds = 0.3
    m.photoTimer.duration = seconds
    m.photoTimer.control = "start"
    m.clock.Mark()
end sub

sub onPhotoTimer()
    if not m.paused then showItem(nextIndex())
end sub

sub onVideoState()
    state = m.video.state
    if state = "finished"
        showItem(nextIndex())
    else if state = "error"
        print "[Slideshow] video error: "; m.video.errorMsg
        skipBroken()
    else if state = "playing"
        m.failures = 0
    end if
end sub

sub togglePause()
    m.paused = not m.paused
    m.pauseIcon.visible = m.paused
    item = m.items[m.index]

    if item.kind = "video"
        if m.paused then m.video.control = "pause" else m.video.control = "resume"
    else if m.paused
        ' Remember how much of this photo's time is left.
        m.photoTimer.control = "stop"
        m.remainingMs = m.remainingMs - m.clock.TotalMilliseconds()
    else if m.waitingSlot < 0
        runPhotoTimer()
    end if
    showInfo()
end sub

' Next / previous always resume the slideshow.
sub jump(index as Integer)
    m.paused = false
    m.pauseIcon.visible = false
    showItem(index)
    showInfo()
end sub

' ----------------------------------------------------------------------------
' Info bar
' ----------------------------------------------------------------------------

sub updateInfo()
    item = m.items[m.index]
    when = CreateObject("roDateTime")
    when.FromSeconds(item.date)
    m.dateLabel.text = when.AsDateString("long-date")
    m.nameLabel.text = m.top.title + "  ·  " + item.name
    m.counterLabel.text = (m.index + 1).ToStr() + " / " + m.items.Count().ToStr()
end sub

sub showInfo()
    m.info.visible = true
    m.infoTimer.control = "stop"
    m.infoTimer.control = "start"
end sub

sub onInfoTimer()
    if not m.paused then m.info.visible = false
end sub

' ----------------------------------------------------------------------------
' Keys
' ----------------------------------------------------------------------------

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.items = invalid
        ' Still sorting: only Back does anything.
        if key = "back" then leave()
        return true
    end if

    if key = "back"
        leave()
    else if key = "OK" or key = "play"
        togglePause()
    else if key = "left" or key = "rewind"
        jump(previousIndex())
    else if key = "right" or key = "fastforward"
        jump(nextIndex())
    else if key = "up" or key = "down" or key = "options"
        showInfo()
    end if
    return true
end function

sub leave()
    m.photoTimer.control = "stop"
    m.video.control = "stop"
    m.top.navigate = { action: "back" }
end sub
