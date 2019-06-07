% Object Classes
class Object
    export update, render, initObj

    var posX, posY : real
    var angle : real
    
    var speed : real
    var angularVel : real
    
    proc initObj (x, y, a : real)
        posX := x
        posY := y
        angle := a
        
        speed := 0
        angularVel := 0
    end initObj
    
    deferred proc update (elapsed : real)
    deferred proc render (partialTicks : real)
end Object

class PlayerObject
    inherit Object
    import Input
    export setInputScheme, setColour
    
    var shooting : boolean := false
    
    var key_forward     : char := 'i'
    var key_left        : char := 'j'
    var key_backward    : char := 'k'
    var key_right       : char := 'l'
    var key_shoot       : char := 'u'
    
    var base_colour     : int := 40
    
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
    
    body proc render
        % Points used for polygon drawing
        var polyX, polyY : array 1 .. 4 of int
    
        const BASE_WIDTH := 25 / 2
        const BASE_LENGTH := BASE_WIDTH * 1.5 %75 / 2
        
        const BARREL_OFFSET : real := (10 div 2)
        const BARREL_LENGTH : real := (40 div 2) + BARREL_OFFSET
        const BARREL_RADIUS : real := 5 / 2
        
        const HEAD_RADIUS : int := 18 div 2
        
        var effX, effY, effAngle : real
        effAngle := angle + angularVel * partialTicks
        effX := posX + speed * cosd (effAngle) * partialTicks
        effY := posY + speed * sind (effAngle) * partialTicks
    
        % Base
        var baseOffX, baseOffY : real := 0
        baseOffX := round(BASE_WIDTH * -sind (effAngle))
        baseOffY := round(BASE_WIDTH * +cosd (effAngle))
        
        polyX (1) := round (effX - cosd (effAngle) * BASE_LENGTH + baseOffX)
        polyX (2) := round (effX + cosd (effAngle) * BASE_LENGTH + baseOffX)
        polyX (3) := round (effX + cosd (effAngle) * BASE_LENGTH - baseOffX)
        polyX (4) := round (effX - cosd (effAngle) * BASE_LENGTH - baseOffX)
        polyY (1) := round (effY - sind (effAngle) * BASE_LENGTH + baseOffY)
        polyY (2) := round (effY + sind (effAngle) * BASE_LENGTH + baseOffY)
        polyY (3) := round (effY + sind (effAngle) * BASE_LENGTH - baseOffY)
        polyY (4) := round (effY - sind (effAngle) * BASE_LENGTH - baseOffY)
    
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
        
        if shooting then
            locate (5, 1)
            put "pew ", base_colour
        end if
    end render

    body proc update
        var keys : array char of boolean
        Input.KeyDown (keys)
        
        var nvel, nangvel : real := 0
        
        if keys (key_forward) then
            nvel += 0.0625
        end if
        if keys (key_backward) then
            nvel -= 0.0625
        end if
        
        if keys (key_left) then
            nangvel += 0.0625
        end if
        if keys (key_right) then
            nangvel -= 0.0625
        end if
        
        shooting := keys (key_shoot)
        
        speed += nvel
        % Clamp the speed
        if speed > 1 then
            speed := 1
        elsif speed < -1 then
            speed := -1
        end if
        
        angularVel += nangvel
        % Clamp the angular velocity
        if angularVel > 1 then
            angularVel := 1
        elsif angularVel < -1 then
            angularVel := -1
        end if
        
        posX += speed * cosd (angle)
        posY += speed * sind (angle)
        angle += angularVel
        
        % Reduce the speed
        if nvel = 0 then
            if abs (speed) > 0.001 then
                speed *= 0.9
            else
                speed := 0
            end if
        end if
        
        % Cancel the angular velocity if the new one is 0
        if nangvel = 0 then
            angularVel := 0
        end if
    end update
end PlayerObject
