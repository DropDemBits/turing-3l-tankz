unit
% Module containing everything related to input
module InputControllers
    import
        MathUtil in "../lib/math_util.tu",
        PlayerObject in "objects/player.t",
        Level in "level.t"
    export ~. var all
    
    % Controller types
    const pervasive CONTROL_TYPE_KEYBOARD : int := 0
    const pervasive CONTROL_TYPE_MOUSE : int := 1
    const pervasive CONTROL_TYPE_AI : int := 2
    
    % Keyboard Control Schemes
    const pervasive KEY_SCHEME_WSAD  : int := 1
    const pervasive KEY_SCHEME_IKJL  : int := 2
    const pervasive KEY_SCHEME_ARROW : int := 3
    
    % Mouse Control Schemes
    const pervasive MOUSE_SCHEME_LEFT  : int := 1
    const pervasive MOUSE_SCHEME_RIGHT : int := 2
    
    class pervasive InputController
        import PlayerObject
        export initController, update, setScheme, setPlayer, getPlayer
   
        %%% Runtime Variables %%%
        % Player controlled by this input controller
        var player_ : ^PlayerObject := nil
        % Type and scheme of this input controller
        var controlType_, controlScheme_ : int
        
        
        %%% Overridable Methods %%%
        deferred proc initController ()
        deferred proc onSchemeChange (scheme : int)
        deferred proc update ()
        
        
        %%% Setters & Getters %%%
        proc setScheme (scheme : int)
            controlScheme_ := scheme
            % Alert of an input scheme change
            onSchemeChange (scheme)
        end setScheme
        
        proc setPlayer (player : ^PlayerObject)
            player_ := player
        end setPlayer
        
        fcn getPlayer () : ^PlayerObject
            result player_
        end getPlayer
    end InputController
    
    class pervasive KeyboardController
        inherit InputController
        import Input
        
        %%% Constants %%%
        const SCHEMES : array 1 .. 3, 1 .. 5 of char := init (
            % Scheme 1: WSAD
            'w', 's', 'a', 'd', 'q',
            % Scheme 2: IKJL
            'i', 'k', 'j', 'l', 'u',
            % Scheme 3: Arrows + Control
            KEY_UP_ARROW, KEY_DOWN_ARROW, KEY_LEFT_ARROW, KEY_RIGHT_ARROW, KEY_CTRL,
        )
        
        %%% Runtime Variables %%%
        var key_forward  : char := SCHEMES (KEY_SCHEME_WSAD, 1)
        var key_backward : char := SCHEMES (KEY_SCHEME_WSAD, 2)
        var key_left     : char := SCHEMES (KEY_SCHEME_WSAD, 3)
        var key_right    : char := SCHEMES (KEY_SCHEME_WSAD, 4)
        var key_shoot    : char := SCHEMES (KEY_SCHEME_WSAD, 5)
        
        
        %%% Implemented Methods %%%
        body proc initController ()
            % WASD is default scheme
            setScheme (KEY_SCHEME_WSAD)
        end initController
        
        body proc onSchemeChange
            if scheme < KEY_SCHEME_WSAD or scheme > KEY_SCHEME_ARROW then
                % Scheme index out of bounds
                return
            end if
            
            % Setup the scheme
            key_forward  := SCHEMES (scheme, 1)
            key_backward := SCHEMES (scheme, 2)
            key_left     := SCHEMES (scheme, 3)
            key_right    := SCHEMES (scheme, 4)
            key_shoot    := SCHEMES (scheme, 5)
        end onSchemeChange
        
        body proc update
            % Don't update if there is no player
            if player_ = nil then
                return
            end if
        
            % Acquire current snapshot of keys
            var keys : array char of boolean
            Input.KeyDown (keys)
            
            % Get new acceleration
            var lineAccel, angleAccel : real := 0
            
            if keys (key_forward) then
                lineAccel += player_ -> MOVEMENT_SPEED / 20
            end if
            if keys (key_backward) then
                lineAccel -= player_ -> MOVEMENT_SPEED / 20
            end if
            
            if player_ -> speed = 0 then
                if keys (key_left) then
                    angleAccel += player_ -> ROTATE_SPEED / 20
                end if
                if keys (key_right) then
                    angleAccel -= player_ -> ROTATE_SPEED / 20
                end if
            else
                if keys (key_left) then
                    angleAccel += player_ -> ROTATE_SPEED / 24
                end if
                if keys (key_right) then
                    angleAccel -= player_ -> ROTATE_SPEED / 24
                end if
            end if
            
            % Get new shooting status
            player_ -> setShootingState (keys (key_shoot))
            
            % Apply new acceleration
            player_ -> setAccel (lineAccel, angleAccel)
        end update
    end KeyboardController
    
    class pervasive MouseController
        inherit InputController
        import Level, Mouse %, atan2d, clamp_f
        
        %%% Constants %%%
        const BUTTON_LEFT  : int :=   1
        const BUTTON_RIGHT : int := 100
        
        
        %%% Runtime Variables %%%
        var shoot_button : int := BUTTON_LEFT
        
        var lastAngle : real := 0
        var destAngle : real := 0
        
        fcn lerp (a, b, t : real) : real
            result (1 - t) * a + t * b
        end lerp
        
        %%% Implemented Methods %%%
        body proc initController
            % Left mouse button is default scheme
            setScheme (MOUSE_SCHEME_LEFT)
        end initController
        
        body proc setScheme
            if scheme < MOUSE_SCHEME_LEFT or scheme > MOUSE_SCHEME_RIGHT then
                % Scheme index out of bounds
            end if
            
            case scheme of
            label MOUSE_SCHEME_LEFT  : shoot_button := BUTTON_LEFT
            label MOUSE_SCHEME_RIGHT : shoot_button := BUTTON_RIGHT
            label : % Nothing
            end case
        end setScheme
        
        body proc update
            % Get snapshot of mouse state
            var mouseX, mouseY : real := 0
            var mX, mY, mouseButton : int
            Mouse.Where (mX, mY, mouseButton)
            
            if (mX < 0 or mX > maxx or mY < 0 or mY > maxy) or Window.GetSelect () = -1 then
                % Don't update if the mouse is outside of the screen
                player_ -> setAccel (0, 0)
                return
            end if
            
            % Convert screen coordinates into world coordinates
            mouseX := (mX - player_ -> level -> cameraX) / Level.TILE_SIZE
            mouseY := (mY - player_ -> level -> cameraY) / Level.TILE_SIZE
            
            % Calculate deltas from the player
            var deltaX, deltaY, deltaDist, deltaAngle : real
            var effAngle : real := player_ -> angle
            
            if effAngle > 180 then
                effAngle := effAngle - 360
            end if
            
            deltaX     := mouseX - (player_ -> posX + cosd (player_ -> angle) * 0 * (player_ -> BARREL_LENGTH / Level.TILE_SIZE))
            deltaY     := mouseY - (player_ -> posY + sind (player_ -> angle) * 0 * (player_ -> BARREL_LENGTH / Level.TILE_SIZE))
            deltaDist  := sqrt (deltaX ** 2 + deltaY ** 2)
            
            deltaAngle := (atan2d (deltaY, deltaX) - effAngle)
            
            % Map the delta angle to [-180, 180]
            if deltaAngle > 180 then
                deltaAngle := deltaAngle - 360
            elsif deltaAngle < -180 then
                deltaAngle :=  deltaAngle + 360
            end if
            
            % Stop rotating once we're within a certain distance of the goal
            if abs (deltaAngle) < 4 then
                deltaAngle := 0
            end if
            
            % Stop accelerating once we're within a certain distance of the goal
            if abs (deltaDist) < 0.4 then
                deltaDist := 0
            end if
            
            % Flip the speed around if the destination is behind us
            if abs (deltaAngle) > 90 then
                deltaDist := -deltaDist
            end if
            
            % Calculate the accelerations
            var lineAccel, angleAccel : real := 0
            lineAccel  := clamp_f (deltaDist / 20,  -player_ -> MOVEMENT_SPEED / 20, player_ -> MOVEMENT_SPEED / 20)
            angleAccel := clamp_f (deltaAngle, -player_ -> ROTATE_SPEED / 8,   player_ -> ROTATE_SPEED / 8)
            
            % Apply the accelerations
            % Initially only apply rotation acceleration
            player_ -> setAccel (0, angleAccel)
            
            if mouseButton = 100 then
                % Speed along once the mouse button is down
                player_ -> setAccel (lineAccel, angleAccel)
            end if
            
            % Update the shooting state
            player_ -> setShootingState (mouseButton = 1)
        end update
    end MouseController
    
end InputControllers