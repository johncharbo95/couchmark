' ============================================================================
' Assert.brs — tiny assertion helpers for the off-device tests
'
'   assertEqual(actual, expected, "what is being checked")
'   assertNear(actual, expected, 0.001, "...")   for floats
'   assertTrue(condition, "...")
'   finishTests()                                 call at the end of Main()
' Values are compared via FormatJson, so arrays and associative arrays are
' compared by content.
' ============================================================================

sub assertEqual(actual as Dynamic, expected as Dynamic, label as String)
    countCheck()
    if FormatJson(actual) <> FormatJson(expected)
        fail(label + ": expected " + FormatJson(expected) + ", got " + FormatJson(actual))
    end if
end sub

sub assertNear(actual as Dynamic, expected as Dynamic, tolerance as Float, label as String)
    countCheck()
    if Abs(actual - expected) > tolerance
        fail(label + ": expected about " + Str(expected) + ", got " + Str(actual))
    end if
end sub

sub assertTrue(condition as Boolean, label as String)
    countCheck()
    if not condition then fail(label)
end sub

sub finishTests()
    g = GetGlobalAA()
    print "RESULT: "; g.testChecks; " checks, "; g.testFailures; " failed"
end sub

sub countCheck()
    g = GetGlobalAA()
    if g.testChecks = invalid
        g.testChecks = 0
        g.testFailures = 0
    end if
    g.testChecks = g.testChecks + 1
end sub

sub fail(message as String)
    g = GetGlobalAA()
    g.testFailures = g.testFailures + 1
    print "FAIL: "; message
end sub
