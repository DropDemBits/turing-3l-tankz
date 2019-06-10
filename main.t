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
Match in "classes/match.t",
PersistentData in "classes/persistent.t"


put "3L Tankz: Work in Progress"
setscreen ("graphics:1024;640;offscreenonly,title:3L Tankz,position:center;middle")

% Timestep at which the game is updated at
const UPDATE_QUANTUM : int := 1000 div 60

% Whether the game should run or not (handles graceful exits)
var isRunning : boolean := true

% Performance monitoring variables
var ups, fps : int := 0
var lastUps, lastFps : int := 0
var frametimer : int := 0

% The current game match
var match : ^Match

% Current scores of all players
var playerWins : array 0 .. 63 of int


proc beginMatch ()
    var width, height : int
    
    width := Rand.Int (3, 15)
    height := Rand.Int (5, 9)
    
    % Initialize the match
    new Match, match
    match -> initMatch (width, height)
    
    % Add the players
    match -> addPlayer (0, 40,         0, 0, 'i', 'j', 'k', 'l', 'u')
    match -> addPlayer (1, 54, width - 1, 0, 'w', 'a', 's', 'd', 'q')
    match -> addPlayer (2, 48, width - 1, height - 1, KEY_UP_ARROW, KEY_LEFT_ARROW, KEY_DOWN_ARROW, KEY_RIGHT_ARROW, KEY_CTRL)
end beginMatch

proc processInput ()
    var keys : array char of boolean
    Input.KeyDown (keys)
end processInput

proc update (elapsed : int)
    match -> update (elapsed)
    
    if match -> matchEnded then
        % Add to the winning player's wins
        if match -> winningPlayer not= -1 then
            playerWins (match -> winningPlayer) += 1
        end if
    
        % Restart the match
        match -> freeMatch ()
        free Match, match
        
        beginMatch ()
    end if
end update

proc render (pt : real)
    % Draw the match
    match -> render (pt)
    
    % Draw the player scores
    locate (1, 1)
    put "Wins:" ..
    locate (whatrow + 1, 1)
    
    for i : 0 .. 3
        put "Player ", (i + 1), ": ", playerWins (i) : 3 ..
        locate (whatrow + 1, 1)
    end for
    

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
    beginMatch ()
    
    % Clear all of the player wins
    for i : 0 .. upper (playerWins)
        playerWins (i) := 0
    end for
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
        
        colourback (30)
        colour (black)
        cls
        
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
        
        % Draw everything (calculate update interpolation also)
        render (catchup / (UPDATE_QUANTUM * 1000))
        fps += 1
        
        % Handle graceful exit
        exit when not isRunning
    end loop
end run

run ()