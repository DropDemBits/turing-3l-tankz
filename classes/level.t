% Level class & data structures
const TILE_SIZE : int := 48

type MazeNode :
record
    tileX, tileY : int
    visited : boolean
end record

class Level
    import MazeNode, TILE_SIZE
    
    var width, height : int := 0
    var mapTiles : flexible array 0 .. -1 of int
    var mapNodes : flexible array 0 .. -1 of ^MazeNode
    
    width := 10
    height := 10
    
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
            % OOB
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
    
    proc drawTile (tileX, tileY, clr : int)
        const startX := tileX * TILE_SIZE
        const startY := tileY * TILE_SIZE
        const endX := (tileX + 1) * TILE_SIZE
        const endY := (tileY + 1) * TILE_SIZE
        
        % Draw box
        drawfillbox (startX, startY, endX, endY, clr)
    end drawTile
    
    proc drawEdges (tileX, tileY, clr : int)
        const startX := tileX * TILE_SIZE
        const startY := tileY * TILE_SIZE
        const endX := (tileX + 1) * TILE_SIZE
        const endY := (tileY + 1) * TILE_SIZE
        const edge := getEdges (tileX, tileY)
        
        if edge = -1 then
            return
        end if
        
        % Draw edges
        const RADIUS : int := 1
        %if (edge & 1) not= 0 then drawfillbox (  endX + RADIUS, startY - RADIUS,   endX - RADIUS,   endY - RADIUS, clr) end if
        %if (edge & 2) not= 0 then drawfillbox (  endX + RADIUS,   endY + RADIUS, startX + RADIUS,   endY - RADIUS, clr) end if
        %if (edge & 4) not= 0 then drawfillbox (startX - RADIUS,   endY + RADIUS, startX + RADIUS, startY + RADIUS, clr) end if
        %if (edge & 8) not= 0 then drawfillbox (startX - RADIUS, startY - RADIUS,   endX - RADIUS, startY + RADIUS, clr) end if
    end drawEdges
    
    proc generateMaze (currIdx : int, currNode : ^MazeNode)
        % Recursive Depth first search of maze generation
        
        % Offsets used for direction determination
        const offsets : array 0 .. 3 of int := init (0, 1, 0, -1)
        
        % The direction to walk through
        var dir : int := 0
        % Offset to the next maze node
        var xOff, yOff : int
        % Whether the all of the current node's neighbors have been visited
        var allVisited : boolean := true
        
        cls
        for i : 0 .. upper (mapTiles)
            const tileX : int := i mod width
            const tileY : int := i div width
            
            % Draw map edges
            drawEdges (tileX, tileY, 16)
        end for
            View.Update()
        delay(15)
        
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
    
    proc initMaze (width_, height_ : int)
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
    end initMaze
end Level