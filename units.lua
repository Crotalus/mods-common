local Select = import('/mods/common/select.lua')
local Score = import('/mods/common/score.lua')

local current_army = nil
local units = {}
local assisting ={}
local cached = {}

local last_reset = 0
local last_cached = 0

function UpdateUnits()
    Select.Hidden(function()
        units = {}
        UISelectionByCategory("ALLUNITS", false, false, false, false)
        for _, u in GetSelectedUnits() or {} do
            units[u:GetEntityId()] = u
            local focus = u:GetFocus()
            if focus and not focus:IsDead() then
                local focus_id = focus:GetEntityId()
                units[focus_id] = focus
            end
        end
    end)
end

local function UpdateCache()
    cached = {}
    assisting = {}

    for id, u in units do
        if not u:IsDead() then
            table.insert(cached, u)

            local focus = u:GetFocus()
            if focus and not focus:IsDead() then
                local focus_id = focus:GetEntityId()
                if not assisting[focus_id] then
                    assisting[focus_id] = {engineers={}, build_rate=0}
                end
                table.insert(assisting[focus_id]['engineers'], u)
                assisting[focus_id]['build_rate'] = assisting[focus_id]['build_rate'] + u:GetBuildRate()
            end
        end
    end
end

local function CheckCache()
    local current_tick = GameTick()

    if current_tick - 10 >= last_cached then
        local army = GetFocusArmy()
        local score = Score.Get()

        if army ~= current_army then
            last_cached = 0
            last_reset = 0
            current_army = army
        end

        if current_tick - 50 > last_reset and score[army].general.currentunits.count > table.getsize(units) then
            UpdateUnits()
            last_reset = current_tick
        end

        UpdateCache()
        last_cached = current_tick
    end
end

function Data(unit)
    local bp = unit:GetBlueprint()
    local data = {
        is_idle=unit:IsIdle(),
        econ=unit:GetEconData()
    }

    if bp.Economy.ProductionPerSecondMass > 0 and data['econ']['massProduced'] > bp.Economy.ProductionPerSecondMass then
        data['bonus'] = data['econ']['massProduced'] / bp.Economy.ProductionPerSecondMass
    else
        data['bonus'] = 1
    end

    if not data['is_idle'] then
        local focus = unit:GetFocus()
        data['assisters']  = 0
        data['build_rate'] = bp.Economy.BuildRate

        if focus then
            local focus_id = focus:GetEntityId();

            if assisting[focus_id] then
                data['assisting'] = table.getsize(assisting[focus_id]['engineers'])
                data['build_rate'] = data['build_rate'] + assisting[focus_id]['build_rate']
            end
        end
    end

    return data
end

function Get(filter)
    CheckCache()
    cached = ValidateUnitsList(cached)

    if filter then
        return EntityCategoryFilterDown(filter, cached) or {}
    else
        return cached
    end
end