% Map Class
% Handles all of the entity & level updating and rendering
unit
class Map
    import Level in "level.t", PlayerObject in "player.t"
    export initMap, freeMap, render, update, addPlayer
    
    var nextFree : int := 0
    var players : array 0 .. 63 of ^PlayerObject
    var level : ^Level
    
    var cameraX, cameraY : real := 0
    
    proc initMap (width, height : int)
        % Setup camera position
        cameraX := maxx div 2 - (width  / 2 * Level.TILE_SIZE)
        cameraY := maxy div 2 - (height / 2 * Level.TILE_SIZE)
    
        % Setup the level
        new Level, level
        
        Level (level).initLevel (width, height)
        
        % Clear the player list
        for i : 0 .. upper (players)
            players (i) := nil
        end for
    end initMap
    
    proc freeMap ()
        for i : 0 .. upper (players)
            if players (i) not= nil then
                free PlayerObject, players (i)
            end if
        end for
        
        free Level, level
    end freeMap
    
    proc update (elapsed : int)
        % Update the level
        Level (level).update (elapsed)
        
        % Update each player
        for i : 0 .. upper (players)
            exit when players (i) = nil
            
            players (i) -> update (elapsed)
            
            % Check if bullet fire is requested
            if players (i) -> isShotPending () then
                players (i) -> clearPendingShot ()
            end if
        end for
    end update
    
    proc render (partialTicks: real)
        % Draw the level
        Level (level).setOffset (cameraX, cameraY)
        Level (level).render (partialTicks)
        
        % Draw each player
        for i : 0 .. upper (players)
            exit when players (i) = nil
            
            players (i) -> render (cameraX, cameraY, partialTicks)
        end for
    end render
    
    
    proc addPlayer (base_colour, tileX, tileY : int, f, l, d, r, s : char)
        if not level -> inBounds (tileX, tileY) then
            return
        end if
        
        % Create a new player
        var player : ^PlayerObject
        new PlayerObject, player
        
        % Setup the player object
        player -> initObj (tileX + 0.5, tileY + 0.5, 0)
        player -> setInputScheme (f, l, d, r, s)
        player -> setColour (base_colour)
        player -> setLevel (level)
        
        players (nextFree) := player
        nextFree += 1
    end addPlayer
end Map