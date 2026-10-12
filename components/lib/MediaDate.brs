' ============================================================================
' MediaDate.brs — when was a photo or video taken?
'
'   Photos (JPEG): EXIF "date taken" via roImageMetadata, plus the EXIF
'                  orientation (phones store portrait photos sideways and
'                  set a flag saying how to rotate them).
'   Videos (MP4/MOV/M4V): the creation time in the "mvhd" atom. We only read
'                  a few bytes at a time with roByteArray.ReadFile(path,
'                  offset, length) — never the whole file.
'   Anything else, or when the above is missing: the file's modified time.
'
' EXIF dates are local "wall clock" time, while MP4 and file times are UTC.
' To sort photos and videos together correctly, UTC times are shifted to
' the TV's local time zone, so every date returned here is local time.
'
' These read the drive, so only call them from Task nodes.
' ============================================================================

' Returns { date: seconds since 1970 (or -1), source: "exif" | "mvhd" | "file",
'           rotation: 0 | 90 | 180 | 270 (clockwise, photos only) }
function MediaInfo(path as String, kind as String) as Object
    info = { date: -1, source: "file", rotation: 0 }
    ext = FileExtension(path)

    if kind = "photo" and (ext = "jpg" or ext = "jpeg")
        exif = readExif(path)
        info.rotation = exif.rotation
        if exif.date > 0
            info.date = exif.date
            info.source = "exif"
        end if
    else if ext = "mp4" or ext = "mov" or ext = "m4v"
        created = Mp4CreationTime(path)
        if created > 0
            info.date = created
            info.source = "mvhd"
        end if
    end if

    if info.date <= 0 then info.date = FileModifiedTime(path)
    if info.source <> "exif" then info.date = info.date + localOffsetSeconds()
    return info
end function

' ----------------------------------------------------------------------------
' Photos
' ----------------------------------------------------------------------------

function readExif(path as String) as Object
    result = { date: -1, rotation: 0 }
    meta = CreateObject("roImageMetadata")

    ' Some firmware wants a file:// URL, some the plain path; try both.
    data = invalid
    for each url in ["file://" + path, path]
        meta.SetUrl(url)
        data = meta.GetMetadata()
        if data <> invalid and data.DoesExist("datetime") then exit for
    end for
    if data = invalid then return result

    if data.DoesExist("datetime") and Type(data.datetime) = "roDateTime"
        result.date = data.datetime.AsSeconds()
    end if

    ' EXIF tag 274 (0x0112) = Orientation, in IFD 0.
    '   1 = normal, 3 = upside down, 6 = rotate 90° clockwise, 8 = rotate 270°
    orientation = meta.GetRawExifTag(0, 274)
    if orientation <> invalid
        if orientation = 3 then result.rotation = 180
        if orientation = 6 then result.rotation = 90
        if orientation = 8 then result.rotation = 270
    end if
    return result
end function

' ----------------------------------------------------------------------------
' Videos: MP4 / MOV "boxes"
'
' An MP4 file is a sequence of boxes: [size: 4 bytes][type: 4 chars][data].
' size = 1 means a 64-bit size follows the type; size = 0 means "to the end
' of the file". The "moov" atom contains "mvhd", whose creation_time is
' seconds since 1904-01-01 UTC. Numbers can exceed BrightScript's 32-bit
' Integer, so the arithmetic uses LongInteger (64-bit, the & suffix), which
' is exact (a Double can round large values when converted back).
' ----------------------------------------------------------------------------

' Seconds since 1970 (UTC), or -1 if not found.
function Mp4CreationTime(path as String) as Integer
    fileSize = fileSizeOf(path)
    if fileSize < 16 then return -1

    atom = nextBox(path, 0&, fileSize)
    guard = 0
    while atom <> invalid and guard < 500
        guard = guard + 1
        if atom.boxType = "moov"
            return findMvhd(path, atom.start + atom.header, atom.start + atom.size)
        end if
        atom = nextBox(path, atom.start + atom.size, fileSize)
    end while
    return -1
end function

' Looks for "mvhd" among the children of "moov".
function findMvhd(path as String, start as LongInteger, finish as LongInteger) as Integer
    atom = nextBox(path, start, finish)
    guard = 0
    while atom <> invalid and guard < 500
        guard = guard + 1
        if atom.boxType = "mvhd"
            bytes = readBytes(path, atom.start + atom.header, 12)
            if bytes = invalid then return -1
            ' byte 0 = version; version 1 uses 64-bit times
            if bytes[0] = 1
                created = be32(bytes, 4) * 4294967296& + be32(bytes, 8)
            else
                created = be32(bytes, 4)
            end if
            return mp4TimeToUnix(created)
        end if
        atom = nextBox(path, atom.start + atom.size, finish)
    end while
    return -1
end function

' Reads the atom header at offset. Returns { start, size, header, boxType }
' or invalid at the end / on bad data.
function nextBox(path as String, offset as LongInteger, limit as LongInteger) as Dynamic
    if offset + 8 > limit then return invalid
    length = 16
    if offset + 16 > limit then length = 8
    bytes = readBytes(path, offset, length)
    if bytes = invalid then return invalid

    size = be32(bytes, 0)
    header = 8
    if size = 1
        if length < 16 then return invalid
        size = be32(bytes, 8) * 4294967296& + be32(bytes, 12)
        header = 16
    else if size = 0
        size = limit - offset
    end if
    if size < header then return invalid

    boxType = Chr(bytes[4]) + Chr(bytes[5]) + Chr(bytes[6]) + Chr(bytes[7])
    return { start: offset, size: size, header: header, boxType: boxType }
end function

' ReadFile takes 32-bit offsets, so give up past ~2 GB (the caller then
' falls back to the file date).
function readBytes(path as String, offset as LongInteger, length as Integer) as Dynamic
    if offset + length > 2147483000& then return invalid
    bytes = CreateObject("roByteArray")
    if not bytes.ReadFile(path, toInteger(offset), length) then return invalid
    if bytes.Count() < length then return invalid
    return bytes
end function

' Big-endian unsigned 32-bit number at index i.
function be32(bytes as Object, i as Integer) as LongInteger
    return bytes[i] * 16777216& + bytes[i + 1] * 65536& + bytes[i + 2] * 256& + bytes[i + 3]
end function

function mp4TimeToUnix(seconds1904 as LongInteger) as Integer
    ' 2082844800 = seconds from 1904-01-01 to 1970-01-01.
    unix = seconds1904 - 2082844800&
    ' 0 / garbage (cameras with no clock) or beyond 2038: not usable.
    if unix < 31536000& or unix > 2147483000& then return -1
    return toInteger(unix)
end function

' LongInteger -> Integer, for values known to fit in 32 bits.
function toInteger(value as LongInteger) as Integer
    return value.ToStr().ToInt()
end function

' ----------------------------------------------------------------------------
' Files
' ----------------------------------------------------------------------------

' Difference between local time and UTC, in seconds (e.g. -14400 for EDT).
function localOffsetSeconds() as Integer
    if m.localOffset = invalid
        clock = CreateObject("roDateTime")
        utc = clock.AsSeconds()
        clock.ToLocalTime()
        m.localOffset = clock.AsSeconds() - utc
    end if
    return m.localOffset
end function

function FileModifiedTime(path as String) as Integer
    info = CreateObject("roFileSystem").Stat(path)
    if info = invalid or not info.DoesExist("mtime") then return 0
    if Type(info.mtime) = "roDateTime" then return info.mtime.AsSeconds()
    return info.mtime
end function

function fileSizeOf(path as String) as LongInteger
    info = CreateObject("roFileSystem").Stat(path)
    if info = invalid or not info.DoesExist("size") then return 0&
    return info.size + 0&
end function
