unit
class PlayerObject
    inherit Object in "object.t"
    export
        % Constants %
        BARREL_OFFSET, BARREL_LENGTH, MOVEMENT_SPEED, ROTATE_SPEED, REVERSE_SPEED,
        % Exported variables %
        var playerID,
        % Setters %
        setInputScheme, setColour, setShootingState, clearPendingShot,
        % Getters %
        isShotPending, getBulletID
    
    %%% Internal Constants %%%
    % Movement related
    const MOVEMENT_SPEED : real := 1.25 / Level.TILE_SIZE
    const REVERSE_SPEED : real := 0.75 / Level.TILE_SIZE
    const ROTATE_SPEED : real := 2
    const MOVEMENT_DECAY : real := 0.9
    const ROTATE_DECAY : real := 0.7
    
    % Constants for the base
    const BASE_WIDTH := 25 / 2
    const BASE_LENGTH := BASE_WIDTH * 1.5
    
    % Constants for the barrel
    const BARREL_OFFSET : real := (10 div 2)
    const BARREL_LENGTH : real := (40 div 2) + BARREL_OFFSET
    const BARREL_RADIUS : real := 5 / 2
    
    % Radius of the head station
    const HEAD_RADIUS : int := 18 div 2
    
    
    %%% Instance Variables %%%
    % Whether the shooting button is down or not
    var isShooting : boolean := false
    % Set if the player has requested to fire a shot
    var shootingRequested : boolean := false
    % Set while the shot state is in the shooting state
    var isShootActive : boolean
    % The ID of the bullet to shoot
    var bulletID : int := 0
    
    % Movement controls
    var key_forward     : char := 'i'
    var key_left        : char := 'j'
    var key_backward    : char := 'k'
    var key_right       : char := 'l'
    var key_shoot       : char := 'u'
    
    % Base colour of the tank (red by default)
    var base_colour     : int := 40
    
    % If the base points need to be updated
    var base_dirty : boolean := true
    
    %% Collision Detection Note %%
    % objectBox is used for drawing the tank base and collision detection, and
    % is updated in the "update" method
    % objectAABB is used for quick overlap rejection, and is also updated in the
    % "update" method
    %%         End note         %%
    
    % Player id of this player
    var playerID : int := 0
    
    var cooldown : real := 1000
    
    
    %%% Public methods %%%
    proc setInputScheme (f, l, b, r, s : char)
        key_forward     := f
        key_left        := l
        key_backward    := b
        key_right       := r
        key_shoot       := s
    end setInputScheme
    
    proc setColour (clr : int)
        base_colour := clr
    end setColour
    
    proc setShootingState (shooting : boolean)
        isShooting := shooting
    end setShootingState
    
    /**
    * Clears the currently pending shot
    */
    proc clearPendingShot ()
        shootingRequested := false
    end clearPendingShot
    
    /**
    * Checks if the current player is requesting to shoot something
    */
    fcn isShotPending () : boolean
        result shootingRequested
    end isShotPending
    
    /**
    * Gets the ID of the bullet to shoot
    */
    fcn getBulletID () : int
        result bulletID
    end getBulletID
    
    
    %%% Implemented Methods %%%
    body proc render
        % Points used for polygon drawing
        var polyX, polyY : array 1 .. 4 of int
    
        var effX, effY, effAngle : real
        effAngle := angle + angularVel * partialTicks
        effX := offX + (posX + speed * cosd (effAngle) * partialTicks) * Level.TILE_SIZE
        effY := offY + (posY + speed * sind (effAngle) * partialTicks) * Level.TILE_SIZE
    
        % Base
        polyX (1) := round (effX + objectBox (1, 1))
        polyX (2) := round (effX + objectBox (2, 1))
        polyX (3) := round (effX + objectBox (3, 1))
        polyX (4) := round (effX + objectBox (4, 1))
        polyY (1) := round (effY + objectBox (1, 2))
        polyY (2) := round (effY + objectBox (2, 2))
        polyY (3) := round (effY + objectBox (3, 2))
        polyY (4) := round (effY + objectBox (4, 2))
    
        drawfillpolygon(polyX, polyY, 4, base_colour + 24 * 3)
        
        
        % Barrel
        var barrelOffX, barrelOffY : real := 0
        barrelOffX := BARREL_RADIUS * -sind (angle)
        barrelOffY := BARREL_RADIUS * +cosd (angle)
        
        polyX (1) := round (effX + cosd (effAngle) * BARREL_OFFSET - barrelOffX)
        polyX (2) := round (effX + cosd (effAngle) * BARREL_OFFSET + barrelOffX)
        polyX (3) := round (effX + cosd (effAngle) * BARREL_LENGTH + barrelOffX)
        polyX (4) := round (effX + cosd (effAngle) * BARREL_LENGTH - barrelOffX)
        polyY (1) := round (effY + sind (effAngle) * BARREL_OFFSET - barrelOffY)
        polyY (2) := round (effY + sind (effAngle) * BARREL_OFFSET + barrelOffY)
        polyY (3) := round (effY + sind (effAngle) * BARREL_LENGTH + barrelOffY)
        polyY (4) := round (effY + sind (effAngle) * BARREL_LENGTH - barrelOffY)
        
        drawfillpolygon(polyX, polyY, 4, 24)
        
        
        % Head
        drawfilloval (round(effX), round(effY), HEAD_RADIUS, HEAD_RADIUS, base_colour)
        
        var lookingX, lookingY : real
        lookingX  := cosd (effAngle)
        lookingY  := sind (effAngle)
        
        drawline (round (effX),
                  round (effY),
                  round (effX + lookingX * (12 + (speed * 8) ** 2 * sign(speed))),
                  round (effY + lookingY * (12 + (speed * 8) ** 2 * sign(speed))),
                  black)
    end render

    body proc update
        % Move the player around
        /*var keys : array char of boolean
        Input.KeyDown (keys)
        
        % Reset acceleration beforehand
        acceleration := 0
        angularAccel := 0
        
        % Get new acceleration
        if keys (key_forward) then
            acceleration += MOVEMENT_SPEED / 20
        end if
        if keys (key_backward) then
            acceleration -= MOVEMENT_SPEED / 20
        end if
        
        if keys (key_left) then
            angularAccel += ROTATE_SPEED / 20
        end if
        if keys (key_right) then
            angularAccel -= ROTATE_SPEED / 20
        end if*/
        
        % Get shooting status        
        if isShooting and not isShootActive then
            % A shot is requested
            shootingRequested := true
            isShootActive := true
        elsif not isShooting then
            % Reset shoot status
            isShootActive := false
        end if
        
        % Apply acceleration
        % Accelerations are updated in the appropriate input controller
        speed += acceleration
        angularVel += angularAccel
        
        % Update base_dirty status
        base_dirty |= (angularAccel > 0)
        
        % Clamp the speed
        if speed > MOVEMENT_SPEED then
            speed := MOVEMENT_SPEED
        elsif speed < -REVERSE_SPEED then
            speed := -REVERSE_SPEED
        end if
        
        % Clamp the angular velocity
        if angularVel > ROTATE_SPEED then
            angularVel := ROTATE_SPEED
        elsif angularVel < -ROTATE_SPEED then
            angularVel := -ROTATE_SPEED
        end if
        
        % Apply velocities
        posX += speed * cosd (angle)
        posY += speed * sind (angle)
        angle += angularVel
        
        % Wrap the angle around
        if angle < 360 then
            angle := 360 + angle
        end if
        
        if angle > 360 then
            angle := angle - 360
        end if
        
        % Update the base points / collision box if needed
        base_dirty := true
        if base_dirty then
            base_dirty := false
            var baseOffX : real := BASE_WIDTH * -sind (angle)
            var baseOffY : real := BASE_WIDTH * +cosd (angle)
        
            objectBox (1, 1) := - cosd (angle) * BASE_LENGTH + baseOffX
            objectBox (2, 1) := + cosd (angle) * BASE_LENGTH + baseOffX
            objectBox (3, 1) := + cosd (angle) * BASE_LENGTH - baseOffX
            objectBox (4, 1) := - cosd (angle) * BASE_LENGTH - baseOffX
            
            objectBox (1, 2) := - sind (angle) * BASE_LENGTH + baseOffY
            objectBox (2, 2) := + sind (angle) * BASE_LENGTH + baseOffY
            objectBox (3, 2) := + sind (angle) * BASE_LENGTH - baseOffY
            objectBox (4, 2) := - sind (angle) * BASE_LENGTH - baseOffY
            
            % Find the minimum and maximum x and y coordinates
            var minX, minY : real := maxint
            var maxX, maxY : real := minint
            
            for i : 1 .. upper (objectBox, 1)
                minX := min_f (minX, objectBox (i, 1))
                minY := min_f (minY, objectBox (i, 2))
                maxX := max_f (maxX, objectBox (i, 1))
                maxY := max_f (maxY, objectBox (i, 2))
            end for
            
            % Update the objectAABB
            objectAABB (1, 1) := minX - 0.125 * Level.TILE_SIZE * 1
            objectAABB (2, 1) := maxX + 0.125 * Level.TILE_SIZE * 1
            objectAABB (1, 2) := minY - 0.125 * Level.TILE_SIZE * 1
            objectAABB (2, 2) := maxY + 0.125 * Level.TILE_SIZE * 1
        end if
        
        % Check for any collisions
        
        if abs(speed) > 0 or abs (angularVel) > 0 then
            var atTX, atTY : int
            atTX := round (posX - 0.5)
            atTY := round (posY - 0.5)
            
            for dir : 0 .. 8
                var tileEdges : int := 0
                var tileOffX : int := (dir mod 3) - 1
                var tileOffY : int := (dir div 3) - 1
            
                tileEdges := level -> getEdges (atTX + tileOffX, atTY + tileOffY)
                
                % Only check for collision if the tile has edges
                if tileEdges not= -1 then
                    % Test for collision against all edges
                    var collideEdges := 0
            
                    % Test for collision against all edges
                    for edge : 0 .. 3
                        % Test only if the edge exists
                        if (tileEdges & (1 shl edge)) not= 0 and
                            isColliding (atTX + tileOffX, atTY + tileOffY, edge, objectBox) then
                            
                            % Collision detected
                            collideEdges |= (1 shl edge)
                        end if
                        
                        % Check done for this edge
                    end for
                    
                    if collideEdges not= 0 then
                        % Collision detected
                        % Response is multiplied by 1.5 to get the tank out of the
                        % wall
                        
                        % Reverse movements
                        posX -= (speed * cosd(angle)) * 1.5
                        posY -= (speed * sind(angle)) * 1.5
                        speed := 0
                        
                        % Reverse rotation
                        angle -= angularVel * 1.5
                        angularVel := 0
                    end if
                end if
            end for
        end if
        
        % Decay the speed
        if acceleration = 0 then
            if abs (speed) > 0.000001 then
                speed *= MOVEMENT_DECAY
            else
                speed := 0
            end if
        end if
        
        % Decay the angular velocity
        if angularAccel = 0 then
            if abs (angularVel) > 0.0001 then
                angularVel *= ROTATE_DECAY
            else
                base_dirty := true
                angularVel := 0
            end if
        end if
    end update
end PlayerObject