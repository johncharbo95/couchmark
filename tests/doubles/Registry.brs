' ============================================================================
' Registry.brs (test double) — replaces the parts of lib/Progress.brs that
' need a real Roku: the registry, MD5 and the clock.
'
'   GetGlobalAA().registry  the fake registry's contents (key -> value)
'   GetGlobalAA().clock     seconds returned by nowSeconds(); increases by
'                           1 on every call so "most recent" is well defined
' ============================================================================

function progressSection() as Object
    g = GetGlobalAA()
    if g.registry = invalid then g.registry = {}
    return {
        Exists: function(key) : return GetGlobalAA().registry.DoesExist(key) : end function
        Read: function(key) : return GetGlobalAA().registry[key] : end function
        Write: function(key, value) : GetGlobalAA().registry[key] = value : end function
        Delete: function(key) : GetGlobalAA().registry.Delete(key) : end function
        GetKeyList: function() : return GetGlobalAA().registry.Keys() : end function
        Flush: function() : return true : end function
    }
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

' Starts every test with an empty registry.
sub resetRegistry()
    GetGlobalAA().registry = {}
end sub
