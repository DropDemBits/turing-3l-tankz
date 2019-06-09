% Root Object Class
% Root class for all updatable objects
unit
class Object
    import Level in "level.t"
    export update, render, initObj, setLevel, posX, posY

    % Position & Orientation
    var posX, posY : real := 0
    var angle : real := 0
    
    % Speeds
    var speed : real := 0
    var angularVel : real := 0
    
    % Accelerations
    var acceleration : real := 0
    var angularAccel : real := 0
    
    var level : ^Level := nil
    
    proc initObj (x, y, a : real)
        posX := x
        posY := y
        angle := a
        
        speed := 0
        angularVel := 0
    end initObj
    
    proc setLevel (level_ : ^Level)
        level := level_
    end setLevel
    
    deferred proc update (elapsed : real)
    deferred proc render (offX, offY : real, partialTicks : real)
end Object
