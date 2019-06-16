unit
% Module containing all of the possible game states
% Also handles transitions between game states
module GameStates
    import
            UI in "../lib/ui_util.tu",
            Constants in "../constants.t",
            PersistentData in "persistent.t",
            Match in "match.t",
            InputControllers in "input.t"
    export ~.* var all

    % Base class for all game states
    class pervasive GameState
        export all
        
        % Initializes the GameState's components
        deferred proc initState ()
        % Processes user input
        deferred proc processInput ()
        % Updates the necessary components
        deferred proc update (elapsed : int)
        % Renders the necessary components
        deferred proc render (partialTicks : real)
        % Frees resources related to this GameState
        deferred proc freeState ()
        % Whether the game should be exited or not
        deferred fcn shouldExit () : boolean
    end GameState
    
    % Main menu state
    class MainMenuState
        inherit GameState
        import UI
        
        body proc initState ()
        end initState
        
        % Processes user input
        body proc processInput ()
        end processInput
        
        % Updates the necessary components
        body proc update (elapsed : int)
        end update
        
        % Renders the necessary components
        body proc render (partialTicks : real)
        end render
        
        % Frees resources related to this GameState
        body proc freeState ()
        end freeState
    end MainMenuState
    
    % Play State
    class PlayState
        inherit GameState
        import MatchData, Match, InputControllers
        
        % The current game match
        var match : ^Match
        
        % Colours of every player
        const PLAYER_CLR : array 0 .. 3 of int := init (40, 54, 48, 43)
        % Inputs for all players
        var inputs : array 0 .. 63 of ^InputController
        % Persistent match data
        var matchData_ : ^MatchData := nil
        
        % Camera for drawing the entire match
        var cameraX, cameraY : real := 0
        
        %% Fonts IDs %%
        % Fonts for player info
        var fontPlayerInfo : int
        
        
        % Draws a player tank
        % Starts from the bottom left corner, instead of the centre
        proc drawTank (scale, x, y, angle : real, base_colour : int)
            var effX, effY : real := 0
            effX := x - (cosd (angle) * BASE_LENGTH - BASE_WIDTH * sind (angle)) * scale
            effY := y + (sind (angle) * BASE_LENGTH + BASE_WIDTH * cosd (angle)) * scale
        
            % Points used for polygon drawing
            var polyX, polyY : array 1 .. 4 of int
        
            %% Base %%
            var baseOffX : real := BASE_WIDTH * -sind (angle)
            var baseOffY : real := BASE_WIDTH * +cosd (angle)
            polyX (1) := round (effX + (-cosd (angle) * BASE_LENGTH + baseOffX) * scale)
            polyX (2) := round (effX + (+cosd (angle) * BASE_LENGTH + baseOffX) * scale)
            polyX (3) := round (effX + (+cosd (angle) * BASE_LENGTH - baseOffX) * scale)
            polyX (4) := round (effX + (-cosd (angle) * BASE_LENGTH - baseOffX) * scale)
            polyY (1) := round (effY + (-sind (angle) * BASE_LENGTH + baseOffY) * scale)
            polyY (2) := round (effY + (+sind (angle) * BASE_LENGTH + baseOffY) * scale)
            polyY (3) := round (effY + (+sind (angle) * BASE_LENGTH - baseOffY) * scale)
            polyY (4) := round (effY + (-sind (angle) * BASE_LENGTH - baseOffY) * scale)
        
            drawfillpolygon(polyX, polyY, 4, base_colour + 24 * 3)
            
            
            %% Barrel %%
            var barrelOffX, barrelOffY : real := 0
            barrelOffX := BARREL_RADIUS * -sind (angle)
            barrelOffY := BARREL_RADIUS * +cosd (angle)
            
            polyX (1) := round (effX + (cosd (angle) * BARREL_OFFSET - barrelOffX) * scale)
            polyX (2) := round (effX + (cosd (angle) * BARREL_OFFSET + barrelOffX) * scale)
            polyX (3) := round (effX + (cosd (angle) * BARREL_LENGTH + barrelOffX) * scale)
            polyX (4) := round (effX + (cosd (angle) * BARREL_LENGTH - barrelOffX) * scale)
            polyY (1) := round (effY + (sind (angle) * BARREL_OFFSET - barrelOffY) * scale)
            polyY (2) := round (effY + (sind (angle) * BARREL_OFFSET + barrelOffY) * scale)
            polyY (3) := round (effY + (sind (angle) * BARREL_LENGTH + barrelOffY) * scale)
            polyY (4) := round (effY + (sind (angle) * BARREL_LENGTH - barrelOffY) * scale)
            
            drawfillpolygon(polyX, polyY, 4, 24)
            
            
            %% Head %%
            drawfilloval (round(effX), round(effY), round (HEAD_RADIUS * scale), round(HEAD_RADIUS * scale), base_colour)
        end drawTank
        
        % Begins the game match
        proc beginMatch ()
            var width, height : int
            
            % Have preference for generating big maps
            if Rand.Real > 0.25 then
                width  := Rand.Int (7, 14)
                height := Rand.Int (5, 7)
            else
                width  := Rand.Int (3, 14)
                height := Rand.Int (3, 7)
            end if
            
            % Initialize the match
            cameraX :=  (maxx - width * TILE_SIZE) / 2
            % Have a 100 px region available at the bottom
            cameraY :=  (maxy - height * TILE_SIZE) / 2 + (100 / 2)
            
            new Match, match
            match -> initMatch (width, height)
            match -> setPersistent (matchData_)
            match -> setCamera (cameraX, cameraY)
            
            % Add the players
            match -> addPlayer (0, PLAYER_CLR (0),         0, 0,          inputs (0))
            match -> addPlayer (1, PLAYER_CLR (1), width - 1, 0,          inputs (1))
            match -> addPlayer (2, PLAYER_CLR (2), width - 1, height - 1, inputs (2))
            match -> addPlayer (3, PLAYER_CLR (3),         0, height - 1, inputs (3))
        end beginMatch
        
        body proc initState ()
            % Setup all of the inputs
            for i : 0 .. upper (inputs)
                inputs (i) := nil
            end for
            
            % Setup keyboard input controllers
            for i : 0 .. 2
                new KeyboardController, inputs (i)
                KeyboardController (inputs (i)).initController ()
                KeyboardController (inputs (i)).setScheme (i + 1)
            end for
            
            % Setup mouse controller
            new MouseController, inputs (3)
            MouseController (inputs (3)).initController ()
            MouseController (inputs (3)).setScheme (MOUSE_SCHEME_LEFT)
            
            % Setup match data
            new MatchData, matchData_
            matchData_ -> initData ()
        
            % Setup the match
            beginMatch ()
            
            % Setup the fonts
            fontPlayerInfo := Font.New ("Helvetica:24x12")
        end initState
        
        body proc processInput ()
            for i : 0 .. upper (inputs)
                if inputs (i) not= nil then
                    InputController (inputs (i)).update ()
                end if
            end for
        end processInput
        
        body proc update (elapsed : int)
            match -> update (elapsed)
    
            if match -> matchEnded then            
                % Restart the match
                match -> freeMatch ()
                free Match, match
                
                beginMatch ()
            end if
        end update
        
        body proc render (partialTicks : real)
            % Draw the match
            match -> render (partialTicks)
            
            % Draw the player info
            % Width of one tank score
            const SCORE_WIDTH : int := (BASE_WIDTH * 4) + 80
            const SCORE_CENTRE_OFF : int := (maxx - SCORE_WIDTH * 4) div 2
            
            for i : 0 .. 3                
                % Draw the player tanks
                var tankX : int := round(SCORE_WIDTH * i + SCORE_CENTRE_OFF)
                % Hidden muldiv 2 at the end
                var tankY : int := (cameraY - BASE_LENGTH * 4) div 2
                
                % Draw the player tank
                drawTank (2, tankX, tankY, 90, PLAYER_CLR (i))
                
                % Show the player wins
                Font.Draw (intstr (matchData_ -> playerWins (i)),
                           tankX + BASE_WIDTH * 4 + 10,
                           tankY + BASE_LENGTH * 2,
                           fontPlayerInfo,
                           18)
            end for
        end render
        
        body proc freeState ()
            match -> freeMatch ()
            free match
        end freeState
    end PlayState
end GameStates