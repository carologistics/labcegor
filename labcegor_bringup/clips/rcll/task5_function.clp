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
  (printout red "prepare_machine_BS " ?m_id " " ?side " " ?color " " ?peer-id crlf)
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
  (printout red "prepare_machine_RS " ?m_id " " ?color " " ?peer-id crlf)
)

(deffunction prepare_machine_CS (?m_id ?operation ?peer-id)
  (printout red "prepare_machine_CS " ?m_id " " ?operation " " ?peer-id crlf)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionCS")) 
  (pb-set-field ?prep-msg "operation" ?operation)

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_cs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)

(deffunction prepare_machine_DS (?m_id ?order_id ?peer-id)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionDS")) 
  (pb-set-field ?prep-msg "order_id" ?order_id)

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_ds" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red "prepare_machine_DS " ?m_id " " ?order_id " " ?peer-id crlf)
)

; Which Machine to bribe?
(deffunction check_payment (?rs1_payment ?rs2_payment ?robot_id)
  ;(printout green "The Ring-stations should have " ?m_one " and " ?m_two crlf)
  (bind ?even FALSE)
  (if (eq (mod ?robot_id 2) 0) then
    (bind ?even TRUE)
  )
  ;(printout blue "new target " ?even " " ?robot_id ".. " ?rs1_payment " " ?rs2_payment " " ?cs1_mount " " ?cs2_mount crlf)
  (if (eq ?even TRUE) then
    (if(< ?rs1_payment 3) then
      (return M-RS1)
    )
  else
    (if(< ?rs2_payment 3)then
      (return M-RS2)
    )
  )
  (return NONE)
)

(deffunction get_target_for_payment (?robot_id)
  (do-for-fact ((?m_cs1 machine_task_overview)
                 (?m_cs2 machine_task_overview)
                 (?m_rs1 machine_task_overview)
                 (?m_rs2 machine_task_overview)) 
                  (and (eq ?m_cs1:machine_id M-CS1)
                    (eq ?m_cs2:machine_id M-CS2)
                    (eq ?m_rs1:machine_id M-RS1)
                    (eq ?m_rs2:machine_id M-RS2))
    
    (bind ?even FALSE)
    (if (eq (mod ?robot_id 2) 0) then
      (bind ?even TRUE)
    )
    
    (if (eq ?even TRUE) then
      (if (eq ?m_cs1:mounted FALSE) then
        (return M-CS1)
      )
      (if(<= ?m_rs1:payment 3) then
        (return M-RS1)
      )
    else
      (if (eq ?m_cs2:mounted FALSE) then
        (return M-CS2)
      )
      (if(<= ?m_rs2:payment 3)then
        (return M-RS2)
      )
    )
    (return NONE)
  )
)


; check order for next step
(deffunction get_next_order_color (?oid ?delete_last_stage)
  (do-for-fact
    ((?order adjustable_order))
    (eq ?order:id ?oid)
    (bind ?name ?order:name)
    (bind ?base-color ?order:base-color)
    (bind ?ring-colors ?order:ring-colors)
    (bind ?cap-color ?order:cap-color)

    (if (eq ?cap-color "Bring_it_home") then
      (bind ?target_color ?cap-color)
      (printout green "should finish now " ?target_color crlf)
      (return ?target_color)
    )

    (if (eq (length$ ?ring-colors) 0) then
      (bind ?target_color ?cap-color)
      (if (eq ?delete_last_stage TRUE) then
        (bind ?cap-color "Bring_it_home") ; next delivery point should be the DS
        (modify ?order (cap-color ?cap-color))
      )
      (return ?target_color)
    )

    (if (> (length$ ?ring-colors) 0) then 
      (bind ?target_color (nth$ 1 ?ring-colors))
      (if (eq ?delete_last_stage TRUE) then
        (bind ?ring-colors (rest$ ?ring-colors))
        (modify ?order (ring-colors ?ring-colors))
      )
    )
    (return ?target_color)
  )
)

(deffunction get_target_color_based (?color)
  (return (switch ?color
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
)

(deffunction check_order (?oid)
  (bind ?color (get_next_order_color ?oid FALSE))
  (bind ?target_machine (get_target_color_based ?color))
  (printout yellow "Target is " ?target_machine " because of " ?color crlf)

  (return ?target_machine)
)

(deffunction get_cost (?color)
  (do-for-fact ((?rs ring-spec)) (eq ?rs:color ?color)
    (return ?rs:cost)
  )
)