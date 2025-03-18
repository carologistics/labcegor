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
  (printout blue "Retrieve robot: " ?r_id " task " ?task_id " " ?r_target " " ?m_point " " ?peer-id crlf)
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
; (deffunction send_cmd_to_machine (?m_id ?operation ?peer-id)
;   (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionCS")) 
;   (pb-set-field ?prep-msg "operation" ?operation) ; "RETRIEVE_CAP")

;   (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
;   (pb-set-field ?msg "team_color" MAGENTA)
;   (pb-set-field ?msg "machine" ?m_id)
;   (pb-set-field ?msg "instruction_cs" ?prep-msg)
;   (pb-broadcast ?peer-id ?msg)
;   (pb-destroy ?msg)
; )

; Prepare Machine
(deffunction prepare_machine_BS (?m_id ?side ?color ?peer-id)
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

(deffunction prepare_machine_RS (?m_id ?color ?peer-id)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionRS"))
  (pb-set-field ?prep-msg "ring_color" ?color)

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_rs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red ?m_id " " ?color " " ?peer-id crlf)
)

(deffunction prepare_machine_CS (?m_id ?operation ?peer-id)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionCS")) 
  (pb-set-field ?prep-msg "operation" ?operation)

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_cs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red ?m_id " " ?operation " " ?peer-id crlf)
)

(deffunction prepare_machine_DS (?m_id ?order_id ?peer-id)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionDS")) 
  (pb-set-field ?prep-msg "order_id" ?order_id)

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_cs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red ?m_id " " ?order_id " " ?peer-id crlf)
)

; Which Machine to bribe?
(deffunction check_payment (?m_one ?m_two)
  ;(printout green "The Ring-stations should have " ?m_one " and " ?m_two crlf)
  (if(< ?m_two 3) then
    (return M-RS2)
  )
  (if(< ?m_one 3)then
    (return M-RS1)
  )
  (return NONE)
)

; check order for next step
(deffunction get_next_order_color (?oid)
  (do-for-fact
    ((?order adjustable_order))
    (eq ?order:id ?oid)
    (bind ?name ?order:name)
    (bind ?base-color ?order:base-color)
    (bind ?ring-colors ?order:ring-colors)
    (bind ?cap-color ?order:cap-color)
    (printout green "Order is as follows " ?oid " " ?name " " ?base-color " " ?cap-color " number of rings_left: " (length$ ?ring-colors)  crlf)

    (if (or (eq (length$ ?ring-colors) 0) (eq (nth$ 1 ?ring-colors) nil)) then
      (printout yellow "Cap color should be " ?cap-color crlf)
      (bind ?target_color ?cap-color)
      (bind ?cap-color "Bring_it_home") ; next delivery point should be the DS
      (modify ?order (cap-color ?cap-color))
    )

    (if (> (length$ ?ring-colors) 0) then 
      (printout yellow "Ring color should be " (nth$ 1 ?ring-colors) " " (length$ ?ring-colors) crlf)
      (bind ?target_color (nth$ 1 ?ring-colors))
      (bind ?ring-colors (rest$ ?ring-colors))
      (printout yellow "nexT color should be " (nth$ 1 ?ring-colors) " " (length$ ?ring-colors) " " (eq (nth$ 1 ?ring-colors) nil) crlf)
      (if (eq (length$ ?ring-colors) 0) then 
        (bind ?ring-colors nil)
      )
      (modify ?order (ring-colors ?ring-colors))
      ; (modify (?order:ring-colors) ?ring-colors)

    )
  )
  return ?target_color
)

(deffunction check_order (?oid)
  (bind ?color (get_next_order_color ?oid))
  (bind ?target_machine (switch ?color
      (case RING_GREEN then M-RS1)
      (case RING_ORANGE then M-RS1)
      (case RING_YELLOW then M-RS2)
      (case RING_BLUE then M-RS2)
      (case CAP_GREY then M-CS1)
      (case CAP_BLACK then M-CS2)
      (case BASE_BLACK then M-BS)
      (case BASE_RED then M-BS)
      (case BASE_SILVER then M-BS)
      (default M-DS)
    ))
  (printout yellow "Target is " ?target_machine " because of " ?color crlf)
  return ?target_machine
)
