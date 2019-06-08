% Root Object Class
% Root class for all updatable objects
unit
class Object
    import Level in "level.t"
    export update, render, initObj, setLevel, posX, posY

    var posX, posY : real
    var angle : real
    
    var speed : real
    var angularVel : real
    
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
