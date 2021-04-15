unit
% Useful math functions which are not provided by the Math module
module pervasive MathUtil
    export ~. pervasive all
    
    /**
    * Converts the given cartesian coordinate into a unique angle, in radians
    */
    fcn atan2 (y, x : real) : real
        % Cover -+ PI/2 branches
        if x = 0 then
            % Return 90 * sign (y) (defines x = 0, y = 0 to be 0)
            result sign (y) * Math.PI / 2
        end if
        
        % Cover general branch
        if x > 0 then
            % Normal arctangent
            result arctan (y / x)
        end if
        
        % Cover negative x branch
        if y < 0 then
            result arctan (y / x) + Math.PI
        else
            result arctan (y / x) - Math.PI
        end if
    end atan2
    
    fcn atan2d (y, x : real) : real
        var value : real := atan2 (y, x) * (180 / Math.PI)
        
        if value < 0 then
            value += 360
        end if
        
        result value
    end atan2d
    
    /**
    * Returns the smaller real of the two
    */
    fcn min_f (a, b : real) : real
        if a < b then
            result a
        end if
        result b
    end min_f
    
    /**
    * Returns the larger real of the two
    */
    fcn max_f (a, b : real) : real
        if a > b then
            result a
        end if
        result b
    end max_f
    
    /**
    * Clamps the given value to the given range
    */
    fcn clamp_f (value, minVal, maxVal : real) : real
        if value < minVal then
            result minVal
        end if
        
        if value > maxVal then
            result maxVal
        end if
        
        result value
    end clamp_f
    
    fcn modulo_f (value, modulus : real) : real
        result ((value / modulus) - floor (value / modulus)) %* (value / modulus)
    end modulo_f
end MathUtil