(deffacts stop (move_is_sentR1))
(deffacts stop (move_is_sentR2))
(deffacts stop (retrive_cap_sent_CS1))

(defrule r1-move
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  (not (move_is_sentR1))
  =>
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
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?success (pb-field-value ?msg "successful"))

  (if (and (eq ?robo_id 1) (eq ?task_id 101) (eq ?success TRUE))
  then
    (printout green "MOVE TASK DONE - ROBO1" crlf)
    (assert(check_complete_101))
  else
    ;(printout yellow "still moving - ROBO1" crlf)
  )
)

(defrule r1-get-cap
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  (check_complete_101)
  (not (get_cap_sent_R1))
  =>
  (assert (get_cap_sent_R1))
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
)
(defrule r1_retrieve_check
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type PEER) (client-id 1) (ptr ?msg))
  (move_is_sentR1)
  (not (check_complete_102))
  =>
  (bind ?robo_id (pb-field-value ?msg "robot_id"))
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?success (pb-field-value ?msg "successful"))

  (if (and (eq ?robo_id 1) (eq ?task_id 102) (eq ?success TRUE))
  then
    ;(printout green "retrieve TASK DONE - ROBO1" crlf)
    (assert(check_complete_102))
  else
    ;(printout yellow "still retrieving - ROBO1" crlf)
  )
)

(defrule r1-place-cap
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  (check_complete_102)
  (not (place_cap_sent_R1))
  =>
  (assert (place_cap_sent_R1))
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 103)
  (pb-set-field ?msg "robot_id" 1)
  (bind ?deliver-msg (pb-create "llsf_msgs.Deliver")) 
  (pb-set-field ?deliver-msg "machine_id" "M-CS1")
  (pb-set-field ?deliver-msg "machine_point" "input")
  (pb-set-field ?msg "deliver" ?deliver-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

)

(defrule r1_place_check
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type PEER) (client-id 1) (ptr ?msg))
  (move_is_sentR1)
  (not (check_complete_103))
  =>
  (bind ?robo_id (pb-field-value ?msg "robot_id"))
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?success (pb-field-value ?msg "successful"))

  (if (and (eq ?robo_id 1) (eq ?task_id 103) (eq ?success TRUE))
  then
    (printout green "deliver TASK DONE - ROBO1" crlf)
    (assert(check_complete_103))
  else
    ;(printout yellow "still delivering - ROBO1" crlf)
  )
)

(defrule cs1_retrive
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (check_complete_103)
  (not (retrive_cap_sent_CS1))
  =>
  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" "M-CS1")
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionCS")) 
  (pb-set-field ?prep-msg "operation" "RETRIEVE_CAP")

  (pb-set-field ?msg "instruction_cs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (assert (retrive_cap_sent_CS1))
  (printout blue "CAP retrived at machine CS1")
)

(defrule cs1_retriverd_check
  (machine (name M-CS1) (state ?m-state))
  (retrive_cap_sent_CS1)
  (not (check_complete_CS1))
  =>
  (printout red ?m-state crlf)
  (if (eq ?m-state READY-AT-OUTPUT)
  then
    (printout blue "CAP Retrieved - BASE at out" crlf)
    (assert(check_complete_CS1))
  else
    (printout yellow "still Retrieving - CS1" crlf)
  )
)

(defrule r2_move
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id))
  (not (move_is_sentR2))
  =>
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
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?success (pb-field-value ?msg "successful"))

  (if (and (eq ?robo_id 2) (eq ?task_id 201) (eq ?success TRUE))
  then
    (printout green "MOVE TASK DONE - ROBO2" crlf)
    (assert(check_complete_201))
  else
    (printout yellow "still moving - ROBO2" crlf)
  )
)

(defrule r2_retrieve-atout
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id))
  (not (pickup_send_r2))
  (check_complete_201)
  (check_complete_CS1)
  =>
  (assert (pickup_send_r2))
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 202)
  (pb-set-field ?msg "robot_id" 2)
  (bind ?retrieve-msg (pb-create "llsf_msgs.Retrieve")) 
  (pb-set-field ?retrieve-msg "machine_id" "M-CS1")
  (pb-set-field ?retrieve-msg "machine_point" "output")
  (pb-set-field ?msg "retrieve" ?retrieve-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red "R2 holding Base TASK COMPLETE" crlf)
)


;(defrule unwatch-all-stuff
;  (not (unwatched))
;  =>
;  (unwatch facts order)
;  (assert (unwatched))
;)

