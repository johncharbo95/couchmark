' @include components/lib/BuildInfo.brs

sub Main()
    info = { commit: "9ad7f63", message: "Player: exact 30 s skips", branch: "dev", dirty: false, builtAt: "2026-10-12 11:42" }
    assertEqual(BuildInfoText(info), "DEV  9ad7f63  Player: exact 30 s skips  ·  dev  ·  built 2026-10-12 11:42", "full line")

    info.dirty = true
    assertTrue(Instr(1, BuildInfoText(info), "(+ uncommitted changes)") > 0, "uncommitted changes are flagged")

    assertEqual(BuildInfoText({ commit: "abc1234", message: "Hi" }), "DEV  abc1234  Hi", "only commit and message")
    assertEqual(BuildInfoText(invalid), "", "release build: nothing")
    assertEqual(BuildInfoText({}), "", "incomplete: nothing")
    assertEqual(BuildInfoText("oops"), "", "not an object: nothing")
    finishTests()
end sub
