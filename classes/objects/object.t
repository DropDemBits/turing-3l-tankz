% Root Object Class
% Root class for all updatable objects
unit
class Object
    import
        MathUtil in "../../lib/math_util.tu",
        Level in "../level.t"
    export
        % Core methods %
        update, render, initObj,
        % Setters %
        setLevel, setDead, setPosition, setAngle, setSpeed, setAccel,
        % Getters %
        posX, posY, angle, speed, acceleration, level, isDead, isRemoved, overlaps,
        % Local export %
        objectAABB, objectBox

    % Position & Orientation
    var posX, posY : real := 0
    var angle : real := 0
    
    % Speeds
    var speed : real := 0
    var angularVel : real := 0
    
    % Accelerations
    var acceleration : real := 0
    var angularAccel : real := 0
    
    % If the object is dead, but is not enqueued for removal
    var isDead_ : boolean := false
    % If the object will be removed
    var isRemoved_ : boolean := false
    
    % The level the object coexists with
    var level : ^Level := nil
    
    % Orientation-corrected object bounding box
    var objectBox : array 1 .. 4, 1 .. 2 of real := init (0, 0, 0, 0, 0, 0, 0, 0)
    % Axis-align object bounding box. Used for quick overlap rejection
    var objectAABB : array 1 .. 2, 1 .. 2 of real := init (0, 0, 0, 0)
    
    
    % Updates the object
    deferred proc update (elapsed : real)
    % Draws the object
    deferred proc render (offX, offY : real, partialTicks : real)
    % Initializes the object
    deferred proc onInitObj (x, y, a : real)
    % Sets the object to be dead
    deferred proc setDead ()
    
    % Default impl
    body proc onInitObj
    end onInitObj
    
    body proc setDead ()
        isDead_ := true
        isRemoved_ := true
    end setDead
    
    fcn isDead () : boolean
        result isDead_
    end isDead
    
    fcn isRemoved () : boolean
        result isRemoved_
    end isRemoved
    
    /**
    * Initializes the object
    * Also sets position and orientation
    */
    proc initObj (x, y, a : real)
        posX := x
        posY := y
        angle := a
        
        speed := 0
        angularVel := 0
        
        onInitObj (x, y, a)
    end initObj
    
    /**
    * Sets the level the object is in
    */
    proc setLevel (level_ : ^Level)
        level := level_
    end setLevel
    
    /**
    * Sets the position of this object
    */
    proc setPosition (x, y : real)
        posX := x
        posY := y
    end setPosition
    
    proc setAngle (a : real)
        angle := a
    end setAngle
    
    /**
    * Sets the speeds of this object
    *
    * Parameters:
    * linear:   Linear speed of the object
    * angular:  Angular speed of the object
    */
    proc setSpeed (linear, angular : real)
        speed := linear
        angularVel := angular
    end setSpeed
    
    /**
    * Sets the accelerations of this object
    *
    * Parameters:
    * linear:   Linear acceleration of the object
    * angular:  Angular acceleration of the object
    */
    proc setAccel (linear, angular : real)
        acceleration := linear
        angularAccel := angular
    end setAccel
    
    %%% Utilitiy %%%
    
    /**
    * Checks if two boxes are overlapping
    * The box's coordinates are assumed to have been transformed into world
    * space
    *
    * Overlap checking is done via Seperating Axis Theorem, which states that
    * two shapes will not intersect if a line (an axis) can be drawn in
    * between them
    *
    * Inspiration is from this video:
    * https://www.youtube.com/watch?v=7Ik2vowGcU0
    * Optimizations are from here:
    * https://www.gamedev.net/articles/programming/general-and-gameplay-programming/2d-rotated-rectangle-collision-r2604
    *
    * General SAT Algorithm:
    * ForEach side of shape1:
    *   Calculate the projection axis
    *   ForEach point of both shapes:
    *       Project the point onto the axis
    *       Find the minimum and maximum values for the shape
    *   If the minimum and maximum values of each shape don't overlap then
    *       Done, no overlap was detected
    * Done, overlap was detected
    *
    * Optimizations:
    * Since we are always checking rectangles, there are a few assumtions we can
    * make:
    * - The polygons have the same number of sides (don't need to check twice)
    * - The polygons have two perpendicular normals (cuts down the number of
    *   axis to compare against)
    * 
    * Returns if there is overlap, and the amount to displace to resolve the
    * overlap
    */
    fcn isOverlapping (box1, box2 : array 1 .. 4, 1 .. 2 of real, var displacement : real) : boolean
        % Ensure displacement has a known value
        displacement := maxint
        
        % Calculate the four axis vectors (perpendicular normals of the sides)
        % Like calculating a perpendicular slope, except with the separated
        % components
        var axis : array 1 .. 4, 1 .. 2 of real
        
        % Box 1
        axis (1, 1) := -(box1 (1, 2) - box1 (2, 2)) % -y
        axis (1, 2) :=  (box1 (1, 1) - box1 (2, 1)) %  x
        axis (2, 1) := -(box1 (3, 2) - box1 (2, 2)) % -y
        axis (2, 2) :=  (box1 (3, 1) - box1 (2, 1)) %  x
        
        % Box 2
        axis (3, 1) := -(box2 (1, 2) - box2 (2, 2)) % -y
        axis (3, 2) :=  (box2 (1, 1) - box2 (2, 1)) %  x
        axis (4, 1) := -(box2 (3, 2) - box2 (2, 2)) % -y
        axis (4, 2) :=  (box2 (3, 1) - box2 (2, 1)) %  x
        
        % Go through all of the axis, stopping once an intersection is found
        for i : 1 .. upper (axis)
            % Find the minimum and maximum extents of each box
            var min_box1, min_box2 : real := maxint
            var max_box1, max_box2 : real := minint
            
            for point : 1 .. 4
                % Project the shape's point onto the axis vector (using dot product)
                var proj_box1, proj_box2 : real
                proj_box1 := box1 (point, 1) * axis (i, 1) + box1 (point, 2) * axis (i, 2)
                proj_box2 := box2 (point, 1) * axis (i, 1) + box2 (point, 2) * axis (i, 2)
                
                % Find minimums of both shapes
                min_box1 := min_f (min_box1, proj_box1)
                min_box2 := min_f (min_box2, proj_box2)
                
                % Find maximums of both shapes
                max_box1 := max_f (max_box1, proj_box1)
                max_box2 := max_f (max_box2, proj_box2)
                
                % Find the minimum displacement to resolve the collision
                var overlap := max_f (max_box1, max_box2) - min_f (min_box1, min_box2)
                displacement := min_f (overlap, displacement)
            end for
            
            % Check if there's any overlap
            if not (max_box2 >= min_box1 and max_box1 >= min_box2) then
                % Boxes are not, return
                displacement := 0
                
                result false
            end if
            
        end for
        
        % Boxes are overlapping
        result true
    end isOverlapping
    
    /**
    * Checks if the object is colliding with a wall
    * This uses a modified form of the isOverlapping method, as a few more
    * assumptions can be made:
    * - Two of the 4 axis are parallel to the respective world axis
    * - The parallel axis will always be in the same direction
    *
    * Returns if the object is colliding with the wall, and the static
    * displacement to resolve the collision
    */
    fcn isColliding (tileX, tileY, direction : int, box_points : array 1 .. 4, 1 .. 2 of real, var displaceX, displaceY : real) : boolean
        % Translate the current object's box into world space
        var objBox : array 1 .. 4, 1 .. 2 of real
        
        for i : 1 .. 4
            objBox (i, 1) := posX + objectBox (i, 1) / Level.TILE_SIZE
            objBox (i, 2) := posY + objectBox (i, 2) / Level.TILE_SIZE
        end for
    
        % Calculate the bounds of the wall box
        var wallBox : array 1 .. 4, 1 .. 2 of real
        
        case direction of
            label Level.DIR_UP:
                % 0,1 -> 1,1
                
                % 0, 0
                wallBox(1, 1) := tileX + 0
                wallBox(1, 2) := tileY + 1 - Level.LINE_RADIUS / Level.TILE_SIZE
                
                % 0, 1
                wallBox(2, 1) := tileX + 1
                wallBox(2, 2) := tileY + 1 - Level.LINE_RADIUS / Level.TILE_SIZE
                
                % 1, 1
                wallBox(3, 1) := tileX + 1
                wallBox(3, 2) := tileY + 1 + Level.LINE_RADIUS / Level.TILE_SIZE
                
                % 1, 0
                wallBox(4, 1) := tileX + 0
                wallBox(4, 2) := tileY + 1 + Level.LINE_RADIUS / Level.TILE_SIZE
            label Level.DIR_DOWN:
                % 0, 0
                wallBox(1, 1) := tileX + 0
                wallBox(1, 2) := tileY + 0 - Level.LINE_RADIUS / Level.TILE_SIZE
                
                % 0, 1
                wallBox(2, 1) := tileX + 1
                wallBox(2, 2) := tileY + 0 - Level.LINE_RADIUS / Level.TILE_SIZE
                
                % 1, 1
                wallBox(3, 1) := tileX + 1
                wallBox(3, 2) := tileY + 0 + Level.LINE_RADIUS / Level.TILE_SIZE
                
                % 1, 0
                wallBox(4, 1) := tileX + 0
                wallBox(4, 2) := tileY + 0 + Level.LINE_RADIUS / Level.TILE_SIZE
            label Level.DIR_LEFT:
                % 0, 0
                wallBox(1, 1) := tileX + 0 - Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(1, 2) := tileY + 0
                
                % 0, 1
                wallBox(2, 1) := tileX + 0 - Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(2, 2) := tileY + 1
                
                % 1, 1
                wallBox(3, 1) := tileX + 0 + Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(3, 2) := tileY + 1
                
                % 1, 0
                wallBox(4, 1) := tileX + 0 + Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(4, 2) := tileY + 0
            label Level.DIR_RIGHT:
                % 0, 0
                wallBox(1, 1) := tileX + 1 - Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(1, 2) := tileY + 0
                
                % 0, 1
                wallBox(2, 1) := tileX + 1 - Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(2, 2) := tileY + 1
                
                % 1, 1
                wallBox(3, 1) := tileX + 1 + Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(3, 2) := tileY + 1
                
                % 1, 0
                wallBox(4, 1) := tileX + 1 + Level.LINE_RADIUS / Level.TILE_SIZE
                wallBox(4, 2) := tileY + 0
        end case
        
        % Test using isOverlapping
        %var displacement : real := 0
        %var isColliding := isOverlapping (wallBox, objBox, displacement)
        
        var isColliding : boolean := false
        var displaceAmount : real := 0
    
        % Get edge endpoints
        var edgeX0, edgeY0, edgeX1, edgeY1 : real
        
        case direction of
        label Level.DIR_UP:
            % 0,1 -> 1,1
            edgeX0 := tileX + 0
            edgeY0 := tileY + 1 - 1 / Level.TILE_SIZE
            edgeX1 := tileX + 1
            edgeY1 := tileY + 1 - 1 / Level.TILE_SIZE
        label Level.DIR_DOWN:
            % 0,0 -> 1,0
            edgeX0 := tileX + 0
            edgeY0 := tileY + 0 + 1 / Level.TILE_SIZE
            edgeX1 := tileX + 1
            edgeY1 := tileY + 0 + 1 / Level.TILE_SIZE
        label Level.DIR_LEFT:
            % 0,0 -> 0,1
            edgeX0 := tileX + 0 + 1 / Level.TILE_SIZE
            edgeY0 := tileY + 0
            edgeX1 := tileX + 0 + 1 / Level.TILE_SIZE
            edgeY1 := tileY + 1
        label Level.DIR_RIGHT:
            % 1,0 -> 1,1
            edgeX0 := tileX + 1 - 1 / Level.TILE_SIZE
            edgeY0 := tileY + 0
            edgeX1 := tileX + 1 - 1 / Level.TILE_SIZE
            edgeY1 := tileY + 1
        end case
    
        % Check for intersection between box edges:
        for box_side : 1 .. 4
            % Line-Line intersection from:
            % http://paulbourke.net/geometry/pointlineplane/
            var u_a0, u_ab, u_b0 : real
            
            % Get side endpoints
            var sideX0 : real := posX + (box_points (box_side, 1)) / Level.TILE_SIZE
            var sideY0 : real := posY + (box_points (box_side, 2)) / Level.TILE_SIZE
            var sideX1 : real := posX + (box_points ((box_side mod upper (box_points)) + 1, 1)) / Level.TILE_SIZE
            var sideY1 : real := posY + (box_points ((box_side mod upper (box_points)) + 1, 2)) / Level.TILE_SIZE
            
            % Check for intersection
            u_a0 := (edgeX1 - edgeX0)*(sideY0 - edgeY0) - (edgeY1 - edgeY0)*(sideX0 - edgeX0)
            u_b0 := (sideX1 - sideX0)*(sideY0 - edgeY0) - (sideY1 - sideY0)*(sideX0 - edgeX0)
            u_ab := (edgeY1 - edgeY0)*(sideX1 - sideX0) - (edgeX1 - edgeX0)*(sideY1 - sideY0)
            
            var u_a, u_b : real := 0
            var dx, dy : real
            
            if u_ab not= 0 then
                u_a := u_a0 / u_ab
                u_b := u_b0 / u_ab
                isColliding := (u_a >= 0 and u_a <= 1) and (u_b >= 0 and u_b <= 1)
                
                
                dx := (sideX0 + u_a * (sideX1 - sideX0)) - posX
                dy := (sideY0 + u_a * (sideY1 - sideY0)) - posY
                
                displaceAmount := sqrt (dx ** 2 + dy ** 2)
            else
                % Lines are parallel, will never collide
                isColliding := false
            end if
            
            if isColliding then
                locate (12, 1)
                put dx, ", ", dy
            
                % Collision has been detected with this tank side
                % No other edges to check
                exit
            end if
            % Tank side not colliding
        end for
        
        /*if displaceX not= 0 then
            drawfillbox
                   (round (wallBox (1, 1) * Level.TILE_SIZE + level -> cameraX),
                    round (wallBox (1, 2) * Level.TILE_SIZE + level -> cameraY),
                    round (wallBox (3, 1) * Level.TILE_SIZE + level -> cameraX),
                    round (wallBox (3, 2) * Level.TILE_SIZE + level -> cameraY),
                    40 + direction * 2)
        end if*/
        
        % All sides tested
        if not isColliding then
            % No collision detected, don't do anything
            %displaceX := 0
            %displaceY := 0
            result false
        end if
        
        % Calculate the displacement in the x and y directions
        % Displacement is applied in the direction of both object centres
        
        % Find the centres of the walls
        var wallCentreX : real := (wallBox(3, 1) + wallBox(1, 1)) / 2
        var wallCentreY : real := (wallBox(3, 2) + wallBox(1, 2)) / 2
        
        % Find the centre of this object
        var objCentreX : real := (objBox(3, 1) + objBox(1, 1)) / 2
        var objCentreY : real := (objBox(3, 2) + objBox(1, 2)) / 2
        
        % Calculate the displacement vector
        displaceX := (wallCentreX - objCentreX)
        displaceY := (wallCentreY - objCentreY)
        
        % Find the magnitude of the displacement vector for normalization
        var mag : real := sqrt (displaceX ** 2 + displaceY ** 2)
        
        % Calculate the real displacement values
        displaceX := -(displaceAmount * displaceX) / mag
        displaceY := -(displaceAmount * displaceY) / mag
        
        % Collision has been detected
        result true      
    end isColliding
    
    /**
    * Checks if this object overlaps with the specified object
    */
    fcn overlaps (other : ^Object) : boolean
        % Quickly check if the boxes are overlapping
        if     posX + objectAABB (1, 1) / Level.TILE_SIZE > other -> posX + other -> objectAABB (2, 1) / Level.TILE_SIZE
            or posX + objectAABB (2, 1) / Level.TILE_SIZE < other -> posX + other -> objectAABB (1, 1) / Level.TILE_SIZE
            or posY + objectAABB (1, 2) / Level.TILE_SIZE > other -> posY + other -> objectAABB (2, 2) / Level.TILE_SIZE
            or posY + objectAABB (2, 2) / Level.TILE_SIZE < other -> posY + other -> objectAABB (1, 2) / Level.TILE_SIZE then
            
            % Boxes aren't overlapping
            result false
        end if
        
        % Transform the boxes into world space
        var box1, box2 : array 1 .. 4, 1 .. 2 of real
        
        for i : 1 .. 4
            box1 (i, 1) := posX + objectBox (i, 1) / Level.TILE_SIZE
            box1 (i, 2) := posY + objectBox (i, 2) / Level.TILE_SIZE
            
            box2 (i, 1) := other -> posX + other -> objectBox (i, 1) / Level.TILE_SIZE
            box2 (i, 2) := other -> posY + other -> objectBox (i, 2) / Level.TILE_SIZE
        end for
        
        % Use SAT to determine overlap (don't care about displacement)
        var displacement : real
        result isOverlapping (box1, box2, displacement)
    end overlaps
end Object
