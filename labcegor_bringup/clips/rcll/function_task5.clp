; ==================================================================================
; FUNCTIONS
; ==================================================================================

; Move
(deffunction send_move_to_cmd (?r_id ?r_target ?m_point ?peer-id ?task_id)
  (bind ?move_msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move_msg "waypoint" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "move" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "Move: robot: " ?r_id " task " ?r_target " " ?task_id " " ?m_point crlf)
)

; Retrieve
(deffunction send_retrieve_from_cmd (?r_id ?r_target ?m_point ?peer-id ?task_id)
  (bind ?move_msg (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?move_msg "machine_id" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "retrieve" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "Retrieve: robot: " ?r_id " task " ?task_id " " ?r_target " " ?m_point " " ?peer-id crlf)
)

; Deliver
(deffunction send_deliver_to_cmd (?r_id ?r_target ?m_point ?peer-id ?task_id)
  (bind ?move_msg (pb-create "llsf_msgs.Deliver"))
  (pb-set-field ?move_msg "machine_id" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "deliver" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "delivery: robot: " ?r_id " task " ?task_id crlf)
)

; BufferStation
(deffunction send_robot_to_bufferStation (?r_id ?r_target ?peer-id ?task_id)
  (bind ?buffer_msg (pb-create "llsf_msgs.BufferStation"))
  (pb-set-field ?buffer_msg "machine_id" ?r_target)
  (pb-set-field ?buffer_msg "shelf_number" 1)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "buffer" ?buffer_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "BufferStation: robot: " ?r_id " task " ?task_id crlf)
)

; Retrieve from Machine
(deffunction send_cmd_to_machine (?m_id ?operation ?peer-id)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionCS")) 
  (pb-set-field ?prep-msg "operation" ?operation) ; "RETRIEVE_CAP")

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_cs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)

; Prepare Machine
(deffunction prepare_basestation (?m_id ?side ?color ?peer-id)
  (printout red "first message in prepare_basestation" ?m_id " " ?side " " ?color " " ?peer-id crlf)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionBS")) 
  (pb-set-field ?prep-msg "side" ?side)
  (pb-set-field ?prep-msg "color" ?color)

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_bs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red ?m_id " " ?side " " ?color " " ?peer-id crlf)
)

; Which Machine to bribe?
(deffunction check_payment (?m_one ?m_two)
  ;(printout green "The Ring-stations should have " ?m_one " and " ?m_two crlf)
  (if(< ?m_one 3)then
    (return "M-RS1")
  )
  (if(< ?m_two 3) then
    (return "M-RS2")
  )
  (return "NONE")
)

; check order for next step
(deffunction check_order (?oid)
  (do-for-fact
    ((?order order))
    (eq ?order:id ?oid)
    (bind ?name ?order:name)
    (bind ?base-color ?order:base-color)
    (bind ?ring-colors ?order:ring-colors)
    (bind ?cap-color ?order:cap-color)
  )
  (bind ?target_color "")
  (printout green "Order is as folloews " ?oid " " ?name " " ?base-color " "?cap-color crlf)
  (if (> (length$ ?ring-colors) 0) then 
    (printout yellow "Ring color should be" (nth$ 1 ?ring-colors) crlf)
    (assert ?target_color (nth$ 1 ?ring-colors))
  )
  (if (eq (length$ ?ring-colors) 0) then
    (printout yellow "Cap color should be" ?cap-color crlf)
    (assert ?target_color ?cap-color)
  )

  (bind ?target_machine (switch ?target_color
    (case RING_GREEN then M-RS1)
    (case RING_ORANGE then M-RS1)
    (case RING_YELLOW then M-RS2)
    (case RING_BLUE then M-RS2)
    (case CAP_SILVER then M-CS1)
    (case CAP_BLACK then M-CS2)
    (case BASE_BLACK then M-BS)
    (case BASE_RED then M-BS)
    (case BASE_SILVER then M-BS)
    (default M-DS)
  ))
  (printout yellow "Target is " ?target_machine " because of " ?target_color crlf)
  
  (return ?target_machine)
)