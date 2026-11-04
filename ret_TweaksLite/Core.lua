local addonName, ns = ...

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

ns.title = GetAddOnMetadata(addonName, "Title")
ns.version = GetAddOnMetadata(addonName, "Version")

-- Prints the version until the addon window exists.
SLASH_RETTWEAKSLITE1 = "/rettl"
SLASH_RETTWEAKSLITE2 = "/rettweakslite"
SlashCmdList.RETTWEAKSLITE = function()
    print(ns.title .. " " .. ns.version)
end
