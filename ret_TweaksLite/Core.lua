local addonName, ns = ...

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

ns.title = GetAddOnMetadata(addonName, "Title")
ns.notes = GetAddOnMetadata(addonName, "Notes")
ns.version = GetAddOnMetadata(addonName, "Version")

--------------------------------------------------------------------------------
-- Saved settings
--------------------------------------------------------------------------------

local SCHEMA_VERSION = 1

-- migrations[n] upgrades saved data from schema version n - 1 to n.
-- Version 0 means data without a schema version: a fresh install
-- or an older, unrelated version of the addon.
local migrations = {
    [1] = function(data)
        wipe(data)
    end,
}

local db

local function LoadDatabase()
    if type(ret_TweaksLiteDB) ~= "table" then
        ret_TweaksLiteDB = {}
    end
    local data = ret_TweaksLiteDB
    for version = (data.schemaVersion or 0) + 1, SCHEMA_VERSION do
        migrations[version](data)
        data.schemaVersion = version
    end
    if type(data.modules) ~= "table" then
        data.modules = {}
    end
    if type(data.collapsed) ~= "table" then
        data.collapsed = {}
    end
    return data
end

local function GetModuleData(key)
    local data = db.modules[key]
    if type(data) ~= "table" then
        data = {}
        db.modules[key] = data
    end
    return data
end

--------------------------------------------------------------------------------
-- Modules
--------------------------------------------------------------------------------

ns.moduleList = {}

local modules = {}
local running = {}
-- Tweak values as they were when the UI loaded: loadedTweaks[moduleKey][tweakKey].
local loadedTweaks = {}

-- One broken module or tweak must not stop the others: errors go to the
-- error handler (BugSack) and the caller carries on.
local function SafeCall(func, ...)
    local args = { n = select("#", ...), ... }
    xpcall(function()
        func(unpack(args, 1, args.n))
    end, geterrorhandler())
end

-- A module is a table with:
--   key         unique id, also the key in saved settings; never rename
--   category    group in the window's list, e.g. "Interface"
--   title       name in the window's list
--   description tooltip text of the module's checkbox
--   tweaks      list of tweaks shown on the module's page while it runs
--   Start       optional function(module), called once after login if enabled
--
-- A tweak is a table with:
--   key         unique within the module, also the key in saved settings
--   title       name next to the tweak's checkbox
--   description tooltip text of the tweak's checkbox
--   parent      optional key of an earlier tweak in the same module. The child
--               is shown only while the parent is checked and works only while
--               the parent works.
--   Apply       function(active); takes effect at once, so it must be able to
--               undo itself. Called whenever the tweak starts or stops working,
--               including with true after login.
function ns.RegisterModule(module)
    assert(type(module.key) == "string", "module.key is required")
    assert(not modules[module.key], "module already registered: " .. module.key)
    assert(type(module.category) == "string", "module.category is required")
    assert(type(module.title) == "string", "module.title is required")
    assert(type(module.description) == "string", "module.description is required")
    assert(type(module.tweaks) == "table", "module.tweaks is required")
    local seen = {}
    for _, tweak in ipairs(module.tweaks) do
        assert(type(tweak.key) == "string", "tweak.key is required")
        assert(not seen[tweak.key], "tweak already registered: " .. tweak.key)
        assert(type(tweak.title) == "string", "tweak.title is required")
        assert(type(tweak.description) == "string", "tweak.description is required")
        assert(type(tweak.Apply) == "function", "tweak.Apply is required")
        assert(tweak.parent == nil or seen[tweak.parent], "tweak.parent must be an earlier tweak")
        seen[tweak.key] = tweak
    end
    module.tweaksByKey = seen

    modules[module.key] = module
    table.insert(ns.moduleList, module)
end

-- What the player chose. Takes effect after /reload.
function ns.IsEnabled(key)
    return GetModuleData(key).enabled == true
end

function ns.SetEnabled(key, enabled)
    GetModuleData(key).enabled = enabled
end

local function GetTweakData(moduleKey)
    local data = GetModuleData(moduleKey)
    if type(data.tweaks) ~= "table" then
        data.tweaks = {}
    end
    return data.tweaks
end

-- Tweaks are off by default and apply at once, without /reload.
-- "Enabled" is the checkbox; "active" means the tweak actually works:
-- it is enabled and so is every parent above it.
function ns.IsTweakEnabled(moduleKey, tweakKey)
    return GetTweakData(moduleKey)[tweakKey] == true
end

local function IsTweakActive(module, tweak)
    if not ns.IsTweakEnabled(module.key, tweak.key) then
        return false
    end
    if tweak.parent then
        return IsTweakActive(module, module.tweaksByKey[tweak.parent])
    end
    return true
end

-- Turning a parent on or off can start or stop its children too. Tweaks that
-- stop are told first, children before parents; then the ones that start,
-- parents before children.
function ns.SetTweakEnabled(moduleKey, tweak, enabled)
    local module = modules[moduleKey]
    local wasActive = {}
    for index, other in ipairs(module.tweaks) do
        wasActive[index] = IsTweakActive(module, other)
    end

    GetTweakData(moduleKey)[tweak.key] = enabled
    if not ns.IsRunning(moduleKey) then
        return
    end

    for index = #module.tweaks, 1, -1 do
        local other = module.tweaks[index]
        if wasActive[index] and not IsTweakActive(module, other) then
            SafeCall(other.Apply, false)
        end
    end
    for index, other in ipairs(module.tweaks) do
        if not wasActive[index] and IsTweakActive(module, other) then
            SafeCall(other.Apply, true)
        end
    end
end

-- What runs in this session: the choice as it was when the UI loaded.
function ns.IsRunning(key)
    return running[key] == true
end

function ns.IsPending(key)
    return ns.IsEnabled(key) ~= ns.IsRunning(key)
end

function ns.HasPendingChanges()
    for _, module in ipairs(ns.moduleList) do
        if ns.IsPending(module.key) then
            return true
        end
    end
    return false
end

-- Undo: everything the player changed since the UI loaded can be set back.
-- For a module, "changed" is the same as pending.
function ns.UndoModule(key)
    ns.SetEnabled(key, ns.IsRunning(key))
end

function ns.IsTweakChanged(moduleKey, tweakKey)
    return ns.IsTweakEnabled(moduleKey, tweakKey) ~= loadedTweaks[moduleKey][tweakKey]
end

function ns.UndoTweak(moduleKey, tweak)
    ns.SetTweakEnabled(moduleKey, tweak, loadedTweaks[moduleKey][tweak.key])
end

local function RememberLoadedTweaks()
    for _, module in ipairs(ns.moduleList) do
        local values = {}
        for _, tweak in ipairs(module.tweaks) do
            values[tweak.key] = ns.IsTweakEnabled(module.key, tweak.key)
        end
        loadedTweaks[module.key] = values
    end
end

--------------------------------------------------------------------------------
-- Window state
--------------------------------------------------------------------------------

-- Groups the player collapsed in the window's list.
function ns.IsCollapsed(category)
    return db.collapsed[category] == true
end

function ns.SetCollapsed(category, collapsed)
    db.collapsed[category] = collapsed or nil
end

local function StartModules()
    for _, module in ipairs(ns.moduleList) do
        if ns.IsEnabled(module.key) then
            running[module.key] = true
            if module.Start then
                SafeCall(module.Start, module)
            end
            for _, tweak in ipairs(module.tweaks) do
                if IsTweakActive(module, tweak) then
                    SafeCall(tweak.Apply, true)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Startup
--------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        db = LoadDatabase()
        RememberLoadedTweaks()
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        StartModules()
    end
end)
