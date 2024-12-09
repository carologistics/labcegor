(defrule r1-move
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  ;(test (eq ?n ))
  ;(not (protobuf-msg))
  (not (move_is_sentR1))
  =>
  (printout green "TEST" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 101)
  (pb-set-field ?msg "robot_id" 1)
  (bind ?move-msg (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?move-msg "waypoint" "M-CS1")
  (pb-set-field ?move-msg "machine_point" "input")

  (pb-set-field ?msg "move" ?move-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (assert (move_is_sentR1))
)

(defrule r1_move_takeCap
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type PEER) (client-id 1) (ptr ?msg))
  (move_is_sentR1)
  =>
  ;(bind ?res (pb-field-value ?msg ?field-name))
  (printout green ?msg crlf)
)



(defrule r2_move
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id))
  ;(test (eq ?n ))
  ;(not (protobuf-msg))
  (not (move_is_sentR2))
  =>
  (printout yellow "TEST" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 201)
  (pb-set-field ?msg "robot_id" 2)
  (bind ?move-msg (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?move-msg "waypoint" "M-CS1")
  (pb-set-field ?move-msg "machine_point" "output")
  (pb-set-field ?msg "move" ?move-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (assert (move_is_sentR2))
)






(defrule unwatch-all-stuff
  (not (unwatched))
  =>
  (unwatch facts order)
  (assert (unwatched))
)

