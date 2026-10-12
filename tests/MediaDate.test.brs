' @include components/lib/MediaDate.brs
' @include components/lib/MediaTypes.brs
' @double tests/doubles/Files.brs
' @fixture tests/fixtures/moov_at_end.mp4
' @fixture tests/fixtures/faststart.mp4
' @fixture tests/fixtures/quicktime.mov
' @fixture tests/fixtures/no_date.mp4

sub Main()
    loadFixtures()

    ' Expected values: see tests/fixtures/README.md
    assertEqual(Mp4CreationTime("moov_at_end.mp4"), 1626100200, "moov after the data (2021-07-12 14:30 UTC)")
    assertEqual(Mp4CreationTime("faststart.mp4"), 1551513600, "moov first (2019-03-02 08:00 UTC)")
    assertEqual(Mp4CreationTime("quicktime.mov"), 1735157700, "QuickTime .mov (2024-12-25 20:15 UTC)")
    assertEqual(Mp4CreationTime("no_date.mp4"), -1, "no creation time")

    assertEqual(MediaInfo("quicktime.mov", "video").source, "mvhd", "video date comes from mvhd")
    assertEqual(MediaInfo("no_date.mp4", "video"), { date: 123456, source: "file", rotation: 0 }, "falls back to the file date")

    assertEqual(mp4TimeToUnix(0&), -1, "zero creation time is ignored")
    assertEqual(be32([255, 255, 255, 255], 0), 4294967295&, "unsigned 32-bit")
    finishTests()
end sub
