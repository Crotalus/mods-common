local Select = import('/mods/common/select.lua')

local originalOnSelectionChanged = OnSelectionChanged
function OnSelectionChanged(oldSelection, newSelection, added, removed)
    if not Select.IsHidden() then
        originalOnSelectionChanged(oldSelection, newSelection, added, removed)
    end
end
