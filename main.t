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
import UI in "lib/ui_util.tu",

% Main classes
PlayerObject in "classes/player.t",
Level in "classes/level.t"


put "3L Tankz: Work in Progress"
setscreen ("graphics:1024;640;offscreenonly")

% Timestep at which the game is updated at
const UPDATE_QUANTUM : int := 1000 div 60

% Whether the game should run or not (handles graceful exits)
var isRunning : boolean := true

% Performance monitoring variables
var ups, fps : int := 0
var lastUps, lastFps : int := 0
var frametimer : int := 0

var player1 : ^PlayerObject
var player2 : ^PlayerObject
var level : ^Level
var prs : boolean := false

proc processInput ()
    var keys : array char of boolean
    Input.KeyDown (keys)
    
    if keys ('z') and not prs then
        level -> rg ()
        prs := true
    elsif not keys ('z') and prs then
        prs := false
    end if
end processInput

proc update (elapsed : int)
    player1 -> update (elapsed)
    player2 -> update (elapsed)
end update

proc render (pt : real)
    colourback (30)
    colour (black)
    cls
    
    level -> setOffset (maxx div 2 - player1 -> posX, maxy div 2 - player1 -> posY)
    level -> render (pt)
    player1 -> render (maxx div 2 - player1 -> posX, maxy div 2 - player1 -> posY, pt)
    player2 -> render (maxx div 2 - player1 -> posX, maxy div 2 - player1 -> posY, pt)

    if Time.Elapsed - frametimer > 1000 then
        lastUps := ups
        lastFps := fps
        
        ups := 0
        fps := 0
        frametimer := Time.Elapsed
    end if
    
    locate (maxrow, 1)
    put lastUps, " ", lastFps..
    
    View.Update ()
end render

proc initGame ()
    new Level, level
    level -> initLevel (11, 5)
    level -> setOffset (maxx div 2, maxy div 2)
    
    new PlayerObject, player1
    player1 -> initObj (0, 0, 0)
    player1 -> setColour (40)
    player1 -> setLevel (level)
    
    new PlayerObject, player2
    player2 -> initObj (0, 0, 0)
    player2 -> setInputScheme ('w', 'a', 's', 'd', 'q')
    player2 -> setColour (32)
    player2 -> setLevel (level)
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