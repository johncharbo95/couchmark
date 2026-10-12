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
