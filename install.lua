---
--- Created by Alex.
--- DateTime: 31.10.2025 11:56
---

local base = "https://raw.githubusercontent.com/makargravanov-cc-tweaked-scripts/cc-tweaked-chunk-mining/main/"
local presets = {
    common = {
        "lib/vec.lua",
        "lib/gps_util.lua",
        "lib/drone_tasks_enum.lua",
        "lib/concurrent_queue.lua"
    },
    hub = {
        "hub/main.lua"
    },
    drone = {
        "drone/main.lua",
        "drone/drone.lua"
    }
}

local function mergePresets(a, b)
    local merged, seen = {}, {}
    for _, list in ipairs({a, b}) do
        for _, path in ipairs(list) do
            if not seen[path] then
                table.insert(merged, path)
                seen[path] = true
            end
        end
    end
    return merged
end

presets.hub = mergePresets(presets.common, presets.hub)
presets.drone = mergePresets(presets.common, presets.drone)
presets.all = mergePresets(mergePresets(presets.common, presets.hub), presets.drone)

local function downloadFiles(list)
    for _, path in ipairs(list) do
        local url = base .. path
        local dir = fs.getDir(path)
        if dir and dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
            print("Created dir: " .. dir)
        end
        local res = http.get(url)
        if res then
            local f = fs.open(path, "w")
            if f then
                f.write(res.readAll())
                f.close()
                res.close()
                print("Loaded: " .. path)
            else
                print("Failed to open file: " .. path)
            end
        else
            print("Loading error: " .. path)
        end
    end
end

local args = {...}
local choice = args[1]
if not choice then
    print("Use: install <hub|drone|all>")
    return
end
if presets[choice] then
    downloadFiles(presets[choice])
    print("Loading '" .. choice .. "' is completed.")
else
    print("Unknown preset: " .. choice)
end