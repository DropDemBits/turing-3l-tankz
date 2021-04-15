unit

% Data persistent across various instances of things
module PersistentData
    export ~. var MatchData
    
    % Data persistent across matches
    % Includes wins and other things
    % Data in here is
    % - modified by Match
    % - read by PlayState
    class MatchData
        export var playerWins, initData
        
        % Number of wins by player
        var playerWins : array 0 .. 63 of int
        
        % Sets up the match data
        % Currently only clears player wins
        proc initData ()
            for i : 0 .. upper (playerWins)
                playerWins (i) := 0
            end for
        end initData
    end MatchData
    
end PersistentData