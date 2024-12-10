; Licensed under GPLv2. See LICENSE file. Copyright Carologistics.


(deftemplate zeugs
  (slot positionx (type FLOAT))
  (slot positiony (type FLOAT))
  (slot direction (type FLOAT))
  (slot directionTurtle (type INTEGER)) ;"1=up", "3=down", "2=left" or "0=right"
  (slot move (type INTEGER))
  (slot turn (type INTEGER))
  (slot velocityL (type FLOAT))
  (slot velocityA (type FLOAT))
)

  ;(slot start (type FLOAT))
  ;(multislot position (type FLOAT) (cardinality 3 3))




(defrule ros-msgs-pub-init
" Create publisher for ros_cx_out."
  (not (ros-msgs-publisher (topic "ros_cx_out")))
  (not (executive-finalize))
=>
  
  (assert (zeugs(directionTurtle 0) (move 1)))
  

)



(defrule ros-msgs-sub-init
" Create a simple subscriber using the generated bindings. "
  (not (ros-msgs-subscription (topic "turtle1/pose")))
  (not (executive-finalize))
=>
  (ros-msgs-create-subscription "turtle1/pose" "turtlesim/msg/Pose")
  (ros-msgs-create-subscription "turtle1/cmd_vel" "geometry_msgs/msg/Twist")
  (printout info "Listening for String messages on /turtle1/pose" crlf)


)


(defrule ros-msgs-receive-pose
" React to incoming messages and answer (on a different topic). "
  (ros-msgs-subscription (topic "turtle1/pose"))
  ?msg-f <- (ros-msgs-message (topic "turtle1/pose") (msg-ptr ?inc-msg))
  ?fact <- (zeugs)
  =>
  (bind ?recvx (ros-msgs-get-field ?inc-msg "x"))
  (bind ?recvy (ros-msgs-get-field ?inc-msg "y"))
  (bind ?recvtheta (ros-msgs-get-field ?inc-msg "theta"))

  (bind ?velLin (ros-msgs-get-field ?inc-msg "linear_velocity"))
  (bind ?velAng (ros-msgs-get-field ?inc-msg "angular_velocity"))

  

  ;(printout blue "Recieved via turtle1/pose: " ?recvx crlf)
  ;(printout yellow "Recieved via turtle1/pose: " ?recvy crlf)
  ;(printout red "Recieved via turtle1/pose: " ?recvtheta crlf)

  ;(printout yellow "Recieved via turtle1/pose: " ?velAng crlf)

  (modify ?fact (positionx ?recvx) (positiony ?recvy) (direction ?recvtheta) (velocityA ?velAng) (velocityL ?velLin))
  ;(assert (zeugs (positiony ?recvy)))
  ;(assert (zeugs (direction ?recvtheta)))

  (ros-msgs-destroy-message ?inc-msg)
  (retract ?msg-f)
)





(defrule move
  ?move-f <- (zeugs (directionTurtle ?dT) (move 1) (positionx ?x) (positiony ?y) (velocityA 0.0)) 
=>
  (printout green "move" crlf)

  (ros-msgs-create-publisher "turtle1/cmd_vel" "geometry_msgs/msg/Twist")

  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))
  (bind ?msgVector3L (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
  (bind ?msgVector3A (ros-msgs-create-message "geometry_msgs/msg/Vector3"))

  (ros-msgs-set-field ?msgVector3L "x" 1.0)
  (ros-msgs-set-field ?msgVector3L "y" 0.0)
  (ros-msgs-set-field ?msgVector3L "z" 0.0)

  (ros-msgs-set-field ?msgVector3A "x" 0.0)
  (ros-msgs-set-field ?msgVector3A "y" 0.0)
  (ros-msgs-set-field ?msgVector3A "z" 0.0)

  (ros-msgs-set-field ?msg "linear" ?msgVector3L)
  (ros-msgs-set-field ?msg "angular" ?msgVector3A)

  (ros-msgs-publish ?msg turtle1/cmd_vel)
  (ros-msgs-destroy-message ?msg)
  
  ;(retract ?move-f)


  (if (and (= ?dT 0) ;is direction rigth? 
           (> ?x 9.0))
      then (modify ?move-f (move 0) (turn 1))
  )

  (if (and (= ?dT 1) ;is direction rigth? 
           (> ?y 9.0))
      then (modify ?move-f (move 0) (turn 1))
  )

  (if (and (= ?dT 2) ;is direction rigth? 
           (< ?x 2.0))
      then (modify ?move-f (move 0) (turn 1))
  )

  (if (and (= ?dT 3) ;is direction rigth? 
           (< ?y 2.0))
      then (modify ?move-f (move 0) (turn 1))
  )

)

(defrule turn 
  ?factTurn <- (zeugs(turn 1) (directionTurtle ?dT) (velocityL 0.0))

=> 
  (printout green "turn" crlf)

  (ros-msgs-create-publisher "turtle1/cmd_vel" "geometry_msgs/msg/Twist")

  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))
  (bind ?msgVector3L (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
  (bind ?msgVector3A (ros-msgs-create-message "geometry_msgs/msg/Vector3"))

  (ros-msgs-set-field ?msgVector3L "x" 0.0)
  (ros-msgs-set-field ?msgVector3L "y" 0.0)
  (ros-msgs-set-field ?msgVector3L "z" 0.0)

  (ros-msgs-set-field ?msgVector3A "x" 0.0)
  (ros-msgs-set-field ?msgVector3A "y" 0.0)
  (ros-msgs-set-field ?msgVector3A "z" (/ (pi) 2))

  (ros-msgs-set-field ?msg "linear" ?msgVector3L)
  (ros-msgs-set-field ?msg "angular" ?msgVector3A)

  (ros-msgs-publish ?msg turtle1/cmd_vel)
  (ros-msgs-destroy-message ?msg)
  
  (modify ?factTurn (turn 0))
  ;(assert (startTurn))
  
)

(defrule wait
  ;(startTurn)
  ?factTurn <- (zeugs (directionTurtle ?dT) (velocityA ?v&:(> ?v 0.0)) (move 0))
=>
  (printout green "done" crlf)
  ;(retract (startTurn))
  (modify ?factTurn (move 1) (turn 0) (directionTurtle (mod (+ ?dT 1) 4))) 
)


