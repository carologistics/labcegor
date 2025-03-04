; ==================================================================================
; Manage ROBOTS as Helper
; ==================================================================================
(defrule send-robot-helper-to-pickup
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type HELPER) (task_id ?tid) (can_move TRUE) (can_retrieve FALSE) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  (test (or (eq ?robot_state IDLE) (eq ?robot_state HOLDING)))
  =>

  ; (printout red "ROBOT " ?rid " " ?robot_state " " ?mot " " ?mat " " ?peer-id crlf)

  ;Prepare Basestation PrepareMachine
  (if (eq ?robot_state IDLE) then 
    (if (or (eq ?mot M-CS1) (eq ?mot M-CS2)) then
      (modify ?tasks_overview (machine_target "INPUT"))
    )
    (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state MOVING))
  )
  (if (eq ?robot_state HOLDING) then 
    (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state CARRY))
  )
)

(defrule robot-helper-pickup-base
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid) (can_move FALSE) (can_retrieve TRUE) (can_deliver FALSE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  (machine (name ?mot) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id ?mot) (machine_task ?task) (payment ?payment) (mounted ?mounted))
  (not (order_from_machine (robot_id ?rid) ))
  =>
  (if (and (or (eq ?mot M-CS1) (eq ?mot M-CS2)) (eq ?mounted FALSE)) then
    (send_retrieve_from_cmd ?rid ?mot "Shelf" ?peer-id ?tid)
    (modify ?tasks_overview (machine_target "Input"))
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state HOLDING))
  )
  (if (eq ?s READY-AT-OUTPUT) then
    (send_retrieve_from_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state HOLDING))
  )
)

(defrule robot-helper-deliver-base
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid) (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>

  (printout red "ROBOT Delevery " ?rid " " ?robot_state " " ?mot " " ?mat " " ?peer-id crlf)
  (send_deliver_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
  (modify ?check_robot (did_something TRUE))
  (modify ?tasks_overview (state IDLE))
)


; ==================================================================================
; CHECK STUFF
; ==================================================================================
; ==========
; ROBOT as Helper
; ==========
(defrule check-robot_helper
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type HELPER) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?mpi_one <- (machine_task_overview (machine_id M-RS1) (payment ?m_one))
  ?mpi_two <- (machine_task_overview (machine_id M-RS2) (payment ?m_two))
  ?mcs_one <- (machine_task_overview (machine_id M-CS1) (mounted ?cs_one))
  ?mcs_two <- (machine_task_overview (machine_id M-CS2) (mounted ?cs_two))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something TRUE))
  ?machine_task_overview <- (machine_task_overview (machine_id ?mot) (machine_task ?task) (payment ?payment) (mounted ?mounted))
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id ?rid) (ptr ?msg))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  (bind ?target (check_payment ?m_one ?m_two))
  
  ; (printout red "robot helper did something " ?task_id " " ?tid " " ?cm  " " ?cr  " " ?cd  " " ?mot  " " ?mat  " " ?robot_state " " ?target crlf)
  ; It has moved
  (if (and (eq ?robot_id ?rid) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE)) then 
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
  )
  
  ; It has moved
  (if (and (eq ?robot_id ?rid) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state HOLDING))
  )

  (if (and (eq ?robot_id ?rid) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cd FALSE)) then 
    ; TODO check ?target == "NONE" and do something else if thats the case
    (modify ?machine_task_overview (machine_task NOT-SET))
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver TRUE))
    (if (and (or (eq ?mot M-CS1) (eq ?mot M-CS2)) (eq ?mounted TRUE) ) then
      (printout yellow "Robot has probably a cap carrier in its claw " ?robot_state " " ?mot " " ?machine_target " " crlf)
    )

    (if (or (not (or (eq ?mot M-CS1) (eq ?mot M-CS2))) (eq ?mounted TRUE) )then
      (modify ?tasks_overview (move_target ?target))
      (modify ?tasks_overview (machine_target "Slide"))
    )
    (if (and (or (eq ?mot M-CS1) (eq ?mot M-CS2)) (eq ?mounted FALSE) )then
      (modify ?tasks_overview (machine_target "Input"))
    )
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?tasks_overview (state HOLDING))
    (modify ?check_robot (did_something FALSE))
  )

  (if (and (eq ?robot_id ?rid) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver FALSE))
    (if (and (or (eq ?mot M-CS1) (eq ?mot M-CS2)) (eq ?mounted FALSE) ) then
      (assert (order_from_machine (machine_id ?mot) (order_id 0) (robot_id ?rid) (operation RETRIEVE_CAP)))
      (modify ?machine_task_overview (mounted TRUE))
    )
    
    (if (not (or (eq ?mot M-CS1) (eq ?mot M-CS2))) then
      (if (not (eq ?target NONE)) then
        (if (eq ?target M-RS1) then
          (modify ?mpi_one (payment (+ ?m_one 1)))
        )
        (if (eq ?target M-RS2) then
          (modify ?mpi_two (payment (+ ?m_two 1)))
        )
      )
        (if (eq ?target NONE) then
          (modify ?tasks_overview (robot_type HELPER))
          ; (printout red "Robot helper should start something different now." crlf)
        )
      )
    (modify ?tasks_overview (machine_target "Output"))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
    ; (printout green "where should it go now? " ?target " " ?m_one " " ?m_two " soooo?: " (check_payment ?m_one ?m_two) crlf)
  )
)
