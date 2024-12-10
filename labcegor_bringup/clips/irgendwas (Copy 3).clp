; Licensed under GPLv2. See LICENSE file. Copyright Carologistics.


(deftemplate zeugs
  (slot positionx (type FLOAT))
  (slot positiony (type FLOAT))
  (slot direction (type FLOAT))
  ;(slot start (type FLOAT))
  ;(multislot position (type FLOAT) (cardinality 3 3))
  )

(deftemplate runTurtle
  (slot startRun (type FLOAT))
)


(defrule ros-msgs-pub-init
" Create publisher for ros_cx_out."
  (not (ros-msgs-publisher (topic "ros_cx_out")))
  (not (executive-finalize))
=>
  
  (ros-msgs-create-publisher "turtle1/cmd_vel" "geometry_msgs/msg/Twist")

  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))
  (bind ?msgVector3L (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
  (bind ?msgVector3A (ros-msgs-create-message "geometry_msgs/msg/Vector3"))

  
  ;turn 180 degree
  (ros-msgs-set-field ?msgVector3L "x" 0.0)
  (ros-msgs-set-field ?msgVector3L "y" 0.0)
  (ros-msgs-set-field ?msgVector3L "z" 0.0)


  (ros-msgs-set-field ?msgVector3A "x" 0.0)
  (ros-msgs-set-field ?msgVector3A "y" 0.0)
  (ros-msgs-set-field ?msgVector3A "z" 3.09)

  (ros-msgs-set-field ?msg "linear" ?msgVector3L)
  (ros-msgs-set-field ?msg "angular" ?msgVector3A)

  (ros-msgs-publish ?msg turtle1/cmd_vel)
  (ros-msgs-destroy-message ?msg)

)



(defrule ros-msgs-sub-init
" Create a simple subscriber using the generated bindings. "
  (not (ros-msgs-subscription (topic "turtle1/pose")))
  (not (executive-finalize))
=>
  (ros-msgs-create-subscription "turtle1/pose" "turtlesim/msg/Pose")
  (printout info "Listening for String messages on /turtle1/pose" crlf)
)


(defrule ros-msgs-receive
" React to incoming messages and answer (on a different topic). "
  (ros-msgs-subscription (topic ?sub))
  ?msg-f <- (ros-msgs-message (topic ?sub) (msg-ptr ?inc-msg))
  =>
  (bind ?recvx (ros-msgs-get-field ?inc-msg "x"))
  (bind ?recvy (ros-msgs-get-field ?inc-msg "y"))
  (bind ?recvtheta (ros-msgs-get-field ?inc-msg "theta"))

  (printout blue "Recieved via " ?sub ": " ?recvx crlf)
  (printout yellow "Recieved via " ?sub ": " ?recvy crlf)
  (printout red "Recieved via " ?sub ": " ?recvtheta crlf)

  (assert (zeugs (positionx ?recvx) (positiony ?recvy) (direction ?recvtheta)))
  ;(assert (zeugs (positiony ?recvy)))
  ;(assert (zeugs (direction ?recvtheta)))

  (ros-msgs-destroy-message ?inc-msg)
  (retract ?msg-f)
)



(defrule move-to-the-left
"Hoffentlich bewegt der Bumms sich nach links"
  ?zeugs-f <- (zeugs(positionx ?x&:(> ?x 1.0)) (direction ?d&:(and(> ?d 3.114) (< ?d 3.115)))) 
  (not (start FALSE))
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
  
  (retract ?zeugs-f)
)



(defrule stop
"bla"
  ?moveStop-f <- (zeugs(positionx ?x&:(< ?x 1.0)))
  (not (start FALSE))
=>  
  (printout red "stop" crlf)

  (ros-msgs-create-publisher "turtle1/cmd_vel" "geometry_msgs/msg/Twist")

  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))
  (bind ?msgVector3L (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
  (bind ?msgVector3A (ros-msgs-create-message "geometry_msgs/msg/Vector3"))


  (ros-msgs-set-field ?msg "linear" ?msgVector3L)
  (ros-msgs-set-field ?msg "angular" ?msgVector3A)

  (ros-msgs-publish ?msg turtle1/cmd_vel)
  (ros-msgs-destroy-message ?msg)

  (assert (start FALSE))
  (retract ?moveStop-f)
  (assert (turnAgain))
)


(defrule turn
  (turnAgain)
  (not (runDings))
=>
  (printout blue "turnAgain" crlf)
  (ros-msgs-create-publisher "turtle1/cmd_vel" "geometry_msgs/msg/Twist")

  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))
  (bind ?msgVector3L (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
  (bind ?msgVector3A (ros-msgs-create-message "geometry_msgs/msg/Vector3"))

  


  ;turn 180 degree
  (ros-msgs-set-field ?msgVector3L "x" 0.0)
  (ros-msgs-set-field ?msgVector3L "y" 0.0)
  (ros-msgs-set-field ?msgVector3L "z" 0.0)


  (ros-msgs-set-field ?msgVector3A "x" 0.0)
  (ros-msgs-set-field ?msgVector3A "y" 0.0)
  (ros-msgs-set-field ?msgVector3A "z" 1.545)

  (ros-msgs-set-field ?msg "linear" ?msgVector3L)
  (ros-msgs-set-field ?msg "angular" ?msgVector3A)

  (ros-msgs-publish ?msg turtle1/cmd_vel)
  (ros-msgs-destroy-message ?msg)

  (assert (runDings))
  
)

(defrule waitForTurn
  (runDings) 
  ?turn-f <- (zeugs(direction ?d&:(and (< ?d -1.611) (> ?d -1.612))))
  
=>
  (assert (runTurtle(startRun 1.0)))
  (retract ?turn-f)
)

(defrule run
  (runDings)
  ?run-f <- (runTurtle (startRun 1.0))
=>
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
  (retract ?run-f)

)

(defrule turnDuringRun
  ?turnDuringRun-f <- (zeugs(positiony ?y&:(< ?y 1.5)))
=>
  (printout green "hit wall" crlf)
  (ros-msgs-create-publisher "turtle1/cmd_vel" "geometry_msgs/msg/Twist")

  (bind ?msg (ros-msgs-create-message "geometry_msgs/msg/Twist"))
  (bind ?msgVector3L (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
  (bind ?msgVector3A (ros-msgs-create-message "geometry_msgs/msg/Vector3"))

  (ros-msgs-set-field ?msgVector3L "x" 1.0)
  (ros-msgs-set-field ?msgVector3L "y" 0.0)
  (ros-msgs-set-field ?msgVector3L "z" 0.0)

  (ros-msgs-set-field ?msgVector3A "x" 0.0)
  (ros-msgs-set-field ?msgVector3A "y" 0.0)
  (ros-msgs-set-field ?msgVector3A "z" 1.8)

  (ros-msgs-set-field ?msg "linear" ?msgVector3L)
  (ros-msgs-set-field ?msg "angular" ?msgVector3A)

  (ros-msgs-publish ?msg turtle1/cmd_vel)
  (ros-msgs-destroy-message ?msg)
  (retract ?turnDuringRun-f)
  

)



