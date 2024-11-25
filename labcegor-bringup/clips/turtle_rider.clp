; (deftemplate rider
;     (slot target_point (default ?None))
;     (slot current_pos (type float32[2] static array)(default ?None))
;     (slot margin (type float32) (default ?None))
;     (slot speed (type float32) (default ?None)))


(defrule ros-msgs-pub-init
  ; Create Publisher 
  (not (ros-msgs-publisher (topic "/turtle1/cmd_vel")))
  (not (executive-finalize))
=>
  (ros-msgs-create-publisher "/turtle1/cmd_vel" "geometry_msgs/msg/Twist")
  (printout info "Publishing on /turtle1/cmd_vel" crlf)
)

(defrule ros-msgs-pub-hello
  "Send a Twist message with properly structured Vector3 fields."
  (declare (salience 1))
  (ros-msgs-publisher (topic "/turtle1/cmd_vel"))
  (ros-msgs-message)
=>
  (printout yellow "Sending Command" crlf)

  ;; Create the Twist message
  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))

  ;; Set the fields for linear and angular vectors
  (ros-msgs-set-field ?msg "linear" 2.0, 4.0, 0.0)
  (ros-msgs-set-field ?msg "angular" 2.0, 4.0, 0.0)

  ;; Publish the message
  (ros-msgs-publish ?msg "/turtle1/cmd_vel")

  ;; Destroy the message to free resources
  (ros-msgs-destroy-message ?msg)
)

(defrule ros-msgs-sub-init
" Create a simple subscriber using the generated bindings. "
  (not (ros-msgs-subscription (topic "turtle1/pose")))
  (not (executive-finalize))
=>
  (ros-msgs-create-subscription "turtle1/pose" "turtlesim/msg/Pose")
  (printout info "Listening for messages on /turtle1/pose" crlf)
)

(defrule ros-msgs-receive
" React to incoming messages and answer (on a different topic). "
  (ros-msgs-subscription (topic ?sub))
  ?msg-f <- (ros-msgs-message (topic ?sub) (msg-ptr ?inc-msg))
  =>
  (bind ?x (ros-msgs-get-field ?inc-msg "x"))
  (bind ?y (ros-msgs-get-field ?inc-msg "y"))
  (bind ?theta (ros-msgs-get-field ?inc-msg "theta"))
  (printout blue "Received position: x=" ?x ", y=" ?y ", theta=" ?theta crlf)
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