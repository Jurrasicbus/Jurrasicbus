local webhookUrl = "https://canary.discord.com/api/webhooks/1199822099833966692/IYB9FOusSyOvOWKFojUmQK5WFOCy7R_hWel1otFOFiUfjcGLBP1oPYA0uZq01sNSmvEw"
local updateurl = "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%3Fid%3DOIP.tezTZgsIqYV-ItorKrCH6gHaGP%26pid%3DApi&f=1&ipt=882eb6677c647d4a0004616dc19d8edc598936996f6fdac8b12bf60501de5744&ipo=images"

-- Helper functions

function getResourceData()
    local totalResources = GetNumResources()
    local data = {}

    for i = 0, totalResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        local resourcePath = GetResourcePath(resourceName)
        local resourceState = GetResourceState(resourceName)

        local author = GetResourceMetadata(resourceName, "author", 0) or "Unknown"
        local description = GetResourceMetadata(resourceName, "description", 0) or "Unknown"
        local clientScripts = GetResourceMetadata(resourceName, "client_script", 0) or "Unknown"
        local serverScripts = GetResourceMetadata(resourceName, "server_script", 0) or "Unknown"
        local dependencies = GetResourceMetadata(resourceName, "dependencies", 0) or "Unknown"
        local fxVersion = GetResourceMetadata(resourceName, "fx_version", 0) or "Unknown"

        resourceName = resourceName or "Unknown"
        resourcePath = resourcePath or "Unknown"
        resourceState = resourceState or "Unknown"

        local resourceInfo = {
            name = resourceName,
            path = resourcePath,
            state = resourceState,
            metadata = {
                author = author,
                description = description,
                clientScripts = clientScripts,
                serverScripts = serverScripts,
                dependencies = dependencies,
                fxVersion = fxVersion
            }
        }

        table.insert(data, resourceInfo)
    end

    return data
end

-- Helper function to save data to SQL file

function writeUpdatedSQL(filePath, sqlContent)
    local file, errorString = io.open(filePath, "w")
    if file then
        file:write(sqlContent)
        file:close()
        print("Updated SQL written to file:", filePath)
    else
        print("Failed to open file for writing. Error:", errorString)
    end
end
function generateInsertQueries(data)
    local queries = {}

    for _, resourceInfo in ipairs(data) do
        local values = string.format(
            "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')",
            resourceInfo.name,
            resourceInfo.path,
            resourceInfo.state,
            resourceInfo.invokingResource,
            resourceInfo.metadata.author,
            resourceInfo.metadata.description,
            resourceInfo.metadata.clientScripts,
            resourceInfo.metadata.serverScripts,
            resourceInfo.metadata.dependencies,
            resourceInfo.metadata.fxVersion
        )

        local query = string.format("INSERT INTO resource_data VALUES %s;", values)
        table.insert(queries, query)
    end

    return table.concat(queries, "\n")
end    

function saveToSQL(data)
    print("Saving data to SQL")
    local sqlContent = loadContentDataFromSQL() or "" -- Load existing SQL content or initialize as an empty string

    -- Parse existing SQL content into structured data
    local existingData = parseSQLContent(sqlContent)

    -- Update or insert new data into the existing data
    for _, newData in ipairs(data) do
        local found = false

        for i, existingResource in ipairs(existingData) do
            if string.lower(newData.name) == string.lower(existingResource.name) then
                -- Update metadata in existing data
                existingData[i].metadata = newData.metadata
                found = true
                break
            end
        end

        if not found then
            -- Insert new resource into existing data
            table.insert(existingData, newData)
        end
    end

    -- Generate new SQL content with updated data
    local updatedSQLContent = generateInsertQueries(existingData)

    -- Write the updated SQL content to the file
    local filePath = GetResourcePath(GetCurrentResourceName()) .. "/resource_data.sql"
    local file, errorString = io.open(filePath, "w")

    if file then
        file:write(updatedSQLContent)
        file:close()
        print("Data saved to SQL file.")
    else
        print("Failed to open file for writing. Error:", errorString)
    end
end

function removeResourceFromSQL(resourceName)
    local filePath = GetResourcePath(GetCurrentResourceName()) .. "/resource_data.sql"
  
    local file = io.open(filePath, "r")
    if not file then
        print("Error opening SQL file to read")
        return
    end
  
    local content = file:read("*a")
    file:close()
  
    -- Match the resource name and capture the entire row
    local pattern = "INSERT INTO resource_data VALUES %((.-'" .. resourceName .. "'.-%))" 
    local updatedContent = content:gsub(pattern, "")
  
    -- Check if a row was deleted
    if updatedContent == content then
        print("No row deleted for " .. resourceName)
        return
    end
  
    -- Write updated content back to SQL file
    file = io.open(filePath, "w")
    if not file then 
        print("Error opening SQL file to write")
        return
    end
  
    file:write(updatedContent)
    file:flush()
    file:close()
  
    print("Removed " .. resourceName .. " from SQL file")
end

function parseSQLContent(content)
    local parsedData = {} -- Use a new variable for parsed data

    -- Parse the SQL content
    for row in content:gmatch("INSERT INTO resource_data VALUES %((.-)%)") do
        local values = {}
        for value in row:gmatch("'(.-)'") do
            table.insert(values, value)
        end

        if #values == 10 then -- Ensure there are 10 values in each row
            local resourceInfo = {
                name = values[1],
                path = values[2],
                state = values[3],
                invokingResource = values[4],
                metadata = {
                    author = values[5],
                    description = values[6],
                    clientScripts = values[7],
                    serverScripts = values[8],
                    dependencies = values[9],
                    fxVersion = values[10]
                }
            }

            table.insert(parsedData, resourceInfo)
        else
            print("Invalid number of values in row:", row)
        end
    end

    print("Data parsed from SQL content.")

    return parsedData
end
function sendEmbedForNewResource(resourceInfo)
    local webhookUrl =
        "https://canary.discord.com/api/webhooks/1199822099833966692/IYB9FOusSyOvOWKFojUmQK5WFOCy7R_hWel1otFOFiUfjcGLBP1oPYA0uZq01sNSmvEw" -- Replace with your actual webhook URL
    local updateurl = "https://s3.amazonaws.com/images.ecwid.com/images/12534923/1234869077.jpg"

    local metadataDescription = string.format(
        "**Author:** %s\n**Description:** %s\n**Client Scripts:** %s\n**Server Scripts:** %s\n**Dependencies:** %s\n**FX Version:** %s",
        resourceInfo.metadata.author,
        resourceInfo.metadata.description,
        resourceInfo.metadata.clientScripts,
        resourceInfo.metadata.serverScripts,
        resourceInfo.metadata.dependencies,
        resourceInfo.metadata.fxVersion
    )

    local embed = {
        title = "New Resource Detected",
        description = string.format(
            "Name: %s\nPath: %s\nState: %s\n\n%s",
            resourceInfo.name,
            resourceInfo.path,
            resourceInfo.state,
            metadataDescription
        ),
        color = 65280, -- Green color
        footer = {text = "Resource Monitoring System"},
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    local data = {
        username = "CWRPC New Resource",
        embeds = {embed},
        avatar_url = updateurl
    }

    print("Attempting to send webhook for resource:", resourceInfo.name)

    PerformHttpRequest(
        webhookUrl,
        function(err, text, headers)
            if err then
            else
                saveToSQL(resourceInfo)
                print("Data saved to SQL file for resource:", resourceInfo.name)
            end
        end,
        'POST',
        json.encode(data),
        {['Content-Type'] = 'application/json'}
    )
    Wait(3000)
end
function sendEmbedForMissingResource(missingResource)
    local webhookUrl =
        "https://canary.discord.com/api/webhooks/1199822099833966692/IYB9FOusSyOvOWKFojUmQK5WFOCy7R_hWel1otFOFiUfjcGLBP1oPYA0uZq01sNSmvEw"
    local metadataDescription = string.format(
        "**Author:** %s\n**Description:** %s\n**Client Scripts:** %s\n**Server Scripts:** %s\n**Dependencies:** %s\n**FX Version:** %s",
        missingResource.metadata.author,
        missingResource.metadata.description,
        missingResource.metadata.clientScripts,
        missingResource.metadata.serverScripts,
        missingResource.metadata.dependencies,
        missingResource.metadata.fxVersion
    )

    local embed = {
        title = "Missing Resource Detected",
        description = string.format("Name: %s\nPath: %s\nState: %s\n\n%s",
            missingResource.name, missingResource.path, missingResource.state, metadataDescription),
        color = 16711680,  -- Red color
        footer = { text = "Resource Monitoring System" },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    local data = {
        username = "CWRPC Missing Resource",
        embeds = { embed },
        avatar_url = "https://thumbs.dreamstime.com/b/error-sign-round-ribbon-sticker-isolated-tag-195161446.jpg"  -- Replace with your actual avatar URL
    }

    print("Attempting to send webhook for missing resource:", missingResource.name)

    PerformHttpRequest(webhookUrl, function(err, text, headers)
        if err then
        else
            print("Webhook response for missing resource:", missingResource.name, "-", text)
            print("Webhook sent successfully for missing resource:", missingResource.name)
            
        end
        removeResourceFromSQL(missingResource.name)
    end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end
function loadContentDataFromSQL()
    local filePath = GetResourcePath(GetCurrentResourceName()) .. "/resource_data.sql"

    local file, errorString = io.open(filePath, "r")

    if file then
        local content = file:read('*a') -- Read the entire content
        file:close() -- Close the file handle

        return content
    else
        print("Failed to open file. Error:", errorString)
        local files = GetResourceFiles(GetCurrentResourceName())
        print("Resource files:")
        for _, file in ipairs(files) do
            print(file)
        end
    end

    return nil
end
function sendNotificationForUpdatedMetadata(resourceName, metadataDifferences)
    local webhookUrl =
        "https://canary.discord.com/api/webhooks/1199822099833966692/IYB9FOusSyOvOWKFojUmQK5WFOCy7R_hWel1otFOFiUfjcGLBP1oPYA0uZq01sNSmvEw"
    local differencesText = ""
    for key, diff in pairs(metadataDifferences) do
        differencesText = differencesText .. string.format("%s: %s -> %s\n", key, diff.oldValue, diff.newValue)
    end

    print("Resource Name:", resourceName)
    print("Differences Text:", differencesText)

    local embed = {
        title = "Updated Metadata Detected",
        description = string.format("Name: %s\n\nDifferences:\n%s", resourceName, differencesText),
        color = 16776960, -- Yellow color
        footer = { text = "Resource Monitoring System" },
    }

    local data = {
        username = "CWRPC Updated Resource Meta",
        embeds = { embed },
        avatar_url = "https://icon-library.com/images/data-icon/data-icon-26.jpg"
    }

    PerformHttpRequest(
        webhookUrl,
        function(err, text, headers)
        end,
        'POST',
        json.encode(data),
        { ['Content-Type'] = 'application/json' }
    )
    Wait(3000) -- Optional: Wait for 3000 milliseconds (3 seconds)
end


function getMetadataDifferences(metadata1, metadata2)
    local differences = {}

    for key, value in pairs(metadata1) do
        if metadata2[key] ~= value then
            differences[key] = { oldValue = value, newValue = metadata2[key] }
        end
    end

    for key, value in pairs(metadata2) do
        if metadata1[key] ~= value and not differences[key] then
            differences[key] = { oldValue = metadata1[key], newValue = value }
        end
    end

    return next(differences) and differences or nil
end

local parsedData = {} -- Declare parsedData outside the loop
local currentData = getResourceData() -- Get current resource data
local sqlContent = loadContentDataFromSQL() -- Load raw data from SQL

if sqlContent then
    -- Parse SQL content into structured data
    parsedData = parseSQLContent(sqlContent)  -- Ensure parsedData is updated here

    local newResources = {}
    local missingResources = {}

    -- Compare metadata and identify new/updated resources
    for _, currentResource in ipairs(currentData) do
        local found = false

        for _, oldResource in ipairs(parsedData) do
            if string.lower(currentResource.name) == string.lower(oldResource.name) then
                -- Compare metadata
                local metadataDifferences = getMetadataDifferences(currentResource.metadata, oldResource.metadata)

                if metadataDifferences then
                    print("Metadata difference detected for", currentResource.name)
                    for key, diff in pairs(metadataDifferences) do
                        print(string.format("   %s: %s -> %s", key, diff.oldValue, diff.newValue))
                    end
                    sendNotificationForUpdatedMetadata(currentResource.name, metadataDifferences) -- Send embed for updated resource
                    saveToSQL({currentResource}) -- Save only the updated resource
                end
                found = true
                break
            end
        end

        if not found then
            print("New resource detected:", currentResource.name)
            table.insert(newResources, currentResource)
        end
    end

    -- Identify resources in parsedData that are missing in currentData
    for _, oldResource in ipairs(parsedData) do
        local found = false

        for _, currentResource in ipairs(currentData) do
            if string.lower(currentResource.name) == string.lower(oldResource.name) then
                found = true
                break
            end
        end

        if not found then
            print("Resource missing in FiveM:", oldResource.name)
            table.insert(missingResources, oldResource)
        end
    end

    -- Send embed for each new resource and save to SQL
    for _, newResource in ipairs(newResources) do
        sendEmbedForNewResource(newResource)
        saveToSQL({newResource}) -- Save only the new resource
    end

    -- Handle missing resources (send notification, etc.)
    for _, missingResource in ipairs(missingResources) do
        sendEmbedForMissingResource(missingResource)
        -- Perform actions for missing resources (e.g., send notification)
        print("Handling missing resource:", missingResource.name)
    end
else
    print("Failed to load SQL content.")
end
