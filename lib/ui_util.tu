% [ REDACTED ] - UI Utilities
% 2019-06-17
% Version 1.1
% Basic framework for UI elements

unit

module UI
    export ~. UIAnchors,
        ~. MOUSE_RELEASED, ~. MOUSE_PRESSED, ~. MOUSE_CLICKED,
        ~. EVENT_PROPAGATE, ~. EVENT_CONSUME,
        ~. EVT_NONE, ~. EVT_MOUSE_BUTTON, ~. EVT_MOUSE_MOVE,
        ~. var UIEvent, ~. var UIElement,
        ~. var UIButton
    
    %% Mouse button states %%
    const pervasive MOUSE_RELEASED : int := 0
    const pervasive MOUSE_PRESSED  : int := 1
    % The mouse only enters this state when the button was pressed and was just released
    % This is similar to a "downup" transition for buttonwait
    const pervasive MOUSE_CLICKED  : int := 2
    
    
    %% Event handling types %%
    const pervasive EVENT_CONSUME   : int := 0
    const pervasive EVENT_PROPAGATE : int := 1
    % Internal use only
    const pervasive EVENT_HANDLED   : int := 2
    
    %% UI Events %%
    % Special type: means that the current event isn't valid or has been nulled
    const pervasive EVT_NONE : int := -1
    % Mouse button change
    const pervasive EVT_MOUSE_BUTTON : int := 0
    % Mouse moved
    const pervasive EVT_MOUSE_MOVE : int := 1
    % Last valid event number
    const pervasive EVT_LAST : int := EVT_MOUSE_MOVE
    
    /*
    * UI Anchors: relative anchor points specifiers
    *
    * START:  Corresponds to the LEFT or BOTTOM points
    * CENTRE: Corresponds to the CENTRE points
    * END:    Corresponds to the RIGHT or TOP points
    */
    type pervasive UIAnchors : enum (
        START,
        CENTRE,
        END)
    
    /**
    * UIEvent: Container for a UI event
    * Valid event types are specified in the EVT_* constants
    */
    class pervasive UIEvent
        export evtType, var evtData, ChangeType
        
        % Data for all of the events
        % Once the data has been setup, the data must be treated as immutable
        % so that child elements recieve the event in the correct state.
        type eventDatas :
            union : EVT_MOUSE_BUTTON .. EVT_LAST of
                label EVT_MOUSE_BUTTON:
                    % Mouse button change
                    bt_x, bt_y      : int  % Current mouse position
                    bt_button       : int  % Current mouse buttons
                    bt_state        : int  % Current button state (pressed, released, clicked)
                label EVT_MOUSE_MOVE:
                    % Mouse movement
                    mv_x, mv_y      : int       % New mouse position
                    mv_dx, mv_dy    : int       % Change in mouse position
                    mv_dragged      : boolean   % Whether the mouse was dragged
                label :
                    % Nothing for the nothing tag
            end union
        
        % Type of event this is
        var evtType : int := -1
        % Data for the current event
        var evtData : eventDatas
        
        /**
        * Changes the type of the current event
        *
        * Destroys the previous event data and transforms it into the new type.
        * If the type requested is EVT_NONE, the current event instance will be
        * made unusable until the next call to ChangeType
        *
        * Parameters:
        * type_: The type of event to change itself into
        */
        procedure ChangeType ( type_ : int)
            evtType := type_
            
            if type_ not= EVT_NONE then
                % Change the tage of the event data
                tag evtData, type_
            end if
        end ChangeType
    end UIEvent
    
    /*
    * UIElement: Base UIElement class
    */
    class pervasive UIElement
        export 
            % Functions
            ProcessElementInput, Render, Update, AddChild, InitElement,
            % Setters
            SetRenderer, SetMouseButtonCallback,
            % Variables
            posX, posY, width, height,
            var parent, var children, var sibling
        
        %%% Type Declerations %%%
        type onMouseButtonCallback : function mouseCallback (self_ : ^ UIElement, 
                                                             x, y,
                                                             button,
                                                             state : int) : int
        type customRenderer : procedure customRender (self_ : ^ UIElement)
    
    
        %%% Variable Declerations %%%
        % Real position of the element (in px)
        var posX, posY : int
        % Real dimensions of the element (in px)
        var width, height : int
        
        %% Callbacks %%
        % Callback called when the button is pressed, released, or clicked by the mouse
        var onMouseButton : onMouseButtonCallback
        var hasCallback : boolean := false
        
        %% Customization %%
        var renderer : customRenderer
        var hasCustomRenderer : boolean := false
        
        %% Element Hierarchy %%
        % Parent of this UI element. Can be nil to represent the root element
        var parent : ^ UIElement := nil
        % Beginning of the list of children. Rendered from first to last
        var children : ^ UIElement := nil
        % Next child in the parent's list of children. 'nil' marks that this is
        % the last element in the list
        var sibling : ^ UIElement := nil
        
        %% Misc %%
        % Set to true if the mouse cursor is or was (respectively) inside of this
        % element. Used to change the mouse movement event state to as appropriate.
        var isMouseInside, wasMouseInside : boolean := false
        
        
        %%% Element overrideable behaviour %%%
        % Handles element-specific input events
        deferred function ProcessInput (evt : ^ UIEvent) : int
        
        % Default renderer of the UIElement
        deferred procedure DoRender (offX, offY : int)
        
        deferred procedure DoUpdate ()
        
        %%% Default element behaviour %%%
        body function ProcessInput
            % Do nothing
            result EVENT_PROPAGATE
        end ProcessInput
        
        body procedure DoUpdate
            % Do nothing
        end DoUpdate
        
        body procedure DoRender
            % Draw nothing
        end DoRender
        
        
        %%% Private Functions %%%
        
        /**
        * Initializes the current element at the specified position and dimensions
        */
        procedure InitElement (x_, y_, width_, height_ : int)
            posX := x_
            posY := y_
            width := width_
            height := height_
        end InitElement
        
        %%% Setters %%%
        
        /**
        * Sets the custom renderer of the element
        */
        procedure SetRenderer (renderer_ : customRenderer)
            renderer := renderer_
            hasCustomRenderer := true
        end SetRenderer
        
        /**
        * Sets the mouse button callback of the element
        */
        procedure SetMouseButtonCallback (buttonCallback : onMouseButtonCallback)
            onMouseButton := buttonCallback
            hasCallback := true
        end SetMouseButtonCallback
        
        
        %%% Main Public Functions %%%
        
        /**
        * Adds a child element to the current element
        */
        procedure AddChild (child : ^ UIElement)
            % Basic checks
            % Element can't be children to two different parents
            assert child -> parent = nil
            
            % Setup links
            child -> sibling := children
            child -> parent := self
            
            % Append to list
            children := child
        end AddChild
        
        /**
        * Updates the variables related to mouse entry & exit
        * 
        * Parameters:
        * evt:      The mouse movement event data
        */
        procedure UpdateMouseEntryState (evt : ^ UIEvent)
            if evt -> evtType not= EVT_MOUSE_MOVE and evt -> evtType not= EVT_MOUSE_BUTTON then
                % Only update when it's a mouse input event
                return
            end if
            
            % Current position of the mouse
            var x, y : int
            
            % Acquire the current position of the mouse pointer
            if evt -> evtType = EVT_MOUSE_BUTTON then
                x := evt -> evtData.bt_x
                y := evt -> evtData.bt_y
            elsif evt -> evtType = EVT_MOUSE_MOVE then
                x := evt -> evtData.mv_x
                y := evt -> evtData.mv_y
            end if
            
            % Update 'isMouseInside' and 'wasMouseInside'
            wasMouseInside := isMouseInside
            isMouseInside := x >= posX and x <= posX + width and y >= posY and y <= posY + height
        end UpdateMouseEntryState
        
        /**
        * Checks if the event should be handled.
        * Currently used only for mouse-related events
        *
        * Parameters:
        * evt:      The event to check for
        *
        * Returns:
        * EVENT_PROPAGATE if the event should be propagated,
        * EVENT_CONSUME if the event should be consumed
        */
        function ShouldHandleEvent (evt : ^ UIEvent) : boolean
            var evtType : int := evt -> evtType
        
            case evtType of
            label EVT_MOUSE_BUTTON, EVT_MOUSE_MOVE:
            
                % Ignore events outside of the button
                if not isMouseInside and not wasMouseInside then
                    result false
                end if
                
            label :
                % Do nothing
            end case
            
            % Always handle by default
            result true
        end ShouldHandleEvent
        
        /**
        * Processes external events
        *
        * Returns true if the event should be propagated, false if it should be
        * consumed
        */
        function ProcessElementInput (evt : ^ UIEvent) : int
            var propagateEvent : int
            
            UpdateMouseEntryState (evt)
            
            % Check if the event should be handled
            if not ShouldHandleEvent (evt) then
                result EVENT_PROPAGATE
            end if
            
            % Allow for element specific behaviour
            propagateEvent := ProcessInput (evt)
            
            % Check if the event was consumed
            if propagateEvent = EVENT_CONSUME then
                result EVENT_CONSUME
            end if
            
            
            % Propagate to handler
            if hasCallback then
                if evt -> evtType = EVT_MOUSE_BUTTON then
                    propagateEvent := onMouseButton (self,
                                                evt -> evtData.bt_x,
                                                evt -> evtData.bt_y,
                                                evt -> evtData.bt_button,
                                                evt -> evtData.bt_state)
                end if
            
                % Check if the event was consumed
                if propagateEvent = EVENT_CONSUME then
                    result EVENT_CONSUME
                end if
            end if
            
            
            % Propagate events to children
            var child : ^ UIElement := children
            
            loop
                exit when child = nil
                
                propagateEvent := child -> ProcessElementInput (evt)
                
                % Check if the event was consumed
                if propagateEvent = EVENT_CONSUME then
                    result EVENT_CONSUME
                end if
                
                % Move to next child
                child := child -> sibling
            end loop
            
            % Propagate event by default
            result EVENT_PROPAGATE
        end ProcessElementInput
        
        /**
        * Renders the element.
        * The offset passed through is the real position of the parent
        */
        procedure Render (offX, offY : int)
            if hasCustomRenderer then
                renderer (self)
                return
            end if
        
            % Render self
            DoRender (offX, offY)
            
            % Render children
            var child : ^ UIElement := children
            
            loop
                exit when child = nil
                
                child -> Render (offX + posX, offY + posY)
                child := child -> sibling
            end loop
        end Render
        
        /**
        * Updates the element
        */
        procedure Update ()
            % Update self
            DoUpdate ()
            
            % Update children
            var child : ^ UIElement := children
            
            loop
                exit when child = nil
                
                child -> Update ()
                child := child -> sibling
            end loop
        end Update
    end UIElement
    
    /*
    * UIButton: Implementation of a button
    */
    class pervasive UIButton
        inherit UIElement
        export Init, SetPressible, text
        
        %%% Constant Declerations %%%
        const DEFAULT_TEXT : int := white
        const DEFAULT_DISABLED_TEXT : int := gray
        
        % Mid-gray
        const DEFAULT_BACKGROUND : int := 24
        % Dark gray
        const DEFAULT_DISABLED_BACKGROUND : int := 22
        % Brighter gray
        const DEFAULT_HIGHLIGHTED_BACKGROUND : int := 26
        % Semi-dark gray
        const DEFAULT_PRESSED_BACKGROUND : int := 20
        
        %%% Variable Declerations %%%
        
        %% Text related %%
        % Text of the button
        var text : string
        % Text drawing offset (from real position, in px)
        var textX, textY : int
        % Font to be used for drawing
        var buttonFont : int
        
        %% Mouse Related %%
        % Whether the button can be pressed. True by default
        var canPress : boolean := true
        % Whether the button is currently pressed
        var isPressed : boolean := false
        % Whether the button is currently highlighted
        var isHighlighted : boolean := false
        
        %% Customization %%
        % Normal colour of the text.
        var textColour : int := DEFAULT_TEXT
        % Colour of the text when the button is disabled. 
        var disabledTextColour : int := DEFAULT_DISABLED_TEXT
        
        % Normal background colour of the button.
        var backgroundColour : int := DEFAULT_BACKGROUND
        % Background colour of the button when it's disabled.
        var disabledColour : int := DEFAULT_DISABLED_BACKGROUND
        % Background colour of the button when it's highlighted.
        var highlightedColour : int := DEFAULT_HIGHLIGHTED_BACKGROUND
        % Background colour of the button when it's pressed.
        var pressedColour : int := DEFAULT_PRESSED_BACKGROUND
        
        %%% Private Functions %%%
        body function ProcessInput
            if not canPress then
                % Just consume events if the button can't be pressed
                result EVENT_CONSUME
            end if
            
            if evt -> evtType = EVT_MOUSE_MOVE then
                % Check mouse movement conditions
                if not isMouseInside and wasMouseInside then
                    % Consume the mouse exit (ignore return value) if the mouse
                    % was moved outside of the button
                    
                    % Button state should always be 0 on a release event
                    var ignored : int := onMouseButton (self, evt -> evtData.mv_x, evt -> evtData.mv_y, 0, MOUSE_RELEASED)
                    
                    % Reset pressed % highlighted state
                    isPressed := false
                    isHighlighted := false
                    
                    result EVENT_CONSUME
                elsif isMouseInside and not wasMouseInside then
                    % Highlight the button on mouse entry
                    isHighlighted := true
                end if
            end if
            
            if evt -> evtType not= EVT_MOUSE_BUTTON then
                % Propagte all other events
                result EVENT_PROPAGATE
            end if
            
            % By this point, it's guarrenteed that the mouse pointer is inside
            % the bounds of the element
            
            % Update button pressed state
            if evt -> evtData.bt_state = MOUSE_PRESSED then
                % Mouse button was pressed
                
                % Make the button pressed
                isPressed := true
            elsif evt -> evtData.bt_state = MOUSE_RELEASED and isPressed then
                % Mouse was released, but is still inside of the button
            
                % Make the button unpressed
                isPressed := false
                
                % Enter the highlighted state
                isHighlighted := true
            elsif evt -> evtData.bt_state = MOUSE_RELEASED and not isPressed then
                % Mouse button was released outside of the button
            
                % Don't allow for phantom releases
                % Also prevents the click event from being fired
                result EVENT_CONSUME
            end if
            
            % Propagate by default
            result EVENT_PROPAGATE
            
        end ProcessInput
        
        /**
        * Renders the button onto the screen.
        */
        body procedure DoRender
            % Foreground = text, Background = background
            var backgroundColour : int := backgroundColour
            var foregroundColour : int := textColour
            
            if not canPress then
                % Darken button to indicate that it can't be pressed
                backgroundColour := disabledColour
                foregroundColour := disabledTextColour
            elsif isPressed then
                % Set the background colour to the pressed one
                backgroundColour := pressedColour
            elsif isHighlighted then
                % Set the background colour to the highlighted one
                backgroundColour := highlightedColour
            end if
            
            % Background
            drawfillbox (posX, posY, posX + width, posY + height, backgroundColour)
            
            % Text                        
            Font.Draw (text, posX + textX, posY + textY, buttonFont, foregroundColour)
            
        end DoRender
        
        /**
        * Updates the button state.
        */
        body procedure DoUpdate
        end DoUpdate
        
        %%% Exported Functions %%%
        /**
        * Creates a single button with the specified arguments
        * The parameters contribute to drawing the button like this:
        * <----[width]--->
        *
        * ----------------    ^
        * |              |    |
        * |  ----------  |    |
        * |  | [text] |  |    | [height]
        * |  ----------  |    |
        * |              |    |
        * +---------------    v
        *
        * The plus represents the starting coordinates.
        *
        * Parameters:
        * x_, y_:                     Indicates the anchor position of the button
        * width_, height_:            Indicates the dimensions of the button
        * txt:                        Specifies the text to draw onto the button
        * buttonFont_:                Specifies the text to draw onto the button
        * clickCallback:              The function called when the button is clicked
        * 
        */
        procedure Init (x_, y_, width_, height_ : int,
                txt : string,
                buttonFont_ : int)
            
            % Call parent functionality
            InitElement (x_, y_, width_, height_)
            
            % Setup other variables
            text := txt
            buttonFont := buttonFont_
            
            % Calculate text offset
            var ascent, descent, intlLead, ignored : int
            
            Font.Sizes (buttonFont, ignored, ascent, descent, ignored)
            
            textX := (width_ - Font.Width (text, buttonFont)) div 2
            textY := (height_ - ascent) div 2 + descent
            
        end Init
        
        
        /**
        * Sets if the button can be pressed
        *
        * If the button is going to be disabled, then the pressed state
        * will be reset.
        */
        procedure SetPressible (canPress_ : boolean)
            canPress := canPress_
            
            if not canPress_ then
                % Reset 'isPressed' and 'isHighlighted' if the button is going
                % to be disabled
                isPressed := false
                isHighlighted := false
            end if
            
        end SetPressible
        
        /**
        * Sets the text colours of the button
        *
        * Specifing a negative parameter means that the respective colour will
        * be reset to the default
        */
        procedure SetTextColour (normal_, disabled_ : int)
            if normal_ < 0 then
                textColour := DEFAULT_TEXT
            else
                textColour := normal_
            end if
            
            if disabled_ < 0 then
                disabledTextColour := DEFAULT_DISABLED_TEXT
            else
                disabledTextColour := disabled_
            end if
            
        end SetTextColour
        
        /**
        * Sets the background colours of the button
        *
        * Specifing a negative parameter means that the respective colour will
        * be reset to the default
        */
        procedure SetBackgroundColours (normal_, disabled_, pressed_, highlighted_ : int)
            if normal_ < 0 then
                backgroundColour := DEFAULT_BACKGROUND
            else
                textColour := normal_
            end if
            
            if disabled_ < 0 then
                disabledColour := DEFAULT_DISABLED_BACKGROUND
            else
                disabledColour := disabled_
            end if
            
            if pressed_ < 0 then
                pressedColour := DEFAULT_PRESSED_BACKGROUND
            else
                pressedColour := pressed_
            end if
            
            if highlighted_ < 0 then
                highlightedColour := DEFAULT_HIGHLIGHTED_BACKGROUND
            else
                highlightedColour := highlighted_
            end if
            
        end SetBackgroundColours
        
    end UIButton
    
end UI