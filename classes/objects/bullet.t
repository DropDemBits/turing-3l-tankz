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
    
    % Current lifespan of the bullet. Will live for 15 seconds
    var lifespan : real := 15000
    
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
        % Reduce the lifespan
        lifespan -= elapsed
        
        if lifespan < 0 then
            setDead ()
            % Bullet is now dead, don't do anything
            return
        end if
    
        % Update position
        posX += speed * cosd (angle)
        posY += speed * sind (angle)
        
        % If we're performing the poof, don't do anything
        if lifespan < 250 then
            isDead_ := true
            return
        end if
        
        % Update owner kill status
        if sqrt ((posX - owner_ -> posX) ** 2 + (posY - owner_ -> posY) ** 2) > 0.5
           or lifespan < lifespan - 5000 then
            % Allow the ability to kill the owner after going a tile away, or for
            % existing after 5 seconds
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
                    
                    if collisionCount > 2 then
                        % Force out the bullet in a perpendicular direction
                        posX += speed * cosd (angle + 90) * 2 * (collisionCount / 10)
                        posY += speed * sind (angle + 90) * 2 * (collisionCount / 10)
                    end if
                    
                    % Definitely collided collided
                    hasCollided |= true
                end if
                
                % Check done for this edge
            end for
            
            % Update continuous collison count
            % If we have just collided, the collision coubter is incremented
            % Otherwise, it is reset to 0
            if hasCollided then
                collisionCount += 1
            else
                collisionCount := 0
            end if
        end if
    end update
    
    body proc render        
        var effX, effY : real
        effX := offX + (posX + speed * cosd (angle) * partialTicks) * Level.TILE_SIZE
        effY := offY + (posY + speed * sind (angle) * partialTicks) * Level.TILE_SIZE
        
        if lifespan < 250 then
            % Less than 0.25 seconds left, perform poof
            var poofPercent : real := 1 - (0.75 - (lifespan / 250) ** 2)
            var poofRad : int := round (5 * abs(poofPercent))
            
            drawfilloval (round (effX), round (effY), poofRad, poofRad, 24)
        else
            % Draw normal bullet
            drawfilloval (round (effX), round (effY), 6, 6, owner_ -> base_colour)
            drawfilloval (round (effX), round (effY), 5, 5, black)
        end if
        
        if offX + posX * Level.TILE_SIZE < 0 or offX + posX * Level.TILE_SIZE > maxx + RADIUS
           or offY + posY * Level.TILE_SIZE < 0 or offY + posY * Level.TILE_SIZE > maxy + RADIUS then
            % Bullet is outside of screen, kill immediately
            setDead ()
        end if
    end render
end BulletObject