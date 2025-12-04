local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local MAX_PLAYERS = 5  // maximum players at server
local MIN_PLAYERS = 0  // minimum players at server

local function serverHop(placeId)
    placeId = placeId or game.PlaceId
    
    print("Attempting to server hop in Place ID: " .. placeId)
    
    local success, errorMessage = pcall(function()
        local cursor = ""
        local foundServer = false
        
        
        for i = 1, 3 do 
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
                placeId,
                cursor
            )
            
            local success2, response = pcall(function()
                return game:HttpGetAsync(url)
            end)
            
            if not success2 then
                
                print("HTTP request failed, using fallback method")
                break
            end
            
            local data = HttpService:JSONDecode(response)
            
            if data and data.data then
                
                local servers = data.data
                table.sort(servers, function(a, b)
                    return a.playing < b.playing
                end)
                
                
                for _, server in ipairs(servers) do
                    if server.id ~= game.JobId and 
                       server.playing >= MIN_PLAYERS and
                       server.playing < MAX_PLAYERS and
                       server.playing < server.maxPlayers then
                        
                        print(string.format("Found server with %d/%d players", 
                            server.playing, server.maxPlayers))
                        
                        TeleportService:TeleportToPlaceInstance(
                            placeId,
                            server.id,
                            Players.LocalPlayer
                        )
                        foundServer = true
                        return
                    end
                end
                
                
                if data.nextPageCursor then
                    cursor = data.nextPageCursor
                else
                    break
                end
            else
                break
            end
        end
        
        if not foundServer then
            print("No suitable servers found, using random teleport")
            TeleportService:Teleport(placeId, Players.LocalPlayer)
        end
    end)
    
    if not success then
        warn("Server hop error: " .. tostring(errorMessage))
      
        pcall(function()
            print("Using fallback random teleport")
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end)
    end
end

serverHop()
