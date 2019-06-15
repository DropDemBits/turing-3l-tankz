% Base class for all of the bullets
unit
class BulletObject
    inherit Object in "object.t"
    import PlayerObject in "player.t"
    export setOwner, getOwner, canKillOwner
    
    const RADIUS : real := 5
    const BULLET_BOX : array 1 .. 4, 1 .. 2 of real := init (
        -RADIUS, -RADIUS,
        +RADIUS, -RADIUS,
        +RADIUS, +RADIUS,
        -RADIUS, +RADIUS,
        )
    
    % Current lifespan of the bullet. Will live for 30 seconds
    var lifespan : real := 30000
    
    % Last collision checkss done by this bullet
    var lastCollideChecks_ : int := 0
    
    % Number of collisions bullet has gone through
    var collisionCount : int := 0
    
    % Owning player of this bullet
    var owner_ : ^PlayerObject
    % Whether the bullet can kill its owner. It can't initially
    var canKillOwner_ : boolean := false
    
    
    /**
    * Sets the owner of this bullet
    */
    proc setOwner (owner__ : ^PlayerObject)
        owner_ := owner__
    end setOwner
    
    /**
    * Gets the owner of this bullet
    */
    fcn getOwner () : ^PlayerObject
        result owner_
    end getOwner
    
    /**
    * If this bullet can kill its owner
    */
    fcn canKillOwner () : boolean
        result canKillOwner_
    end canKillOwner
    
    body proc onInitObj
        % Set up speed
        speed := 2 / Level.TILE_SIZE
        
        % Setup bounding boxes
        for i : 1 .. upper (BULLET_BOX, 1)
            objectBox  (i, 1) := BULLET_BOX (i, 1)
            objectBox  (i, 2) := BULLET_BOX (i, 2)
        end for
        
        objectAABB (1, 1) := BULLET_BOX (1, 1)
        objectAABB (1, 2) := BULLET_BOX (1, 2)
        objectAABB (2, 1) := BULLET_BOX (3, 1)
        objectAABB (2, 2) := BULLET_BOX (3, 2)
    end onInitObj
    
    body proc update
        if lifespan < 0 then
            setDead ()
            % Bullet is now dead, don't do anything
            return
        end if
    
        % Update position
        posX += speed * cosd (angle)
        posY += speed * sind (angle)
        
        % Update owner kill status
        if sqrt ((posX - owner_ -> posX) ** 2 + (posY - owner_ -> posY) ** 2) > 1 then
            % Allow the ability to kill the owner after going a tile away
            canKillOwner_ := true
        end if
        
        % Check for any collisions
        var atTX, atTY : int
        atTX := round (posX - 0.5)
        atTY := round (posY - 0.5)
        
        
        var tileEdges : int := 0
        var tileOffX : int := 0
        var tileOffY : int := 0
        
        tileEdges := level -> getEdges (atTX + tileOffX, atTY + tileOffY)
            
        % Only check for collision if the tile has edges
        locate (1, 1)
        if tileEdges not= -1 then
            var hasCollided : boolean := false
        
            % Test for collision against all edges
            var collideEdges := 0
            var newLastCollided : int := 0
        
            % Test for collision against all edges
            for edge : 0 .. 3
                % Test only if the edge exists,
                % Perform coarse collision detection
                if      (tileEdges & (1 shl edge)) not= 0
                    and isColliding (atTX + tileOffX, atTY + tileOffY, edge, objectBox) then
                    % Reverse our movements
                    posX -= + speed * cosd (angle)
                    posY -= + speed * sind (angle)
                    
                    % Investigate the collision point further
                    var stepSpeed : real := speed / 10
                    for steps : 1 .. 10
                        % Keep advancing the position until we hit the collision point
                        exit when isColliding (atTX + tileOffX, atTY + tileOffY, edge, objectBox)
                        
                        posX += + stepSpeed * cosd (angle)
                        posY += + stepSpeed * sind (angle)
                    end for
                    
                    % Collision detected, reflect the angle
                    
                    % Angle will be reflected by breaking it down into the 
                    % respective x and y components, flipping the sign
                    % as appropriate, and converting it back into an angle.
                    var amtX, amtY : real
                    
                    % Flip the appropriate sign
                    case edge of
                    label Level.DIR_RIGHT, Level.DIR_LEFT: amtX := -cosd (angle)     amtY := +sind (angle)
                    label Level.DIR_UP,    Level.DIR_DOWN: amtX := +cosd (angle)     amtY := -sind (angle)
                    end case
                    
                    % Convert back into an angle
                    angle := atan2d (amtY, amtX)
                    
                    % Displace self out of wall
                    posX += speed * cosd (angle) * 0.5
                    posY += speed * sind (angle) * 0.5
                    
                    if collisionCount > 1 then
                        posX += speed * cosd (angle + 90) * 2 * (collisionCount / 10)
                        posY += speed * sind (angle + 90) * 2 * (collisionCount / 10)
                    end if
                    
                    % Either collided or technically collided
                    hasCollided |= true
                    newLastCollided |= 1 shl edge
                end if
                
                % Check done for this edge
            end for
            
            % Update last collision checks
            % If we have just collided, the current tiles edges are out last checks
            % Otherwise, it is 0
            %locate (8, 1)
            %put lastCollideChecks_, " "..
            
            locate (10, 1)
            if hasCollided then
                collisionCount += 1
                lastCollideChecks_ := newLastCollided
                put "a "..
            else
                collisionCount := 0
                lastCollideChecks_ := 0
                put "r "..
            end if
            put collisionCount ..
            
            %put intstr (lastCollideChecks_, 4, 2)..
        end if
        
        % Reduce the lifespan
        lifespan -= elapsed
    end update
    
    body proc render
        if isDead () then
            return
        end if
        
        var effX, effY : real
        effX := offX + (posX + speed * cosd (angle) * partialTicks) * Level.TILE_SIZE
        effY := offY + (posY + speed * sind (angle) * partialTicks) * Level.TILE_SIZE
        drawfilloval (round (effX), round (effY), 5, 5, black)
        
        % Draw object bounding box (OBB)
        /*
        for i : 1 .. 4
            var startP, endP : int
            
            startP := i
            endP := (i mod upper (objectBox)) + 1
            
            drawline (round (effX + objectBox (startP, 1)),
                      round (effY + objectBox (startP, 2)),
                      round (effX + objectBox (endP, 1)),
                      round (effY + objectBox (endP, 2)),
                      yellow)
        end for
        */
        
        if offX + posX * Level.TILE_SIZE < 0 or offX + posX * Level.TILE_SIZE > maxx + RADIUS
           or offY + posY * Level.TILE_SIZE < 0 or offY + posY * Level.TILE_SIZE > maxy + RADIUS then
            % Bullet is outside of screen, kill immediately
            setDead ()
        end if
    end render
end BulletObject