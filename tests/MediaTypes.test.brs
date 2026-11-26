' @include components/lib/MediaTypes.brs

sub Main()
    ' File kinds
    assertEqual(MediaKind("Movie.MKV"), "video", "upper-case extension")
    assertEqual(MediaKind("IMG_0001.jpeg"), "photo", "jpeg is a photo")
    assertEqual(MediaKind("IMG_0002.HEIC"), "", "HEIC is unsupported")
    assertEqual(MediaKind("._IMG_0001.jpg"), "", "macOS resource fork is junk")
    assertEqual(MediaKind("subs.srt"), "", "subtitles are ignored")

    ' Junk files
    assertTrue(IsJunkName(".DS_Store"), ".DS_Store is junk")
    assertTrue(IsJunkName("Thumbs.db"), "Thumbs.db is junk")
    assertTrue(IsJunkName("$RECYCLE.BIN"), "$RECYCLE.BIN is junk")
    assertTrue(not IsJunkName("Season 1"), "a normal folder is not junk")

    ' Names
    assertEqual(FileExtension("a.b.c.MP4"), "mp4", "extension after the last dot")
    assertEqual(FileExtension("README"), "", "no extension")
    assertEqual(StripExtension("Movie.Part.1.mkv"), "Movie.Part.1", "strip only the last extension")
    assertEqual(StreamFormatFor("x.mov"), "mp4", "mov plays as mp4")
    assertEqual(StreamFormatFor("x.ts"), "", "ts: let Roku detect")

    ' Episode titles (the "..." bug: dot-separated names)
    assertEqual(CleanEpisodeTitle("How.I.Met.Your.Mother.S04E08.Woooo.720p.HDTV.x264", "S04E08"), "S04E08  ·  Woooo", "scene-style name")
    assertEqual(CleanEpisodeTitle("How.I.Met.Your.Mother.S04E08.720p.HDTV.x264", "S04E08"), "S04E08", "scene-style name without a title")
    assertEqual(CleanEpisodeTitle("S01E02 Diversity Day", "S01E02"), "S01E02  ·  Diversity Day", "code first")
    assertEqual(CleanEpisodeTitle("The Office - 2x05 - Halloween", "S02E05"), "S02E05  ·  Halloween", "NxNN with dashes")
    assertEqual(CleanEpisodeTitle("Show_Name_s01e03_The_Title", "S01E03"), "S01E03  ·  The Title", "underscores")
    assertEqual(CleanEpisodeTitle("Pilot", ""), "Pilot", "no code: unchanged")
    assertEqual(CleanEpisodeTitle("Some.Special.Episode", ""), "Some Special Episode", "no code: dots become spaces")

    finishTests()
end sub
