% Level class & data structures
unit
class Level
    export initLevel, render, update, setOffset, getEdges, drawEdges, rg
    
    const TILE_SIZE : int := 64
    
    %% Internal Types %%
    % Maze node for maze generation
    type MazeNode :
        record
            tileX, tileY : int
            visited : boolean
        end record
    
    % Offsets used for direction determination
    const offsets : array 0 .. 3 of int := init (0, 1, 0, -1)
    
    var width, height : int := 0
    var mapTiles : flexible array 0 .. -1 of int
    var mapNodes : flexible array 0 .. -1 of ^MazeNode
    
    var cameraX, cameraY : real := 0
    
    % Gets the edges at the current tile
    fcn getEdges (tx, ty : int) : int
        if tx < 0 or ty < 0 or tx >= width or ty >= height then
            result -1
        end if
        
        result mapTiles (tx + ty * width)
    end getEdges
    
    proc setEdges (tx, ty : int, edges : int)
        if tx < 0 or ty < 0 or tx >= width or ty >= height then
            return
        end if
        
        mapTiles (tx + ty * width) := edges
    end setEdges
    
    proc clearEdge (tx, ty, dir : int)
        if dir < 0 or dir > 3 then
            return
        end if
        
        const offsets : array 0 .. 3 of int := init (0, 1, 0, -1)
        
        var xOff := offsets ((dir + 1) mod 4)
        var yOff := offsets (dir)
        
        var newEdgeA, newEdgeB : int
        newEdgeA := getEdges (tx, ty)
        newEdgeB := getEdges (tx + xOff, ty + yOff)
        
        if newEdgeA = -1 and newEdgeB = -1 then
            % Out of Bounds
            return
        end if
        
        % Clear main edge
        newEdgeA &= not (1 shl dir)
        setEdges (tx, ty, newEdgeA)
        
        if newEdgeB not= -1 then
            % Clear opposite edge
            newEdgeB &= not (1 shl ((dir - 2) mod 4))
            setEdges (tx + xOff, ty + yOff, newEdgeB)
        end if
    end clearEdge
    
        
    proc drawEdges (tileX, tileY, clr : int)
        var startX := tileX * TILE_SIZE + round (cameraX)
        var startY := tileY * TILE_SIZE + round (cameraY)
        var endX := (tileX + 1) * TILE_SIZE + round (cameraX)
        var endY := (tileY + 1) * TILE_SIZE + round (cameraY)
        var edges := getEdges (tileX, tileY)
        
        if edges = -1 then
            drawfillbox (startX, startY, endX, endY, blue)
            return
        end if
        
        % Draw edges
        const RADIUS : int := 1
        if (edges & 1) not= 0 then drawfillbox (  endX + RADIUS, startY - RADIUS,   endX - RADIUS,   endY - RADIUS, clr) end if
        if (edges & 2) not= 0 then drawfillbox (  endX + RADIUS,   endY + RADIUS, startX + RADIUS,   endY - RADIUS, clr) end if
        if (edges & 4) not= 0 then drawfillbox (startX - RADIUS,   endY + RADIUS, startX + RADIUS, startY + RADIUS, clr) end if
        if (edges & 8) not= 0 then drawfillbox (startX - RADIUS, startY - RADIUS,   endX - RADIUS, startY + RADIUS, clr) end if
    end drawEdges
    
    % Generates the map starting at the given node
    proc generateMaze (currIdx : int, currNode : ^MazeNode)
        % Recursive Depth first search of maze generation
        
        % The direction to walk through
        var dir : int := 0
        % Offset to the next maze node
        var xOff, yOff : int
        % Whether the all of the current node's neighbors have been visited
        var allVisited : boolean := true
        
        % Current node will always be visited
        currNode -> visited := true
        
        % Get the next neighbor to traverse
        var walked : int := 0
        loop
            %                                           0 1 2 3
            % Select a random neighbor to walk through (E N W S)
            dir := Rand.Int (0, 3)
            
            xOff := offsets ((dir + 1) mod 4)
            yOff := offsets (dir)
            
            % Check if the direction is inside of the map
            if getEdges (currNode -> tileX + xOff, currNode -> tileY + yOff) not= -1 then
                % Calculate the next node indicies
                var nextIdx : int := currIdx + (xOff + yOff * width)
                var nextNode : ^MazeNode := mapNodes (nextIdx)
                
                % Check if the next node hasn't been traversed yet
                if not nextNode -> visited then
                    % Breakdown the wall
                    clearEdge (currNode -> tileX, currNode -> tileY, dir)
                    clearEdge (nextNode -> tileX, nextNode -> tileY, (dir - 2) mod 4)
                    
                    % Recursive walk
                    generateMaze (nextIdx, nextNode)
                end if
            end if
            
            % Indicate that this direction has been checked
            walked or= 1 shl dir
            
            % Stop once all of the nodes have been walked
            exit when walked = 2#1111
        end loop
    end generateMaze
    
    /**
    * Initializes the level
    *
    * Parameters:
    * width_:   The width of the map
    * height_:  The length of the map
    */
    proc initLevel (width_, height_ : int)
        width := width_
        height := height_
        
        new mapNodes, (width * height) - 1
        new mapTiles, (width * height) - 1
        
        for i : 0 .. upper (mapNodes)
            new mapNodes(i)
        end for
            
        % Set up all the edges 
        for i : 0 .. upper (mapTiles)
            mapTiles (i) := 2#1111
        end for
            
        % Generate the maze nodes
        for i : 0 .. upper (mapNodes)
            const tileX : int := (i mod width)
            const tileY : int := (i div width)
            
            mapNodes (i) -> tileX := tileX
            mapNodes (i) -> tileY := tileY
            mapNodes (i) -> visited := false
        end for
        
        % Generate the main maze
        generateMaze (0, mapNodes(0))
        
        % Knock down a few walls
        for i : 1 .. 10
            var tx, ty, dir : int
            tx := Rand.Int (0, width)
            ty := Rand.Int (0, height)
            dir := Rand.Int (0, 3)
            
            var xOff := offsets ((dir + 1) mod 4)
            var yOff := offsets (dir)
            
            % Only knock down edges that don't form the boundary
            if getEdges (tx + xOff, ty + yOff) not= -1 then
                clearEdge (tx, ty, dir)
            end if
        end for
    end initLevel
    
    proc rg
        for i : 0 .. upper (mapTiles)
            mapTiles (i) := 2#1111
        end for
            
        % Generate the maze nodes
        for i : 0 .. upper (mapNodes)
            const tileX : int := (i mod width)
            const tileY : int := (i div width)
            
            mapNodes (i) -> tileX := tileX
            mapNodes (i) -> tileY := tileY
            mapNodes (i) -> visited := false
        end for
    
        generateMaze (0, mapNodes(0))
        
        for i : 1 .. 10
            var tx, ty, dir : int
            tx := Rand.Int (0, width)
            ty := Rand.Int (0, height)
            dir := Rand.Int (0, 3)
            
            var xOff := offsets ((dir + 1) mod 4)
            var yOff := offsets (dir)
            
            % Only knock down edges that don't form the boundary
            if getEdges (tx + xOff, ty + yOff) not= -1 then
                clearEdge (tx, ty, dir)
            end if
        end for
    end rg
    
    /**
    * Sets the level draw offset from the bottom right corner
    */
    proc setOffset (offX_, offY_ : real)
        cameraX := offX_
        cameraY := offY_
    end setOffset
    
    /**
    * Updates the level and related objects
    */
    proc update (elapsed : int)
    end update
    
    /**
    * Renders the map and related objects
    *
    * Parameters:
    * partialTicks: The amount to interpolate between updates
    */
    proc render (partialTicks : real)
        for i : 0 .. upper (mapTiles)
            % Calculate tile to draw
            const tileX : int := i mod width
            const tileY : int := i div width
            
            % Draw map edges
            drawEdges (tileX, tileY, 16)
        end for
    end render
end Level