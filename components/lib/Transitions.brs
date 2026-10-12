' ============================================================================
' Transitions.brs — what each slideshow transition does
'
' A transition moves two image slots: the INCOMING photo and the OUTGOING
' one. For each slot, a plan gives start and end values for:
'   opacity      0.0 – 1.0
'   translation  [x, y] of the slot (the slot clips to the screen)
'   scale        [sx, sy] around the screen centre
'   inner        [x, y] of the picture INSIDE the slot. Wipe moves the slot
'                one way and the picture the other way, so the picture stays
'                still while the visible window sweeps across it.
' SlideshowScreen turns a plan into Animation keyframes; this file has no
' SceneGraph code, so it can be unit-tested.
' ============================================================================

' Names in the order shown in Settings.
function TransitionNames() as Object
    return ["none", "fade", "slide", "push", "wipe", "zoom", "random"]
end function

' Seconds a transition takes at each speed.
function TransitionSeconds(speed as String) as Float
    if speed = "slow" then return 1.5
    if speed = "fast" then return 0.4
    return 0.8
end function

' Returns { name, duration, incoming: { opacity, translation, scale, inner },
'           outgoing: { ... } }, each value a [start, end] pair.
' randomPick (0 – 4) chooses the effect for "random"; pass Rnd(5) - 1.
function TransitionPlan(name as String, seconds as Float, randomPick as Integer) as Object
    if name = "random"
        choices = ["fade", "slide", "push", "wipe", "zoom"]
        name = choices[randomPick mod choices.Count()]
    end if

    plan = { name: name, duration: seconds, incoming: stillSlot(), outgoing: stillSlot() }
    width = 1920

    if name = "fade"
        plan.incoming.opacity = [0.0, 1.0]
    else if name = "slide"
        ' New photo slides in from the right, over the old one.
        plan.incoming.translation = [[width, 0], [0, 0]]
    else if name = "push"
        ' New photo pushes the old one out to the left.
        plan.incoming.translation = [[width, 0], [0, 0]]
        plan.outgoing.translation = [[0, 0], [-width, 0]]
    else if name = "wipe"
        ' Revealed from left to right, picture standing still.
        plan.incoming.translation = [[-width, 0], [0, 0]]
        plan.incoming.inner = [[width, 0], [0, 0]]
    else if name = "zoom"
        ' New photo grows from slightly smaller while fading in.
        plan.incoming.opacity = [0.0, 1.0]
        plan.incoming.scale = [[0.85, 0.85], [1.0, 1.0]]
    else
        ' "none" (or unknown): instant cut.
        plan.name = "none"
        plan.duration = 0
    end if
    return plan
end function

' A slot that doesn't move: every value stays at its resting state.
function stillSlot() as Object
    return {
        opacity: [1.0, 1.0]
        translation: [[0, 0], [0, 0]]
        scale: [[1.0, 1.0], [1.0, 1.0]]
        inner: [[0, 0], [0, 0]]
    }
end function
