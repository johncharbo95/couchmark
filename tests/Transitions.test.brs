' @include components/lib/Transitions.brs

sub Main()
    still = stillSlot()

    assertEqual(TransitionSeconds("slow"), 1.5, "slow")
    assertEqual(TransitionSeconds("normal"), 0.8, "normal")
    assertEqual(TransitionSeconds("fast"), 0.4, "fast")
    assertEqual(TransitionSeconds("bogus"), 0.8, "unknown speed: normal")

    plan = TransitionPlan("none", 0.8, 0)
    assertEqual(plan.duration, 0, "none is instant")

    plan = TransitionPlan("bogus", 0.8, 0)
    assertEqual(plan.name, "none", "unknown transition: cut")

    plan = TransitionPlan("fade", 0.8, 0)
    assertEqual(plan.incoming.opacity, [0.0, 1.0], "fade: incoming fades in")
    assertEqual(plan.outgoing, still, "fade: outgoing stays (no black between)")

    plan = TransitionPlan("slide", 0.8, 0)
    assertEqual(plan.incoming.translation, [[1920, 0], [0, 0]], "slide: from the right")
    assertEqual(plan.outgoing, still, "slide: outgoing stays")

    plan = TransitionPlan("push", 0.8, 0)
    assertEqual(plan.outgoing.translation, [[0, 0], [-1920, 0]], "push: outgoing leaves left")

    plan = TransitionPlan("wipe", 0.8, 0)
    start = plan.incoming.translation[0][0] + plan.incoming.inner[0][0]
    finish = plan.incoming.translation[1][0] + plan.incoming.inner[1][0]
    assertEqual([start, finish], [0, 0], "wipe: picture stays put while the window moves")
    assertEqual(plan.incoming.translation[0], [-1920, 0], "wipe: window starts off-screen left")

    plan = TransitionPlan("zoom", 1.5, 0)
    assertEqual(plan.incoming.scale[1], [1.0, 1.0], "zoom: ends at normal size")
    assertEqual(plan.duration, 1.5, "duration passed through")

    picked = {}
    for i = 0 to 4
        picked[TransitionPlan("random", 0.8, i).name] = true
    end for
    assertEqual(picked.Count(), 5, "random covers all five effects")
    assertTrue(not picked.DoesExist("none"), "random never picks none")

    assertEqual(TransitionNames().Count(), 7, "seven choices in settings")
    finishTests()
end sub
