(defrule r1-move
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  ;(test (eq ?n ))
  ;(not (protobuf-msg))
  (not (move_is_sentR1))
  =>
  ;(printout green "TEST" crlf)
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

(defrule r1_move_check
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type PEER) (client-id 1) (ptr ?msg))
  (move_is_sentR1)
  (not (check_complete_101))
  =>
  (bind ?robo_id (pb-field-value ?msg "robot_id"))
  ;(printout green ?robo_id crlf)
  (bind ?task_id (pb-field-value ?msg "task_id"))
  ;(printout green ?task_id crlf)
  (bind ?success (pb-field-value ?msg "successful"))
  ;(printout green ?success crlf)

  (if (and (eq ?robo_id 1) (eq ?task_id 101) (eq ?success TRUE))
  then
    (printout green "MOVE TASK DONE - ROBO1" crlf)
    (assert(check_complete_101))
  else
    (printout yellow "still moving - ROBO1" crlf)
  )
)

(defrule r1-get-cap
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  (check_complete_101)
  (not (get_cap_sent_R1))
  =>
  (printout green "TEST" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 102)
  (pb-set-field ?msg "robot_id" 1)
  (bind ?retrieve-msg (pb-create "llsf_msgs.Retrieve")) 
  (pb-set-field ?retrieve-msg "machine_id" "M-CS1")
  (pb-set-field ?retrieve-msg "machine_point" "left")

  (pb-set-field ?msg "retrieve" ?retrieve-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (assert (get_cap_sent_R1))
  (printout INFO "CAP retrieved")
)

(defrule r1_retrieve_check
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type PEER) (client-id 1) (ptr ?msg))
  (move_is_sentR1)
  (not (check_complete_102))
  =>
  (bind ?robo_id (pb-field-value ?msg "robot_id"))
  (printout green ?robo_id crlf)
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (printout green ?task_id crlf)
  (bind ?success (pb-field-value ?msg "successful"))
  (printout green ?success crlf)

  (if (and (eq ?robo_id 1) (eq ?task_id 102) (eq ?success TRUE))
  then
    (printout green "retrieve TASK DONE - ROBO1" crlf)
    (assert(check_complete_102))
  else
    (printout yellow "still retrieving - ROBO1" crlf)
  )
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

(defrule r2_move_check
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type PEER) (client-id 2) (ptr ?msg))
  (move_is_sentR2)
  (not (check_complete_201))
  =>
  (bind ?robo_id (pb-field-value ?msg "robot_id"))
  ;(printout green ?robo_id crlf)
  (bind ?task_id (pb-field-value ?msg "task_id"))
  ;(printout green ?task_id crlf)
  (bind ?success (pb-field-value ?msg "successful"))
  ;(printout green ?success crlf)

  (if (and (eq ?robo_id 2) (eq ?task_id 201) (eq ?success TRUE))
  then
    (printout blue "MOVE TASK DONE - ROBO2" crlf)
    (assert(check_complete_201))
  else
    (printout yellow "still moving - ROBO2" crlf)
  )
)


(defrule unwatch-all-stuff
  (not (unwatched))
  =>
  (unwatch facts order)
  (assert (unwatched))
)

