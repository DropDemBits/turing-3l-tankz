% Map Class
% Handles all of the entity & level updating and rendering
unit
class Match
    import
        InputControllers in "input.t",
        Level in "level.t",
        PlayerObject in "objects/player.t",
        BulletObject in "objects/bullet.t"
    export
        matchEnded, winningPlayer,
        initMatch, freeMatch, render, update,
        addPlayer
    
    % 3 seconds to the end of a match
    const END_COUNTDOWN : int := 4000
    
    % Shaking related constants
    const SHAKE_INTENSITY : real := 50
    const SHAKE_DECAY : real := 0.9
    
    % Next free index into the player list
    var nextFree : int := 0
    % List of active players
    var players : array 0 .. 63 of unchecked ^PlayerObject
    
    % Next free index into the bullet list
    var nextFreeBullet : int := 0
    % List of active bullets
    var activeBullets : array 0 .. 255 of unchecked ^BulletObject
    
    % Current level associated with this match
    var level : ^Level
    
    %% End-of-match variables %%
    % Number of currently living players
    var livingPlayers : int := 0
    % Timer until a rematch happens. Begins counting down once there's one
    % player left
    var endTimer : real := END_COUNTDOWN
    % If the match has ended or not
    var matchEnded : boolean := false
    % The player that won the match. Is -1 if no one won
    var winningPlayer : int := -1
    
    
    % Current camera position. Affected by shake
    var cameraX, cameraY : real := 0
    % If the screen should be shaken
    var shakeScreen_ : boolean := false
    % Intensity of the shake
    var shakeIntensity_ : real := 0
    
    /**
    * Initializes the match and other things
    */
    proc initMatch (width, height : int)
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
        
        % Cleat the active bullets
        for i : 0 .. upper (activeBullets)
            activeBullets (i) := nil
        end for
    end initMatch
    
    proc freeMatch ()
        % Free all of the players
        for i : 0 .. upper (players)
            if players (i) not= nil then
                free players (i)
            end if
        end for
        nextFree := 0
        
        % Free all of the active bullets
        for i : 0 .. upper (activeBullets)
            if activeBullets (i) not= nil then
                free activeBullets (i)
            end if
        end for
        nextFreeBullet := 0
        
        free Level, level
    end freeMatch
    
    
    proc addPlayer (id, base_colour, tileX, tileY : int, controller : ^InputController)
        if not level -> inBounds (tileX, tileY) or nextFree > upper (players) then
            % Outside of bounds or no slots
            return
        end if
        
        % Create a new player
        var player : ^PlayerObject
        new PlayerObject, player
        
        % Setup the player object
        player -> initObj (tileX + 0.5, tileY + 0.5, 360 * Rand.Real ())
        player -> setColour (base_colour)
        player -> setLevel (level)
        player -> playerID := id
        controller -> setPlayer (player)
        
        % Add to the player list
        players (nextFree) := player
        nextFree += 1
        
        % Add to the living players count
        livingPlayers += 1
    end addPlayer
    
    fcn spawnBullet (owner : ^PlayerObject, bulletID : int) : boolean
        var bullet : ^BulletObject
        new BulletObject, bullet
        
        % Calculate offset to barrel end
        var offX, offY : real
        offX := (cosd(owner -> angle) * (owner -> BARREL_LENGTH - 4)) / Level.TILE_SIZE
        offY := (sind(owner -> angle) * (owner -> BARREL_LENGTH - 4)) / Level.TILE_SIZE
        
        % Initialize the bullet
        bullet -> initObj (offX + owner -> posX, offY + owner -> posY, owner -> angle)
        bullet -> setLevel (level)
        bullet -> setOwner (owner)
        
        % Find a free bullet slot
        var bulletSlot : int := -1
        
        % Check if there's any contiguous slots left
        if nextFreeBullet <= upper (activeBullets) then
            bulletSlot := nextFreeBullet
            nextFreeBullet += 1
        else
            % Will have to search through list
            for i : 0 .. upper (activeBullets)
                if activeBullets (i) = nil then
                    % Slot found, use it
                    bulletSlot := i
                    exit
                end if
            end for
        end if
        
        if bulletSlot = -1 then
            % No free slot was found
            result false
        end if
        
        % Add bullet to active list
        activeBullets (bulletSlot) := bullet
        result true
    end spawnBullet
    
    
    proc update (elapsed : int)
        if matchEnded then
            % Don't need to do anything when the match ends
            return
        end if
        
        % Check if there is at most one player left
        if livingPlayers <= 1 then
            % Start counting down
            endTimer -= elapsed
            
            if endTimer < 0 then
                % Match has ended
                matchEnded := true
                
                % Search for the winning player
                winningPlayer := -1
                
                for i : 0 .. upper (players)
                    if players (i) not= nil and not players (i) -> isDead () then
                        % Winning player found
                        winningPlayer := players (i) -> playerID
                        exit
                    end if
                end for
                
                return
            end if
        end if
    
        % Update the level
        Level (level).update (elapsed)
        
        % Update each player
        for i : 0 .. upper (players)
            exit when players (i) = nil
            
            % Don't update dead players
            if not players (i) -> isDead () then
                players (i) -> update (elapsed)
                
                % Check if bullet fire is requested
                if players (i) -> isShotPending () then
                    var spawned := spawnBullet (players (i), players (i) -> getBulletID ())
                    
                    if spawned then
                        % Clear the pending shot if the bullet was spawned
                        players (i) -> clearPendingShot ()
                    end if
                end if
            end if
        end for
        
        % Update every bullet
        for i : 0 .. upper (activeBullets)
            if activeBullets (i) not= nil then
                % Don't update dead bullets
                if not activeBullets (i) -> isDead () then
                    activeBullets (i) -> update (elapsed)
                    
                    % Check if we've collided with another player
                    for ply : 0 .. upper (players)
                        exit when players (ply) = nil
                        
                        if  not players (ply) -> isDead ()
                            and (players (ply) not= activeBullets (i) -> getOwner () or activeBullets (i) -> canKillOwner ())
                            and players (ply) -> overlaps (activeBullets (i)) then
                            % Bullet collided with player, kill them and the
                            % bullet
                            activeBullets (i) -> setDead ()
                            players (ply) -> setDead ()
                            
                            % Decrement the living player count
                            livingPlayers -= 1
                            
                            % Shake the screen
                            shakeScreen_ := true
                            
                            % Done, move on
                            exit
                        end if
                    end for
                end if
                
                % Remove the bullet if it's going to be removed
                if activeBullets (i) -> isRemoved () then
                    free activeBullets (i)
                    activeBullets (i) := nil
                end if
            end if
        end for
        
        % Let the shake intensity decay
        if shakeIntensity_ > 0.001 then
            shakeIntensity_ *= SHAKE_DECAY
        else
            % Shake is below a visible quantity, stop
            shakeIntensity_ := 0
        end if
        
        % Start shaking the screen when requested
        if shakeScreen_ then
            shakeScreen_ := false
            
            % Add on even more shaking
            shakeIntensity_ += SHAKE_INTENSITY
        end if
    end update
    
    proc render (partialTicks: real)
        % Calculate effective camera after camera shake
        var realCamX, realCamY : real
        realCamX := cameraX + Rand.Real () * shakeIntensity_
        realCamY := cameraY + Rand.Real () * shakeIntensity_
        
        % Draw the level
        Level (level).setOffset (realCamX, realCamY)
        Level (level).render (partialTicks)
        
        % Draw each player
        for i : 0 .. upper (players)
            exit when players (i) = nil
            
            % Don't draw dead players
            if not players (i) -> isDead () then
                players (i) -> render (realCamX, realCamY, partialTicks)
            end if
        end for
        
        % Draw every bullet
        for i : 0 .. upper (activeBullets)
            % Don't draw dead bullets
            if activeBullets (i) not= nil and not activeBullets (i) -> isDead () then
                activeBullets (i) -> render (realCamX, realCamY, partialTicks)
            end if
        end for
        
        % Draw the match end countdown
        if livingPlayers <= 1 then
            locate (6, 1)
            put (endTimer / 1000) ..
        end if
    end render
end Match