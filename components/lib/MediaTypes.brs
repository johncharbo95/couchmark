' ============================================================================
' MediaTypes.brs — which files Couchmark shows, and how to play them
' ============================================================================

' Returns "video", "photo", or "" (unsupported / ignored) for a file name.
function MediaKind(fileName as String) as String
    if IsJunkName(fileName) then return ""

    ext = FileExtension(fileName)
    videos = { mp4: true, m4v: true, mov: true, mkv: true, ts: true, webm: true }
    photos = { jpg: true, jpeg: true, png: true, gif: true, bmp: true }

    if videos.DoesExist(ext) then return "video"
    if photos.DoesExist(ext) then return "photo"
    return ""
end function

' Hidden and system files/folders that should never be listed:
' ".DS_Store", "._IMG_0001.jpg", ".Trashes", "Thumbs.db", "$RECYCLE.BIN", ...
function IsJunkName(name as String) as Boolean
    if Left(name, 1) = "." or Left(name, 1) = "$" then return true
    junk = { "thumbs.db": true, "desktop.ini": true, "system volume information": true }
    return junk.DoesExist(LCase(name))
end function

' "Movie.Part.1.MKV" -> "mkv"
function FileExtension(fileName as String) as String
    dot = lastIndexOf(fileName, ".")
    if dot = 0 then return ""
    return LCase(Mid(fileName, dot + 1))
end function

' "Movie.Part.1.mkv" -> "Movie.Part.1"
function StripExtension(fileName as String) as String
    dot = lastIndexOf(fileName, ".")
    if dot <= 1 then return fileName
    return Left(fileName, dot - 1)
end function

' The Video node's streamFormat hint. Empty = let Roku detect it.
function StreamFormatFor(fileName as String) as String
    ext = FileExtension(fileName)
    if ext = "mp4" or ext = "m4v" or ext = "mov" then return "mp4"
    if ext = "mkv" then return "mkv"
    return ""
end function

' 1-based position of the last occurrence of needle, or 0 if not found.
function lastIndexOf(text as String, needle as String) as Integer
    position = 0
    found = Instr(1, text, needle)
    while found > 0
        position = found
        found = Instr(found + 1, text, needle)
    end while
    return position
end function

' A friendlier episode name for display (saved progress uses the real file
' name, so this is cosmetic):
'   "How.I.Met.Your.Mother.S04E08.Woooo.720p.HDTV.x264" -> "S04E08 · Woooo"
'   "S01E02 Diversity Day"                               -> "S01E02 · Diversity Day"
'   "The Office - 2x05 - Halloween"                      -> "S02E05 · Halloween"
'   "Pilot"                                              -> "Pilot"
' code = "S04E08" style code from the file name, or "".
function CleanEpisodeTitle(title as String, code as String) as String
    text = title
    ' Scene-style names use dots or underscores instead of spaces.
    if Instr(1, text, " ") = 0 then text = text.Replace(".", " ").Replace("_", " ")
    if code = "" then return text.Trim()

    ' Keep only what follows the episode code ("Show S04E08 Woooo" -> "Woooo").
    beforeCode = CreateObject("roRegex", "^.*?(s\d{1,3}[ ._-]?e\d{1,4}|\b\d{1,2}x\d{1,4}\b)[ ._-]*", "i")
    rest = beforeCode.Replace(text, "")

    ' Drop release tags and everything after them ("720p HDTV x264").
    releaseTags = CreateObject("roRegex", "\s*\b(480p|576p|720p|1080p|2160p|4k|hdtv|webrip|web-dl|web|bluray|brrip|dvdrip|x264|x265|h264|h265|hevc|xvid|aac|ac3|proper|repack)\b.*$", "i")
    rest = releaseTags.Replace(rest, "").Trim()

    ' Separators left at either end, e.g. "- Halloween -".
    while Len(rest) > 0 and Instr(1, "-_.", Left(rest, 1)) > 0
        rest = Mid(rest, 2).Trim()
    end while
    while Len(rest) > 0 and Instr(1, "-_.", Right(rest, 1)) > 0
        rest = Left(rest, Len(rest) - 1).Trim()
    end while

    if rest = "" then return code
    return code + "  ·  " + rest
end function
