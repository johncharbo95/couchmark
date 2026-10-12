' @include components/lib/Format.brs

sub Main()
    assertEqual(FormatTime(3734), "1:02:14", "hours")
    assertEqual(FormatTime(845), "14:05", "minutes")
    assertEqual(FormatTime(5), "0:05", "seconds")
    assertEqual(FormatTime(0), "0:00", "zero")
    assertEqual(FormatRemaining(3900), "1 h 5 min", "over an hour")
    assertEqual(FormatRemaining(1380), "23 min", "minutes")
    assertEqual(FormatRemaining(20), "1 min", "rounds up")
    assertEqual(FormatRemainingOfTotal(845, 2640), "-29:55 / 44:00", "time left / total")
    assertEqual(FormatRemainingOfTotal(3734, 7200), "-57:46 / 2:00:00", "movie length")
    assertEqual(FormatRemainingOfTotal(2700, 2640), "-0:00 / 44:00", "never negative")
    assertEqual(FormatRemainingOfTotal(10, 0), "", "length not known yet")
    assertEqual(pad2(7), "07", "pad")
    assertEqual(pad2(42), "42", "no pad")
    finishTests()
end sub
