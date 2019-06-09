unit
class PlayerObject
    inherit Object in "objects.t"
    export 
    %% Setters %%
    setInputScheme, setColour, clearPendingShot,
    %% Getters %%
    isShotPending, getBulletID
    
    %%% Internal Constants %%%
    % Movement related
    const MOVEMENT_SPEED : real := 1.25 / Level.TILE_SIZE
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
    
    % Relative coordinates of the base's position
    % Used for drawing the tank base and collision detection
    % Updated in the "update" method
    var base_points : array 1 .. 4, 1 .. 2 of real := init (0, 0, 0, 0, 0, 0, 0, 0)
    % If the base points need to be updated
    var base_dirty : boolean := true
    
    
    %%% Private methods %%%
    fcn isColliding (tileX, tileY, direction : int) : boolean
        var isColliding : boolean := false
    
        % Check for intersection between tank edges:
        for tank_side : 1 .. 4
            % Line-Line intersection from:
            % http://paulbourke.net/geometry/pointlineplane/
            var u_a0, u_ab, u_b0 : real
            
            % Get side endpoints
            var sideX0 : real := posX + (base_points (tank_side, 1)) / Level.TILE_SIZE
            var sideY0 : real := posY + (base_points (tank_side, 2)) / Level.TILE_SIZE
            var sideX1 : real := posX + (base_points (((tank_side + 2) mod upper (base_points)) + 1, 1)) / Level.TILE_SIZE
            var sideY1 : real := posY + (base_points (((tank_side + 2) mod upper (base_points)) + 1, 2)) / Level.TILE_SIZE
        
            % Get edge endpoints
            var edgeX0, edgeY0, edgeX1, edgeY1 : real
            
            case direction of
            label Level.DIR_UP:
                % 0,1 -> 1,1
                edgeX0 := tileX + 0
                edgeY0 := tileY + 1
                edgeX1 := tileX + 1
                edgeY1 := tileY + 1
            label Level.DIR_DOWN:
                % 0,0 -> 1,0
                edgeX0 := tileX + 0
                edgeY0 := tileY + 0
                edgeX1 := tileX + 1
                edgeY1 := tileY + 0
            label Level.DIR_LEFT:
                % 0,0 -> 0,1
                edgeX0 := tileX + 0
                edgeY0 := tileY + 0
                edgeX1 := tileX + 0
                edgeY1 := tileY + 1
            label Level.DIR_RIGHT:
                % 1,0 -> 1,1
                edgeX0 := tileX + 1
                edgeY0 := tileY + 0
                edgeX1 := tileX + 1
                edgeY1 := tileY + 1
            end case
            
            % Check for intersection
            u_a0 := (edgeX1 - edgeX0)*(sideY0 - edgeY0) - (edgeY1 - edgeY0)*(sideX0 - edgeX0)
            u_b0 := (sideX1 - sideX0)*(sideY0 - edgeY0) - (sideY1 - sideY0)*(sideX0 - edgeX0)
            u_ab := (edgeY1 - edgeY0)*(sideX1 - sideX0) - (edgeX1 - edgeX0)*(sideY1 - sideY0)
            
            var u_a, u_b : real := 0
            
            if u_ab not= 0 then
                u_a := u_a0 / u_ab
                u_b := u_b0 / u_ab
                isColliding := (u_a >= 0 and u_a <= 1) and (u_b >= 0 and u_b <= 1)
            else
                % Lines are parallel, will never collide
                isColliding := false
            end if
            
            if isColliding then
                % Collision has been detected with this tank side
                % No other edges to check
                exit
            end if
            % Tank side not colliding
        end for
        % All sides tested
        
        result isColliding
    end isColliding
    
    
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
        polyX (1) := round (effX + base_points (1, 1))
        polyX (2) := round (effX + base_points (2, 1))
        polyX (3) := round (effX + base_points (3, 1))
        polyX (4) := round (effX + base_points (4, 1))
        polyY (1) := round (effY + base_points (1, 2))
        polyY (2) := round (effY + base_points (2, 2))
        polyY (3) := round (effY + base_points (3, 2))
        polyY (4) := round (effY + base_points (4, 2))
    
        drawfillpolygon(polyX, polyY, 4, base_colour + 24 * 3)
        
        
        % Barrel
        var barrelOffX, barrelOffY : real := 0
        barrelOffX := round(BARREL_RADIUS * -sind (angle))
        barrelOffY := round(BARREL_RADIUS * +cosd (angle))
        
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
        
        if shootingRequested then
            locate (5, 1)
            put "pew ", base_colour
        end if
        
        var lookingX, lookingY : real
        lookingX  := cosd (effAngle)
        lookingY  := sind (effAngle)
        
        drawline (round (effX),
                  round (effY),
                  round (effX + lookingX * (12 + (speed * 4) ** 2 * sign(speed))),
                  round (effY + lookingY * (12 + (speed * 4) ** 2 * sign(speed))),
                  black)
    end render

    body proc update
        % Move the player around
        var keys : array char of boolean
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
        end if
        
        % Apply acceleration
        speed += acceleration
        angularVel += angularAccel
        
        % Update base_dirty status
        base_dirty |= (angularAccel > 0)
        
        % Clamp the speed
        if speed > MOVEMENT_SPEED then
            speed := MOVEMENT_SPEED
        elsif speed < -MOVEMENT_SPEED then
            speed := -MOVEMENT_SPEED
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
        
        % Get shooting status
        var wasShooting : boolean := isShooting
        isShooting := keys (key_shoot)
        
        if not wasShooting and isShooting then
            % A shot is requested
            shootingRequested := true
        end if
        
        
        % Update the base points / collision box if needed
        base_dirty := true
        if base_dirty then
            base_dirty := false
            var baseOffX : real := BASE_WIDTH * -sind (angle)
            var baseOffY : real := BASE_WIDTH * +cosd (angle)
        
            base_points (1, 1) := - cosd (angle) * BASE_LENGTH + baseOffX
            base_points (2, 1) := + cosd (angle) * BASE_LENGTH + baseOffX
            base_points (3, 1) := + cosd (angle) * BASE_LENGTH - baseOffX
            base_points (4, 1) := - cosd (angle) * BASE_LENGTH - baseOffX
            base_points (1, 2) := - sind (angle) * BASE_LENGTH + baseOffY
            base_points (2, 2) := + sind (angle) * BASE_LENGTH + baseOffY
            base_points (3, 2) := + sind (angle) * BASE_LENGTH - baseOffY
            base_points (4, 2) := - sind (angle) * BASE_LENGTH - baseOffY
        end if
        
        % Check for any collisions
        var atTX, atTY : int
        atTX := round (posX - 0.5)
        atTY := round (posY - 0.5)
        
        for dir : 0 .. 8
            var tileEdges : int := 0
            var tileOffX : int := (dir mod 3) - 1
            var tileOffY : int := (dir div 3) - 1
        
            tileEdges := level -> getEdges (atTX + tileOffX, atTY + tileOffY)
            
            % Only check for collision if the tile has edges
            locate (1, 1)
            if tileEdges not= -1 then
                % Test for collision against all edges
                var collideEdges := 0
        
                % Test for collision against all edges
                for edge : 0 .. 3
                    % Test only if the edge exists
                    if (tileEdges & (1 shl edge)) not= 0 and
                        isColliding (atTX + tileOffX, atTY + tileOffY, edge) then
                        
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