unit
%%% Constants %%%
% All the constants used in this program
module Constants
    export ~.*all
    
    % Level tile size
    const TILE_SIZE : real := 68
    
    %%% Tank Drawing Constants %%%
    % Constants for the base
    const BASE_WIDTH : int := 25 div 2
    const BASE_LENGTH : int := floor(BASE_WIDTH * 1.5)
    
    % Constants for the barrel
    const BARREL_OFFSET : real := (10 div 2)
    const BARREL_LENGTH : real := (40 div 2) + BARREL_OFFSET
    const BARREL_RADIUS : real := 5 div 2
    
    % Radius of the head station
    const HEAD_RADIUS : int := 18 div 2
end Constants