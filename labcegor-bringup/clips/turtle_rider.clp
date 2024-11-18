
(defrule ros-msgs-pub-init
" Create publisher for turtleSim/cmd_val."
  (not (ros-msgs-publisher (topic "cmd_val")))
  (not (executive-finalize))
=>
  ; create the publisher
  (ros-msgs-create-publisher "cmd_val" "geometry_msgs/msg/Twist")
  (printout info "Publishing on /cmd_val" crlf)
)

(defrule ros-msgs-pub-hello
" Whenever a message comes in, send out a Hello World message in response. "
  (declare (salience 1))
  (ros-msgs-publisher (topic ?topic))
  (ros-msgs-message)
  =>
  (printout yellow "Sending Hello World Message!" crlf)
  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))
  (ros-msgs-set-field ?msg "data" "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0}}")
  (ros-msgs-publish ?msg ?topic)
  (ros-msgs-destroy-message ?msg)
)

(defrule ros-msgs-sub-init
" Create a simple subscriber using the generated bindings. "
  (not (ros-msgs-subscription (topic "pose")))
  (not (executive-finalize))
=>
  (ros-msgs-create-subscription "pose" "turtlesim/msg/Pose")
  (printout info "Listening for messages on /pose" crlf)
)

(defrule ros-msgs-receive
" React to incoming messages and answer (on a different topic). "
  (ros-msgs-subscription (topic ?sub))
  ?msg-f <- (ros-msgs-message (topic ?sub) (msg-ptr ?inc-msg))
  =>
  (bind ?recv (ros-msgs-get-field ?inc-msg "data"))
  (printout blue "Recieved via " ?sub ": " ?recv crlf)
  (ros-msgs-destroy-message ?inc-msg)
  (retract ?msg-f)
)
(defrule ros-msgs-sub-finalize
" Delete the subscription on executive finalize. "
  (executive-finalize)
  (ros-msgs-subscription (topic ?topic))
=>
  (printout debug "Destroying topic " ?topic crlf)
  (ros-msgs-destroy-subscription ?topic)
)

(defrule ros-msgs-pub-finalize
" Delete the publisher on executive finalize. "
  (executive-finalize)
  (ros-msgs-publisher (topic ?topic))
=>
  (printout info "Destroying topic " ?topic crlf)
  (ros-msgs-destroy-publisher ?topic)
)

(defrule ros-msgs-message-cleanup
" Delete the subscription on executive finalize. "
  (executive-finalize)
  ?msg-f <- (ros-msgs-message (msg-ptr ?ptr))
=>
  (ros-msgs-destroy-message ?ptr)
  (retract ?msg-f)
)

; "Todos if publisher not yet exisist => create"
; "Todos if topic /cmd_val exist => set publisher to /cmd_val"
; "Todos if speed == 0 => get next point()"
; "Todos if if speed == 0 and currentPos*margin != target_point => move to point"





; ;; Templates
; (deftemplate publisher
;     (slot initialized (type SYMBOL) (default FALSE)))

; (deftemplate listener
;     (slot initialized (type SYMBOL) (default FALSE)))

; (deftemplate bot
;     (slot current_pos (type LIST) (default [0.0 0.0]))
;     (slot target_pos (type LIST) (default [0.0 0.0]))
;     (slot speed (type FLOAT) (default 0.0))
;     (slot margin (type FLOAT) (default 0.1)))

; (deftemplate message
;     (slot content (type SYMBOL) (default "")))

; (deftemplate target
;     (slot x (type FLOAT))
;     (slot y (type FLOAT)))

; ;; Facts (Initial State)
; (deffacts initial-state
;     (publisher (initialized FALSE))
;     (listener (initialized FALSE))
;     (message (content ""))
;     (bot (current_pos [0.0 0.0]) (target_pos [1.0 1.0]) (speed 0.0) (margin 0.1))
;     (target (x 1.0) (y 1.0))
;     (target (x 2.0) (y 2.0))
;     (target (x 3.0) (y 3.0)))

;; Rules
;; 1. Initialize Publisher
; (defrule init-publisher
;     (publisher (initialized FALSE))
;     =>
;     (printout t "Initializing publisher..." crlf)
;     (retract (publisher (initialized FALSE)))
;     (assert (publisher (initialized TRUE))))

; ;; 2. Initialize Listener
; (defrule init-listener
;     (listener (initialized FALSE))
;     =>
;     (printout t "Initializing listener..." crlf)
;     (retract (listener (initialized FALSE)))
;     (assert (listener (initialized TRUE))))

; ;; 3. Send message if msg is not empty
; (defrule send-message
;     ?msg <- (message (content ?content&~""))
;     =>
;     (printout t "Sending message: " ?content crlf)
;     (modify ?msg (content "")))

; ;; 4. Update bot position from listener data
; (defrule update-position
;     ?listener <- (listener (initialized TRUE))
;     (new-position (x ?x) (y ?y))  ;; Simulated ROS topic data
;     =>
;     (printout t "Updating position to [" ?x ", " ?y "]" crlf)
;     (retract (new-position (x ?x) (y ?y)))
;     (modify ?listener (position [?x ?y])))

; ;; 5. Move to target if not at target
; (defrule move-to-target
;     ?bot <- (bot (current_pos ?pos) (target_pos ?target) (speed ?speed))
;     (test (not (equal ?pos ?target))) ;; pos != target
;     =>
;     (bind ?distance (euclidean-distance ?pos ?target))
;     (printout t "Moving to target. Distance: " ?distance crlf)
;     (if (> ?distance 0.1) then
;         (printout t "Continuing movement..." crlf)
;         (if (= ?speed 0.0) then
;             (printout t "Speed is 0. Calculating heading and moving." crlf)
;             (modify ?bot (speed 0.5)) ;; Start moving
;         )
;     else
;         (printout t "Target reached!" crlf)
;     ))

; ;; 6. Get new target when current is reached
; (defrule get-new-target
;     ?bot <- (bot (current_pos ?pos) (target_pos ?target))
;     (test (equal ?pos ?target)) ;; pos == target
;     ?next-target <- (target (x ?x) (y ?y))
;     =>
;     (printout t "Getting new target: [" ?x ", " ?y "]" crlf)
;     (modify ?bot (target_pos [?x ?y]))
;     (retract ?next-target))

; ;; Functions
; ;; Euclidean distance calculation
; (deffunction euclidean-distance (?pos1 ?pos2)
;     (sqrt (+ (** (- (nth 0 ?pos1) (nth 0 ?pos2)) 2)
;              (** (- (nth 1 ?pos1) (nth 1 ?pos2)) 2))))

; ;; Publish message (simulated as printout)
; (deffunction publish-message (?content)
; =>
;     (printout t "Publishing to topic: " ?content crlf))