-- MADE BY LEFOS

-- CONFIG, CHANGE THINGS
local webhook1 = "https://canary.discord.com/api/webhooks/1190688672195026964/u0oxr_z9_rWQvuedf_A9um9szbCXqxnWLr_ZIRoFVLhdnUfa-IcrJXhw06ur6kOGEnpS" -- Create a webhook and put it here
local webhook2 = "https://canary.discord.com/api/webhooks/1190688672195026964/u0oxr_z9_rWQvuedf_A9um9szbCXqxnWLr_ZIRoFVLhdnUfa-IcrJXhw06ur6kOGEnpS" -- Create a webhook and put it here
local username = "CWRPC" -- Put your server name or anything else you want the author of the message to be

-- Function to extract identifiers
function ExtractIdentifiers(source)
    local identifiers = {}
    
    for _, v in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            identifiers.steam = v
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
            identifiers.license = v
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
            identifiers.xbl = v
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            identifiers.discord = v
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
            identifiers.live = v
        end
    end
    
    return identifiers
end

-- Event handler for playerConnecting
AddEventHandler('playerConnecting', function()
    local name = GetPlayerName(source)
    local identifiers = ExtractIdentifiers(source)

    local connect = {
        {
            ["color"] = "1048320", -- Color in decimal
            ["title"] = "User Joined!", -- Title of the embed message
            ["description"] = "Name: **" .. name .. "**\n" ..
                              "Steam ID: **" .. (identifiers.steam or "N/A") .. "**\n" ..
                              "GTA License: **" .. (identifiers.license or "N/A") .. "**\n" ..
                              "Xbox Live ID: **" .. (identifiers.xbl or "N/A") .. "**\n" ..
                              "Discord Tag: **" .. (identifiers.discord and ("<@" .. identifiers.discord:gsub("discord:", "") .. ">") or "N/A") .. "**\n" ..
                              "Live ID: **" .. (identifiers.live or "N/A") .. "**", -- Main Body of embed with the info about the person who joined
        }
    }

    PerformHttpRequest(webhook1, function(err, text, headers) end, 'POST', json.encode({ username = username, embeds = connect, tts = TTS }), { ['Content-Type'] = 'application/json' }) -- Perform the request to the discord webhook and send the specified message
end)

-- Event handler for playerDropped
AddEventHandler('playerDropped', function(reason)
    local name = GetPlayerName(source)
    local identifiers = ExtractIdentifiers(source)
    local steam = identifiers.steam or "N/A"
    local license = identifiers.license or "N/A"
    local discord = identifiers.discord and "<@" .. identifiers.discord:gsub("discord:", "") .. ">" or "N/A"

    local disconnect = {
        {
            ["color"] = "16711680", -- Color in decimal
            ["title"] = "User Left!", -- Title of the embed message
            ["description"] = "Name: **" .. name .. "**\n" ..
                              "Steam ID: **" .. steam .. "**\n" ..
                              "GTA License: **" .. license .. "**\n" ..
                              "Discord Tag: **" .. discord .. "**\n" ..
                              "Xbox Live ID: **" .. (identifiers.xbl or "N/A") .. "**\n" ..
                              "Live ID: **" .. (identifiers.live or "N/A") .. "**\n" ..
                              "Reason: **" .. reason .. "**", -- Main Body of embed with the info about the person who left
        }
    }

    PerformHttpRequest(webhook2, function(err, text, headers) end, 'POST', json.encode({ username = username, embeds = disconnect, tts = TTS }), { ['Content-Type'] = 'application/json' }) -- Perform the request to the discord webhook and send the specified message
end)
