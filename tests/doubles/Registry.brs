' ============================================================================
' Registry.brs (test double) — replaces the parts of lib/Progress.brs and
' lib/Settings.brs that need a real Roku: the registry, MD5 and the clock.
'
'   GetGlobalAA().registry  fake registry: section name -> { key: value }
'   GetGlobalAA().clock     seconds returned by nowSeconds(); increases by
'                           1 on every call so "most recent" is well defined
' ============================================================================

function progressSection() as Object
    return fakeSection("progress")
end function

function settingsSection() as Object
    return fakeSection("settings")
end function

' An object with the same methods as roRegistrySection, backed by an
' associative array.
function fakeSection(name as String) as Object
    g = GetGlobalAA()
    if g.registry = invalid then g.registry = {}
    if not g.registry.DoesExist(name) then g.registry[name] = {}
    return {
        data: g.registry[name]
        Exists: function(key) : return m.data.DoesExist(key) : end function
        Read: function(key) : return m.data[key] : end function
        Write: function(key, value) : m.data[key] = value : end function
        Delete: function(key) : m.data.Delete(key) : end function
        GetKeyList: function() : return m.data.Keys() : end function
        Flush: function() : return true : end function
    }
end function

' The contents of a fake section (key -> value).
function fakeRegistry(name as String) as Object
    return fakeSection(name).data
end function

' Not MD5: a small deterministic hash so different texts get different keys.
function md5Hex(text as String) as String
    hash = 5381
    for i = 1 to Len(text)
        hash = (hash * 31 + Asc(Mid(text, i, 1))) mod 16777213
    end for
    digits = "0123456789abcdef"
    hex = ""
    for i = 1 to 8
        hex = Mid(digits, (hash mod 16) + 1, 1) + hex
        hash = hash \ 16
    end for
    return hex + hex + hex + hex
end function

function nowSeconds() as Integer
    g = GetGlobalAA()
    if g.clock = invalid then g.clock = 1000000
    g.clock = g.clock + 1
    return g.clock
end function

' Starts a test with an empty registry.
sub resetRegistry()
    GetGlobalAA().registry = {}
end sub
