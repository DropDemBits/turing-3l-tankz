unit
% Module containing all of the possible game states
module GameStates
    class pervasive GameState
        deferred proc initState ()
        deferred proc processInput ()
        deferred proc update (elapsed : int)
        deferred proc render (partialTicks : real)
    end GameState
    
    class PlayState
        inherit GameState
        
        body proc initState ()
        end initState
        
        body proc update (elapsed : int)
        end update
        
        body proc render (partialTicks : real)
        end render
        
    end PlayState
end GameStates