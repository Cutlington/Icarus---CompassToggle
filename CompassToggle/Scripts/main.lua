-- CompassToggle (optimised)
-- F8: portable beacons   F9: dynamic mission beacons   F7: manual rescan
-- ESC: shows all markers while the pause menu is open, re-hides them when you close it
-- F11: manual restore if the menu was closed some other way
-- Hides/shows the markers on both the compass and the big map.

local TICK_MS = 1000   -- how often hidden markers are re-applied (raise for even less work)

local categories = {
    { key = Key.F8, actor = "BP_Portable_Beacon_C",        label = "Portable beacons",        hidden = false },
    { key = Key.F9, actor = "BP_Dynamic_Mission_Beacon_C", label = "Dynamic mission beacons", hidden = false },
}

------------------------------------------------------------
-- Helpers (defined once so the per-tick path creates no garbage)
------------------------------------------------------------
local function getProp(obj, name) return obj[name] end

local function tryGet(obj, name)
    local ok, v = pcall(getProp, obj, name)
    if ok then return v end
    return nil
end

local function anyHidden()
    for i = 1, #categories do
        if categories[i].hidden then return true end
    end
    return false
end

------------------------------------------------------------
-- Cache: the expensive FindAllOf scans happen only in rescan()
------------------------------------------------------------
local cache = { icons = {}, entries = {}, byActor = {}, byComp = {} }
local lastRescan = 0
local menuOpen = false   -- true while ESC has temporarily shown everything
local stash = nil        -- what was hidden before ESC was pressed

local function rescan()
    local icons, entries, byActor, byComp = {}, {}, {}, {}

    -- Compass icons (HUD copies only; also includes the PortableBeacon subclass)
    local widgets = FindAllOf("UMG_IcarusCompassIcon_C")
    for _, w in ipairs(widgets or {}) do
        if w:IsValid() and not w:GetFullName():find("DeathScreen", 1, true) then
            local portable = w:GetClass():GetFName():ToString() == "UMG_IcarusCompassIcon_PortableBeacon_C"
            icons[#icons + 1] = { w = w, portable = portable, faded = false }
        end
    end

    -- World objects of each hideable type, plus their map icon components
    for _, cat in ipairs(categories) do
        local actors = FindAllOf(cat.actor)
        for _, a in ipairs(actors or {}) do
            if a:IsValid() then
                byActor[a:GetAddress()] = cat
                local entry = { cat = cat, faded = false }
                local comp = tryGet(a, "IcarusMapIcon")
                if comp and comp:IsValid() then
                    byComp[comp:GetAddress()] = cat
                    entry.comp = comp
                end
                entries[#entries + 1] = entry
            end
        end
    end

    -- Keep the faded state of anything we already faded, so it can be restored later
    for _, new in ipairs(icons) do
        for _, old in ipairs(cache.icons) do
            if old.faded and old.w:IsValid() and old.w:GetAddress() == new.w:GetAddress() then
                new.faded = true
            end
        end
    end
    for _, new in ipairs(entries) do
        for _, old in ipairs(cache.entries) do
            if old.faded and old.comp and new.comp and old.comp:IsValid()
               and old.comp:GetAddress() == new.comp:GetAddress() then
                new.faded = true
            end
        end
    end

    cache.icons, cache.entries, cache.byActor, cache.byComp = icons, entries, byActor, byComp
    lastRescan = os.time()
end

------------------------------------------------------------
-- Apply: cheap, reads a few properties on cached objects only
------------------------------------------------------------
local function apply()
    local byActor, byComp = cache.byActor, cache.byComp

    -- Compass markers
    for i = 1, #cache.icons do
        local e = cache.icons[i]
        local w = e.w
        if w:IsValid() then
            local cat
            if e.portable then
                local ref = tryGet(w, "BeaconReference")
                if ref and ref:IsValid() then cat = byActor[ref:GetAddress()] end
            else
                local mi = tryGet(w, "LinkedMapIcon")
                if mi and mi:IsValid() then cat = byComp[mi:GetAddress()] end
            end
            if cat and cat.hidden then
                w:SetRenderOpacity(0.0)
                e.faded = true
            elseif e.faded then
                w:SetRenderOpacity(1.0)   -- icon was recycled to a type that isn't hidden
                e.faded = false
            end
        end
    end

    -- Map markers
    for i = 1, #cache.entries do
        local entry = cache.entries[i]
        local widget = entry.widget
        if (not widget or not widget:IsValid()) and entry.comp and entry.comp:IsValid() then
            widget = tryGet(entry.comp, "GeneratedIconWidget")
            if widget and widget:IsValid() then
                entry.widget = widget
            else
                widget = nil
                entry.widget = nil
            end
        end
        if widget then
            if entry.cat.hidden then
                widget:SetRenderOpacity(0.0)
                entry.faded = true
            elseif entry.faded then
                widget:SetRenderOpacity(1.0)
                entry.faded = false
            end
        end
    end
end

------------------------------------------------------------
-- Keys
------------------------------------------------------------
for _, cat in ipairs(categories) do
    RegisterKeyBind(cat.key, function()
        menuOpen = false   -- a manual toggle cancels any pending ESC restore
        stash = nil
        cat.hidden = not cat.hidden
        ExecuteInGameThread(function()
            rescan()
            apply()
            if not anyHidden() then
                cache = { icons = {}, entries = {}, byActor = {}, byComp = {} }
            end
        end)
        print(string.format("[CompassToggle] %s: %s\n", cat.label, cat.hidden and "HIDDEN" or "shown"))
    end)
end

-- F7: manual rescan (e.g. after building a new beacon while something is hidden)
RegisterKeyBind(Key.F7, function()
    if not anyHidden() then return end
    ExecuteInGameThread(function()
        rescan()
        apply()
    end)
    print("[CompassToggle] rescanned\n")
end)

------------------------------------------------------------
-- ESC: show all markers while the pause menu is open, re-hide when it closes
-- F11: manual restore (if the menu was closed some other way)
------------------------------------------------------------
local function restoreStash()
    if not stash then
        menuOpen = false
        return
    end
    for i, cat in ipairs(categories) do
        cat.hidden = stash[i]
    end
    stash = nil
    menuOpen = false
    ExecuteInGameThread(function()
        rescan()
        apply()
    end)
end

RegisterKeyBind(Key.ESCAPE, function()
    if not menuOpen then
        if not anyHidden() then return end
        stash = {}
        for i, cat in ipairs(categories) do
            stash[i] = cat.hidden
            cat.hidden = false          -- set at once so the timer stops right away
        end
        menuOpen = true
        ExecuteInGameThread(function()
            apply()                     -- puts every faded marker back
            cache = { icons = {}, entries = {}, byActor = {}, byComp = {} }
        end)
    else
        restoreStash()
    end
end)

RegisterKeyBind(Key.F11, function()
    if menuOpen then restoreStash() end
end)

------------------------------------------------------------
-- Keep markers hidden while the game recycles icons. Does nothing when nothing is hidden.
------------------------------------------------------------
local function tick()
    -- Rescan only if the cached icons have gone stale (e.g. a new world loaded), at most every 10s
    local first = cache.icons[1]
    if (not first or not first.w:IsValid()) and (os.time() - lastRescan) > 10 then
        rescan()
    end
    apply()
end

LoopAsync(TICK_MS, function()
    if anyHidden() then ExecuteInGameThread(tick) end
    return false
end)