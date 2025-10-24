loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/File/Fps%20display.lua"))()
local PlaceScripts = {
    [10324346056] = { 
        name = "Big Team", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua" 
    },
    [9872472334] = { 
        name = "Evade", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua" 
    },
    [96537472072550] = { 
        name = "Legacy Evade", 
        url = "UNSUPPORTED" 
    },
    [10662542523] = { 
        name = "Casual", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua" 
    },
    [10324347967] = { 
        name = "Social Space", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua" 
    },
    [121271605799901] = { 
        name = "Player Nextbots", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua" 
    },
    [10808838353] = { 
        name = "VC Only", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua" 
    },
    [11353528705] = { 
        name = "Pro", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua" 
    },
    [99214917572799] = { 
        name = "Custom Servers", 
        url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20Test.lua"  
    },
}

local UniversalScript = {
    name = "Universal Script",
    url = "https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/File/Universal-Hub.lua"
}

local currentGameId = game.PlaceId
local selectedScript = PlaceScripts[currentGameId]

if selectedScript then
    if selectedScript.url == "UNSUPPORTED" then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error - Game Not Supported",
            Text = selectedScript.name .. " is currently unsupported. Please check back later.",
            Duration = 5
        })
    else
        local success, result = pcall(function()
            return loadstring(game:HttpGet(selectedScript.url))()
        end)
        if not success then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "",
                Text = "" .. selectedScript.name .. " script: " .. tostring(result),
                Duration = 5
            })
        end
    end
else
    local success, result = pcall(function()
        return loadstring(game:HttpGet(UniversalScript.url))()
    end)
    if not success then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "",
            Text = "" .. tostring(result),
            Duration = 5
        })
    end
end
