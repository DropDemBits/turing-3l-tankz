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
    
    % Owning player of this bullet
    var owner_ : ^PlayerObject
    % Whether the bullet can kill its owner
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
            % Test for collision against all edges
            var collideEdges := 0
        
            % Test for collision against all edges
            for edge : 0 .. 3
                % Test only if the edge exists
                if (tileEdges & (1 shl edge)) not= 0 and
                    isColliding (atTX + tileOffX, atTY + tileOffY, edge, objectBox) then
                    
                    % Fix up the colliding side
                    %
                    % Since side collisions at the edges of walls are detected
                    % as collisions of the orthoganal side (e.g. colliding at
                    % the left end of a down wall is a down wall collision),
                    % they need to be fixed to the correct side (e.g colliding
                    % at the left end of a down wall is now a left wall
                    % collision
                    var edgeX, edgeY : real
                    var realEdge : int := edge
                    
                    % Edge radius, and some tolerance
                    const EDGE_RADIUS : real := (Level.LINE_RADIUS + 0.025) / Level.TILE_SIZE
                    
                    
                    % Fix up horizontal wall case
                    /*if edge = Level.DIR_UP or edge = Level.DIR_DOWN then
                        edgeX := atTX + tileOffX
                        
                        if edge = Level.DIR_UP then
                            edgeY := atTY + tileOffY + 1
                        else
                            edgeY := atTY + tileOffY
                        end if
                        
                        %locate (1, 1)
                        %put abs (posX - edgeX), ", ", (posY - edgeY), " ", EDGE_RADIUS..
                        if abs (posY - edgeY) < EDGE_RADIUS then
                            
                            % Collision is within the line's radius, fix it up
                            if (posX - edgeX) > 0.56 then
                                realEdge := Level.DIR_RIGHT
                                posX := posX + (1 - (posX - edgeX)) * 1.1
                            else
                                realEdge := Level.DIR_LEFT
                                posX := posX - (posX - edgeX) * 1.1
                            end if
                        end if
                    end if
                    
                    % Fixup vertical wall case
                    if edge = Level.DIR_LEFT or edge = Level.DIR_RIGHT then
                        edgeY := atTY + tileOffY
                        
                        if edge = Level.DIR_RIGHT then
                            edgeX := atTX + tileOffX + 1
                        else
                            edgeX := atTX + tileOffX
                        end if
                        
                        %locate (1, 1)
                        %put abs (posX - edgeX), ", ", (posY - edgeY), " ", EDGE_RADIUS..
                        if abs (posX - edgeX) < EDGE_RADIUS then
                            
                            % Collision is within the line's radius, fix it up
                            if (posY - edgeY) > 0.56 then
                                realEdge := Level.DIR_DOWN
                                posY := posY + (1 - (posY - edgeY)) * 1.1
                            else
                                realEdge := Level.DIR_UP
                                posY := posY - (posY - edgeY) * 1.1
                            end if
                        end if
                    end if*/
                    
                    % Collision detected, reflect the angle
                    
                    % Angle will be reflected by breaking it down into the 
                    % respective x and y components, flipping the sign
                    % as appropriate, and converting it back into an angle.
                    var amtX, amtY : real
                    
                    % Flip the appropriate sign
                    case realEdge of
                    label Level.DIR_RIGHT, Level.DIR_LEFT: amtX := -cosd (angle)     amtY := +sind (angle)
                    label Level.DIR_UP,    Level.DIR_DOWN: amtX := +cosd (angle)     amtY := -sind (angle)
                    end case
                    
                    % Convert back into an angle
                    angle := atan2d (amtY, amtX)
                    
                    % Back out immediately
                    posX += speed * cosd (angle) * 1.6
                    posY += speed * sind (angle) * 1.6
                end if
                
                % Check done for this edge
            end for
        end if
        
        % Reduce the lifespan
        lifespan -= elapsed
    end update
    
    body proc render
        if isDead then
            return
        end if
        
        var effX, effY : real
        effX := offX + (posX + speed * cosd (angle) * partialTicks) * Level.TILE_SIZE
        effY := offY + (posY + speed * sind (angle) * partialTicks) * Level.TILE_SIZE
        drawfilloval (round (effX), round (effY), 5, 5, black)
        
        /*for i : 1 .. 4
            var startP, endP : int
            
            startP := i
            endP := (i mod upper (objectBox)) + 1
            
            drawline (round (effX + objectBox (startP, 1)),
                      round (effY + objectBox (startP, 2)),
                      round (effX + objectBox (endP, 1)),
                      round (effY + objectBox (endP, 2)),
                      yellow)
        end for*/
        
        if offX + posX * Level.TILE_SIZE < 0 or offX + posX * Level.TILE_SIZE > maxx + RADIUS
           or offY + posY * Level.TILE_SIZE < 0 or offY + posY * Level.TILE_SIZE > maxy + RADIUS then
            % Bullet is outside of screen, kill immediately
            setDead ()
        end if
    end render
end BulletObject