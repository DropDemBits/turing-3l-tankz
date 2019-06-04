%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   [ REDACTED ] - ICS3C Culminating   %
%       2019-06-03 -> 2016-06-17       %
%                                      %
%               3L Tankz               %
%    A multiplayer tank game where     %
%      you try to be the last one      %
%              standing                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Net Arbiter Library
%import NetArbiter in "lib/net-arbiter.tu"
% UI Library
import UI in "lib/ui_util.tu"

put "3L Tankz: Work in Progress"
setscreen ("graphics:1024;640;offscreenonly")

% Timestep at which the game is updated at
const UPDATE_QUANTUM : int := 1000 div 60

% Whether the game should run or not (handles graceful exits)
var isRunning : boolean := true

% Performance monitoring variables
var ups, fps : int := 0
var frametimer : int := 0

forward proc updatePlayer (elapsed : int)
forward proc drawPlayer (pt : real)


proc processInput ()
end processInput

proc update (elapsed : int)
    updatePlayer (elapsed)
end update

proc render (pt : real)
    cls
    
    drawPlayer (pt)

    if Time.Elapsed - frametimer > 1000 then
        locate (1, 1)
        put ups, " ", fps
        
        ups := 0
        fps := 0
        frametimer := Time.Elapsed
    end if
    
    View.Update ()
end render

proc initGame ()
end initGame

proc run ()
    initGame ()

    % Game loop from https://gameprogrammingpatterns.com/game-loop.html#play-catch-up
    var lastTime : int := Time.Elapsed
    var catchup : int := 0
    
    % Enter main game loop
    loop
        var now : int := Time.Elapsed
        var elapsed : int := now - lastTime
        lastTime := now
        catchup += elapsed
        
        % Handle input events
        processInput ()
        
        % Update at a fixed rate
        loop
            % Stop once we've caught up with the lag
            exit when catchup < UPDATE_QUANTUM
            
            update (UPDATE_QUANTUM)
            
            % Decrease the catchup duration
            catchup -= UPDATE_QUANTUM
            
            ups += 1
        end loop
        
        % Draw everything
        % ???: Do we need partialTicks (time in between updates)
        render (catchup / UPDATE_QUANTUM)
        fps += 1
        
        % Handle graceful exit
        exit when not isRunning
    end loop
end run

run ()


%% To be moved into a separate file %%
var plyMag : real := 0
var plyX, plyY : real := 0
var plyAngVel : real := 0
var plyAngle : real := 0
var shooting : boolean := false

body proc drawPlayer
    % Points used for polygon drawing
    var polyX, polyY : array 1 .. 4 of int

    const BASE_WIDTH := 25 / 2
    const BASE_LENGTH := BASE_WIDTH * 1.5 %75 / 2
    
    const BARREL_OFFSET : real := (10 div 2)
    const BARREL_LENGTH : real := (40 div 2) + BARREL_OFFSET
    const BARREL_RADIUS : real := 5 / 2
    
    const HEAD_RADIUS : int := 18 div 2
    
    var effX, effY : real
    effX := plyX + plyMag * cosd (plyAngle)
    effY := plyY + plyMag * sind (plyAngle)

    % Base
    var baseOffX, baseOffY : real := 0
    baseOffX := round(BASE_WIDTH * -sind (plyAngle))
    baseOffY := round(BASE_WIDTH * +cosd (plyAngle))
    
    polyX (1) := round (effX - cosd (plyAngle) * BASE_LENGTH + baseOffX)
    polyX (2) := round (effX + cosd (plyAngle) * BASE_LENGTH + baseOffX)
    polyX (3) := round (effX + cosd (plyAngle) * BASE_LENGTH - baseOffX)
    polyX (4) := round (effX - cosd (plyAngle) * BASE_LENGTH - baseOffX)
    
    polyY (1) := round (plyY - sind (plyAngle) * BASE_LENGTH + baseOffY)
    polyY (2) := round (plyY + sind (plyAngle) * BASE_LENGTH + baseOffY)
    polyY (3) := round (plyY + sind (plyAngle) * BASE_LENGTH - baseOffY)
    polyY (4) := round (plyY - sind (plyAngle) * BASE_LENGTH - baseOffY)

    drawfillpolygon(polyX, polyY, 4, 40 + 24 * 3)
    
    
    % Barrel
    var barrelOffX, barrelOffY : real := 0
    barrelOffX := round(BARREL_RADIUS * -sind (plyAngle))
    barrelOffY := round(BARREL_RADIUS * +cosd (plyAngle))
    
    polyX (1) := round (effX + cosd (plyAngle) * BARREL_OFFSET - barrelOffX)
    polyX (2) := round (effX + cosd (plyAngle) * BARREL_OFFSET + barrelOffX)
    polyX (3) := round (effX + cosd (plyAngle) * BARREL_LENGTH + barrelOffX)
    polyX (4) := round (effX + cosd (plyAngle) * BARREL_LENGTH - barrelOffX)
    
    polyY (1) := round (plyY + sind (plyAngle) * BARREL_OFFSET - barrelOffY)
    polyY (2) := round (plyY + sind (plyAngle) * BARREL_OFFSET + barrelOffY)
    polyY (3) := round (plyY + sind (plyAngle) * BARREL_LENGTH + barrelOffY)
    polyY (4) := round (plyY + sind (plyAngle) * BARREL_LENGTH - barrelOffY)
    
    drawfillpolygon(polyX, polyY, 4, 24)
    
    
    % Head
    drawfilloval (round(effX), round(plyY), HEAD_RADIUS, HEAD_RADIUS, 40)
    
    if shooting then
        locate (5, 1)
        put "pew"
    end if
end drawPlayer

body proc updatePlayer
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
    
    plyMag += nvel
    % Clamp the speed
    if plyMag > 1 then
        plyMag := 1
    elsif plyMag < -1 then
        plyMag := -1
    end if
    
    plyAngVel += nangvel
    % Clamp the angular velocity
    if plyAngVel > 1 then
        plyAngVel := 1
    elsif plyAngVel < -1 then
        plyAngVel := -1
    end if
    
    plyX += plyMag * cosd (plyAngle)
    plyY += plyMag * sind (plyAngle)
    plyAngle += plyAngVel
    
    % Reduce the speed
    if nvel = 0 then
        if abs (plyMag) > 0.001 then
            plyMag *= 0.9
        else
            plyMag := 0
        end if
    end if
    
    % Cancel the angular velocity if the new one is 0
    if nangvel = 0 then
        plyAngVel := 0
    end if
end updatePlayer