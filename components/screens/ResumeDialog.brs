' ============================================================================
' ResumeDialog.brs
' ============================================================================

sub init()
    m.options = m.top.FindNode("options")
    m.options.ObserveField("itemSelected", "onOptionSelected")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")
end sub

sub buildOptions()
    content = CreateObject("roSGNode", "ContentNode")
    content.CreateChild("ContentNode").title = m.top.resumeText
    content.CreateChild("ContentNode").title = "Start over"
    m.options.content = content
end sub

sub onFocusedChildChange()
    if m.top.HasFocus() then m.options.SetFocus(true)
end sub

sub onOptionSelected()
    fields = m.top.playerFields
    if m.options.itemSelected = 0
        fields.startPart = m.top.resumePart
        fields.startPos = m.top.resumePos
    else
        fields.startPart = 0
        fields.startPos = 0
    end if
    m.top.navigate = { screen: "PlayerScreen", fields: fields, replace: true }
end sub
