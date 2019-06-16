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
import 
    % Main classes
    PersistentData in "classes/persistent.t",
    GameStates in "classes/state.t"


put "3L Tankz: Work in Progress"
setscreen ("graphics:1024;640;offscreenonly,title:3L Tankz,position:center;middle")

% Timestep at which the game is updated at
const UPDATE_QUANTUM : real := 15%1000 / 60

% Whether the game should run or not (handles graceful exits)
var isRunning : boolean := true

% Performance monitoring variables
var ups, fps : int := 0
var lastUps, lastFps : int := 0
var frametimer : int := 0

% Current Play state
var currentState : ^GameState := nil
var playState : ^PlayState
var menuState : ^MainMenuState


proc processInput ()
    currentState -> processInput ()
end processInput

proc update (elapsed : int)
    currentState -> update (elapsed)
end update

proc render (pt : real)
    currentState -> render (pt)
    
    % Update frames & updates per second
    if Time.Elapsed - frametimer > 1000 then
        lastUps := ups
        lastFps := fps
        
        ups := 0
        fps := 0
        frametimer := Time.Elapsed
    end if
    
    % Print out FPS & UPS
    colourback (black)
    colour (white)
    locate (maxrow, 1)
    put lastUps, " ", lastFps..
    
    View.Update ()
end render

proc initGame ()
    % Setup multi-button input
    Mouse.ButtonChoose("multibutton")
    
    % Initialize the play state
    new PlayState, playState
    playState -> initState ()
    
    currentState := playState
end initGame

proc run ()
    initGame ()

    % Game loop from https://gameprogrammingpatterns.com/game-loop.html#play-catch-up
    var lastTime : int := Time.Elapsed
    var catchup : real := 0
    
    % Enter main game loop
    loop
        var now : int := Time.Elapsed
        var elapsed : int := now - lastTime
        lastTime := now
        catchup += elapsed
        
        colourback (28)
        colour (white)
        cls
        
        % Handle input events
        processInput ()
        
        % Update at a fixed rate
        loop
            % Stop once we've caught up with the lag
            exit when catchup < UPDATE_QUANTUM
            
            update (floor(UPDATE_QUANTUM))
            
            % Decrease the catchup duration
            catchup -= UPDATE_QUANTUM
            
            ups += 1
        end loop
        
        % Draw everything (calculate update interpolation also)
        render (catchup / (UPDATE_QUANTUM * 1000))
        fps += 1
        
        %loop exit when hasch end loop
        %Input.Flush ()
        
        % Handle graceful exit
        exit when not isRunning
    end loop
    
    % Free all resources
    playState -> freeState ()
end run

run ()