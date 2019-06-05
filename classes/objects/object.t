% Object Classes
class Object
    var posX, posY : real
    var angle : real
    
    var speed : real
    var angularVel : real
    
    deferred proc update (elapsed : real)
    deferred proc render (partialTicks : real)
end Object

class PlayerObject
    import Input
    inherit Object
    
    var shooting : boolean
    
    body proc render
    % Points used for polygon drawing
    var polyX, polyY : array 1 .. 4 of int

    const BASE_WIDTH := 25 / 2
    const BASE_LENGTH := BASE_WIDTH * 1.5 %75 / 2
    
    const BARREL_OFFSET : real := (10 div 2)
    const BARREL_LENGTH : real := (40 div 2) + BARREL_OFFSET
    const BARREL_RADIUS : real := 5 / 2
    
    const HEAD_RADIUS : int := 18 div 2
    
    var effX, effY : real
    effX := posX + speed * cosd (angle)
    effY := posY + speed * sind (angle)

    % Base
    var baseOffX, baseOffY : real := 0
    baseOffX := round(BASE_WIDTH * -sind (angle))
    baseOffY := round(BASE_WIDTH * +cosd (angle))
    
    polyX (1) := round (effX - cosd (angle) * BASE_LENGTH + baseOffX)
    polyX (2) := round (effX + cosd (angle) * BASE_LENGTH + baseOffX)
    polyX (3) := round (effX + cosd (angle) * BASE_LENGTH - baseOffX)
    polyX (4) := round (effX - cosd (angle) * BASE_LENGTH - baseOffX)
    polyY (1) := round (effY - sind (angle) * BASE_LENGTH + baseOffY)
    polyY (2) := round (effY + sind (angle) * BASE_LENGTH + baseOffY)
    polyY (3) := round (effY + sind (angle) * BASE_LENGTH - baseOffY)
    polyY (4) := round (effY - sind (angle) * BASE_LENGTH - baseOffY)

    drawfillpolygon(polyX, polyY, 4, 40 + 24 * 3)
    
    
    % Barrel
    var barrelOffX, barrelOffY : real := 0
    barrelOffX := round(BARREL_RADIUS * -sind (angle))
    barrelOffY := round(BARREL_RADIUS * +cosd (angle))
    
    polyX (1) := round (effX + cosd (angle) * BARREL_OFFSET - barrelOffX)
    polyX (2) := round (effX + cosd (angle) * BARREL_OFFSET + barrelOffX)
    polyX (3) := round (effX + cosd (angle) * BARREL_LENGTH + barrelOffX)
    polyX (4) := round (effX + cosd (angle) * BARREL_LENGTH - barrelOffX)
    polyY (1) := round (effY + sind (angle) * BARREL_OFFSET - barrelOffY)
    polyY (2) := round (effY + sind (angle) * BARREL_OFFSET + barrelOffY)
    polyY (3) := round (effY + sind (angle) * BARREL_LENGTH + barrelOffY)
    polyY (4) := round (effY + sind (angle) * BARREL_LENGTH - barrelOffY)
    
    drawfillpolygon(polyX, polyY, 4, 24)
    
    
    % Head
    drawfilloval (round(effX), round(effY), HEAD_RADIUS, HEAD_RADIUS, 40)
    
    if shooting then
        locate (5, 1)
        put "pew"
    end if
end render

body proc update
    var keys : array char of boolean
    Input.KeyDown (keys)
    
    var nvel, nangvel : real := 0
    
    if keys ('i') then
        nvel += 0.0625
    end if
    if keys ('k') then
        nvel -= 0.0625
    end if
    
    if keys ('j') then
        nangvel += 0.0625
    end if
    if keys ('l') then
        nangvel -= 0.0625
    end if
    
    shooting := keys ('u')
    
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
