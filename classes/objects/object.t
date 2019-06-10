% Root Object Class
% Root class for all updatable objects
unit
class Object
    import Level in "../level.t"
    export update, render, initObj, setLevel, setDead, posX, posY, angle, var speed, isDead, isRemoved, overlaps, objectAABB, objectBox

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
    var isDead : boolean := false
    % If the object will be removed
    var isRemoved : boolean := false
    
    % The level the object coexists with
    var level : ^Level := nil
    
    % Orientation-corrected object bounding box
    var objectBox : array 1 .. 4, 1 .. 2 of real := init (0, 0, 0, 0, 0, 0, 0, 0)
    % Axis-align object bounding box. Used for quick overlap rejection
    var objectAABB : array 1 .. 2, 1 .. 2 of real := init (0, 0, 0, 0)
    
    
    %%% Math Functions (Move to MathUtil) %%%
    /**
    * Converts the given cartesian coordinate into a unique angle, in degrees
    */
    fcn atan2d (y, x : real) : real
        % Cover -+90 branches
        if x = 0 then
            % Return 90 * sign (y) (defines x = 0, y = 0 to be 0)
            result sign (y) * 90
        end if
        
        % Cover general branch
        if x > 0 then
            % Normal arctangent
            result arctand (y / x)
        end if
        
        % Cover negative x branch
        if y < 0 then
            result arctand (y / x) + 180
        else
            result arctand (y / x) - 180
        end if
    end atan2d
    
    /**
    * Returns the smaller real
    */
    fcn min_real (a, b : real) : real
        if a < b then
            result a
        end if
        result b
    end min_real
    
    /**
    * Returns the bigger real
    */
    fcn max_real (a, b : real) : real
        if a > b then
            result a
        end if
        result b
    end max_real
    
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
        isDead := true
        isRemoved := true
    end setDead
    
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
    
    %%% Utilitiy %%%
    /**
    * Checks if the object is colliding with a wall
    */
    fcn isColliding (tileX, tileY, direction : int, box_points : array 1 .. 4, 1 .. 2 of real) : boolean
        var isColliding : boolean := false
    
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
    
    /**
    * Checks if two boxes are overlapping
    * The box's coordinates are assumed to have been transformed into world
    * space
    *
    * Overlap checking is done via Seperated Axis Theorem, which states that
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
    *   If the minimum and maximum values of each shape overlap then
    *       Done, Overlap was detected
    * Done, no overlap was detected
    *
    * Optimizations:
    * Since we are always checking rectangles, there are a few assumtions we can
    * make:
    * - The polygons have the same number of sides (don't need to check twice)
    * - The polygons have two perpendicular normals (cuts down the number of
    *   axis to compare against)
    * 
    */
    fcn isOverlapping (box1, box2 : array 1 .. 4, 1 .. 2 of real) : boolean
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
        
        % Normalize the axis vectors (simplifies projection)
        %for i : 1 .. upper (axis)
        %    var magnitude : real := sqrt (axis (i, 1) ** 2 + axis (i, 2) ** 2)
        %    axis (i, 1) /= magnitude
        %    axis (i, 2) /= magnitude
        %end for
        
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
                min_box1 := min_real (min_box1, proj_box1)
                min_box2 := min_real (min_box2, proj_box2)
                
                % Find maximums of both shapes
                max_box1 := max_real (max_box1, proj_box1)
                max_box2 := max_real (max_box2, proj_box2)
            end for
            
            % Check if there's any overlap
            if not (max_box2 >= min_box1 and max_box1 >= min_box2) then
                % Boxes are not, return
                result false
            end if
            
        end for
        
        % Boxes are overlapping
        result true
    end isOverlapping
    
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
        
        % Use SAT to determine overlap
        result isOverlapping (box1, box2)
    end overlaps
end Object
