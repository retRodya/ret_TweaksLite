local _, ns = ...

local WIDTH, HEIGHT = 560, 400
local LIST_WIDTH = 170
local ENTRY_HEIGHT = 22
local TWEAK_HEIGHT = 28
local TWEAK_INDENT = 24

-- Offsets of ButtonFrameTemplate's inset: title bar on top, button bar at the bottom.
local INSET_LEFT, INSET_RIGHT, INSET_TOP, INSET_BOTTOM = 4, -6, -24, 26

-- In the list on the left: where the +/- toggle, the labels and the module checkboxes sit.
local TOGGLE_X, LABEL_X, MODULE_X = 2, 24, 22

-- Retail's AddOns list uses the minimal checkbox; clients without it get the classic one.
local CHECKBOX_TEMPLATE = "UICheckButtonTemplate"
if C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo("MinimalCheckboxTemplate") then
    CHECKBOX_TEMPLATE = "MinimalCheckboxTemplate"
end

local window
local entries = {} -- list on the left, in display order
local pages = {} -- one page per entry
local selectedEntry

local function ShowTooltip(owner, title, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, HIGHLIGHT_FONT_COLOR:GetRGB())
    local r, g, b = NORMAL_FONT_COLOR:GetRGB()
    GameTooltip:AddLine(text, r, g, b, true)
    GameTooltip:Show()
end

local function PlayCheckboxSound(checked)
    PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
end

-- Shown next to anything the player changed since the UI loaded,
-- so all changes are visible at a glance before the next reload.
local function CreateUndoButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(16, 16)
    button:Hide()

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetAtlas("common-icon-undo")

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetAtlas("common-icon-undo")
    highlight:SetBlendMode("ADD")

    button:SetScript("OnEnter", function(self)
        ShowTooltip(self, "Undo change", "Restores the state from the last UI reload.")
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    return button
end

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- Same look as the category list of the game's Settings panel.
local function UpdateEntry(entry)
    if entry == selectedEntry then
        entry.background:SetAtlas("Options_List_Active")
        entry.background:Show()
    elseif entry:IsMouseOver() then
        entry.background:SetAtlas("Options_List_Hover")
        entry.background:Show()
    else
        entry.background:Hide()
    end
    if entry.Update then
        entry:Update()
    end
end

local function Refresh()
    for _, entry in ipairs(entries) do
        UpdateEntry(entry)
    end
    for _, page in ipairs(pages) do
        if page.Update then
            page:Update()
        end
    end
    window.reloadButton:SetShown(ns.HasPendingChanges())
end

local function SelectEntry(entry)
    selectedEntry = entry
    for _, other in ipairs(entries) do
        UpdateEntry(other)
        other.page:SetShown(other == entry)
    end
end

-- Modules of a collapsed group are hidden; the rest move up.
local function LayoutList()
    local y = -4
    for _, entry in ipairs(entries) do
        local visible = not (entry.module and ns.IsCollapsed(entry.category))
        entry:SetShown(visible)
        if visible then
            entry:ClearAllPoints()
            entry:SetPoint("TOPLEFT", 4, y)
            entry:SetPoint("TOPRIGHT", -4, y)
            y = y - ENTRY_HEIGHT
        end
    end
end

--------------------------------------------------------------------------------
-- Pages
--------------------------------------------------------------------------------

local function CreatePage(parent, titleText)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page:Hide()

    local title = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetPoint("TOPRIGHT", -16, -16)
    title:SetJustifyH("LEFT")
    title:SetText(titleText)
    page.title = title

    table.insert(pages, page)
    return page
end

-- Welcome page. Its content comes later.
local function CreateGeneralPage(parent)
    local page = CreatePage(parent, ns.title)

    local notes = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    notes:SetPoint("TOPLEFT", page.title, "BOTTOMLEFT", 0, -8)
    notes:SetPoint("TOPRIGHT", page.title, "BOTTOMRIGHT", 0, -8)
    notes:SetJustifyH("LEFT")
    notes:SetText(ns.notes)

    return page
end

-- Overview of a group: enabled modules in white, disabled ones in grey.
local function CreateGroupPage(parent, category, modules)
    local page = CreatePage(parent, category)

    local names = {}
    local previous = page.title
    for index, module in ipairs(modules) do
        local name = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, index == 1 and -12 or -6)
        name:SetText(module.title)
        name.module = module
        table.insert(names, name)
        previous = name
    end

    function page:Update()
        for _, name in ipairs(names) do
            name:SetFontObject(ns.IsEnabled(name.module.key) and "GameFontHighlight" or "GameFontDisable")
        end
    end

    return page
end

local function CreateTweakRow(parent, module, tweak)
    local checkbox = CreateFrame("CheckButton", nil, parent, CHECKBOX_TEMPLATE)
    checkbox:SetSize(24, 24)

    local label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText(tweak.title)
    -- Clicking the name toggles the checkbox too.
    checkbox:SetHitRectInsets(0, -(label:GetStringWidth() + 4), 0, 0)

    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        PlayCheckboxSound(checked)
        ns.SetTweakEnabled(module.key, tweak, checked)
        Refresh()
    end)
    checkbox:SetScript("OnEnter", function(self)
        ShowTooltip(self, tweak.title, tweak.description)
    end)
    checkbox:SetScript("OnLeave", GameTooltip_Hide)

    -- A child of the checkbox, so it hides together with a hidden child tweak.
    local undo = CreateUndoButton(checkbox)
    undo:SetPoint("LEFT", label, "RIGHT", 6, 0)
    undo:SetScript("OnClick", function()
        ns.UndoTweak(module.key, tweak)
        Refresh()
    end)

    return {
        tweak = tweak,
        checkbox = checkbox,
        Update = function()
            checkbox:SetChecked(ns.IsTweakEnabled(module.key, tweak.key))
            undo:SetShown(ns.IsTweakChanged(module.key, tweak.key))
        end,
    }
end

-- A child tweak sits under its parent, indented, and only while the parent is
-- checked; the rows below move up when it is hidden.
local function LayoutTweakRows(module, rows)
    local depth = {}
    local y = 0
    for _, row in ipairs(rows) do
        local tweak = row.tweak
        local parentDepth = tweak.parent and depth[tweak.parent]
        local visible = tweak.parent == nil
            or (parentDepth ~= nil and ns.IsTweakEnabled(module.key, tweak.parent))
        row.checkbox:SetShown(visible)
        if visible then
            depth[tweak.key] = parentDepth and parentDepth + 1 or 0
            row.checkbox:ClearAllPoints()
            row.checkbox:SetPoint("TOPLEFT", depth[tweak.key] * TWEAK_INDENT, y)
            y = y - TWEAK_HEIGHT
        end
    end
end

-- The page shows the module's tweaks only while it runs. Otherwise it tells
-- the player what to do next.
local function CreateModulePage(parent, module)
    local page = CreatePage(parent, module.title)

    local message = page:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    message:SetPoint("LEFT", 24, 0)
    message:SetPoint("RIGHT", -24, 0)
    message:SetJustifyH("CENTER")

    local tweaks = CreateFrame("Frame", nil, page)
    tweaks:SetPoint("TOPLEFT", page.title, "BOTTOMLEFT", 0, -12)
    tweaks:SetPoint("BOTTOMRIGHT", -16, 16)

    local rows = {}
    for _, tweak in ipairs(module.tweaks) do
        table.insert(rows, CreateTweakRow(tweaks, module, tweak))
    end

    function page:Update()
        local enabled, running = ns.IsEnabled(module.key), ns.IsRunning(module.key)
        local text
        if enabled and not running then
            text = "Type /reload to enable " .. module.title .. "."
        elseif running and not enabled then
            text = "Type /reload to disable " .. module.title .. "."
        elseif not enabled then
            text = "Check the box to enable " .. module.title .. "."
        end

        message:SetText(text or "")
        message:SetShown(text ~= nil)
        tweaks:SetShown(text == nil)
        for _, row in ipairs(rows) do
            row.Update()
        end
        LayoutTweakRows(module, rows)
    end

    return page
end

--------------------------------------------------------------------------------
-- List on the left
--------------------------------------------------------------------------------

local function CreateEntry(parent, page, text, fontObject)
    local entry = CreateFrame("Button", nil, parent)
    entry:SetHeight(ENTRY_HEIGHT)
    entry.page = page

    entry.background = entry:CreateTexture(nil, "BACKGROUND")
    entry.background:SetAllPoints()
    entry.background:Hide()

    entry.label = entry:CreateFontString(nil, "ARTWORK", fontObject)
    entry.label:SetPoint("LEFT", LABEL_X, 0)
    entry.label:SetText(text)

    entry:SetScript("OnEnter", UpdateEntry)
    entry:SetScript("OnLeave", UpdateEntry)
    entry:SetScript("OnClick", SelectEntry)

    table.insert(entries, entry)
    return entry
end

-- Controls inside an entry: moving onto them makes the entry get OnLeave
-- while the cursor is still over it, so they refresh the entry's hover too.
local function KeepEntryHover(control, entry)
    control:HookScript("OnEnter", function()
        UpdateEntry(entry)
    end)
    control:HookScript("OnLeave", function()
        UpdateEntry(entry)
    end)
end

-- Navigation only: General and the groups are gold, modules are white.
local function CreateGeneralEntry(parent, page)
    return CreateEntry(parent, page, "General", "GameFontNormal")
end

local function CreateGroupEntry(parent, category, page)
    local entry = CreateEntry(parent, page, category, "GameFontNormal")
    entry.category = category

    local toggle = CreateFrame("Button", nil, entry)
    toggle:SetSize(20, 20)
    toggle:SetPoint("LEFT", TOGGLE_X, 0)
    toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    toggle:SetScript("OnClick", function()
        local collapsed = not ns.IsCollapsed(category)
        ns.SetCollapsed(category, collapsed)
        if collapsed and selectedEntry.module and selectedEntry.category == category then
            SelectEntry(entry)
        end
        LayoutList()
        Refresh()
    end)
    KeepEntryHover(toggle, entry)

    function entry:Update()
        local state = ns.IsCollapsed(category) and "Plus" or "Minus"
        toggle:SetNormalTexture("Interface\\Buttons\\UI-" .. state .. "Button-UP")
        toggle:SetPushedTexture("Interface\\Buttons\\UI-" .. state .. "Button-DOWN")
    end

    return entry
end

local function CreateModuleEntry(parent, module, page)
    local entry = CreateEntry(parent, page, module.title, "GameFontHighlight")
    entry.category = module.category
    entry.module = module

    -- The module's on/off switch sits left of its name.
    local checkbox = CreateFrame("CheckButton", nil, entry, CHECKBOX_TEMPLATE)
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("LEFT", MODULE_X, 0)
    entry.label:ClearAllPoints()
    entry.label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)

    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        PlayCheckboxSound(checked)
        ns.SetEnabled(module.key, checked)
        SelectEntry(entry)
        Refresh()
    end)
    checkbox:SetScript("OnEnter", function(self)
        ShowTooltip(self, module.title, module.description)
    end)
    checkbox:SetScript("OnLeave", GameTooltip_Hide)
    KeepEntryHover(checkbox, entry)

    local undo = CreateUndoButton(entry)
    undo:SetPoint("LEFT", entry.label, "RIGHT", 4, 0)
    undo:SetScript("OnClick", function()
        ns.UndoModule(module.key)
        Refresh()
    end)
    KeepEntryHover(undo, entry)

    function entry:Update()
        checkbox:SetChecked(ns.IsEnabled(module.key))
        undo:SetShown(ns.IsPending(module.key))
    end

    return entry
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

-- Groups in the order their first module loads (file order in the .toc),
-- so a group like Developer can stay at the bottom; modules in a group by name.
local function GetGroups()
    local categories, modulesByCategory = {}, {}
    for _, module in ipairs(ns.moduleList) do
        local list = modulesByCategory[module.category]
        if not list then
            list = {}
            modulesByCategory[module.category] = list
            table.insert(categories, module.category)
        end
        table.insert(list, module)
    end
    for _, list in pairs(modulesByCategory) do
        table.sort(list, function(a, b)
            return a.title < b.title
        end)
    end
    return categories, modulesByCategory
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "RetTweaksLiteFrame", UIParent, "ButtonFrameTemplate")
    frame:Hide()
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER")
    -- Above the game's Settings panel (HIGH), which can open this window.
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    ButtonFrameTemplate_HidePortrait(frame)
    frame:SetTitle(ns.title)
    -- Escape closes the window.
    table.insert(UISpecialFrames, frame:GetName())

    local list = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    list:SetPoint("TOPLEFT", INSET_LEFT, INSET_TOP)
    list:SetPoint("BOTTOMLEFT", INSET_LEFT, INSET_BOTTOM)
    list:SetWidth(LIST_WIDTH)

    -- The template's own inset becomes the work area on the right.
    local workArea = frame.Inset
    workArea:ClearAllPoints()
    workArea:SetPoint("TOPLEFT", list, "TOPRIGHT", 2, 0)
    workArea:SetPoint("BOTTOMRIGHT", INSET_RIGHT, INSET_BOTTOM)

    local version = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    version:SetPoint("BOTTOMLEFT", 12, 9)
    version:SetText(ns.version)

    local reloadButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    reloadButton:SetSize(120, 22)
    reloadButton:SetPoint("BOTTOMRIGHT", INSET_RIGHT, 4)
    reloadButton:SetText(RELOADUI)
    reloadButton:SetScript("OnClick", function()
        ReloadUI()
    end)
    frame.reloadButton = reloadButton

    local general = CreateGeneralEntry(list, CreateGeneralPage(workArea))
    local categories, modulesByCategory = GetGroups()
    for _, category in ipairs(categories) do
        local modules = modulesByCategory[category]
        CreateGroupEntry(list, category, CreateGroupPage(workArea, category, modules))
        for _, module in ipairs(modules) do
            CreateModuleEntry(list, module, CreateModulePage(workArea, module))
        end
    end
    LayoutList()
    SelectEntry(general)

    frame:HookScript("OnShow", Refresh)
    return frame
end

function ns.ShowWindow()
    if not window then
        window = CreateWindow()
    end
    window:Show()
end

function ns.ToggleWindow()
    if window and window:IsShown() then
        window:Hide()
    else
        ns.ShowWindow()
    end
end
