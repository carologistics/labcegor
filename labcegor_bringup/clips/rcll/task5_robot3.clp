; ==================================================================================
; Manage ROBOTS 3 for Payment
; ==================================================================================
(defrule send-robot-three-to-pickup
  (game-state (phase PRODUCTION))
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 3) (robot_type PAYMENT) (task_id ?tid) (can_move TRUE) (can_retrieve FALSE) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (test (or (eq ?robot_state IDLE) (eq ?robot_state HOLDING)))
  =>

  ;Prepare Basestation PrepareMachine
  (if (eq ?robot_state IDLE) then 
    (assert (order_from_machine (machine_id M-BS) (order_id 0) (robot_id 3) (color BASE_BLACK) (position "Output")))
    (send_move_to_cmd 3 ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state MOVING))
  )
  (if (eq ?robot_state HOLDING) then 
    (send_move_to_cmd 3 ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state CARRY))
  )
  (printout red "ROBOT 3 " ?robot_state " " ?mot " " ?mat " " ?peer-id crlf)
)

(defrule robot-three-pickup-base
  (game-state (phase PRODUCTION))
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 3) (task_id ?tid) (can_move FALSE) (can_retrieve TRUE) (can_deliver FALSE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (machine (name M-BS) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
  (not (order_from_machine (robot_id 3) ))
  =>
  (printout red "Basestation is in state " ?s " " crlf)
  (if (eq ?s READY-AT-OUTPUT) then
    (send_retrieve_from_cmd 3 ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state HOLDING))
  )
)

(defrule robot-three-deliver-base
  (game-state (phase PRODUCTION))
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 3) (task_id ?tid) (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  =>
  (send_deliver_to_cmd 3 ?mot ?mat ?peer-id ?tid)
  (modify ?check_robot (did_something TRUE))
  (modify ?tasks_overview (state IDLE))
)


; ==================================================================================
; CHECK STUFF
; ==================================================================================
; ==========
; ROBOT 3 for Payment
; ==========
(defrule check-robot_three
  (game-state (phase PRODUCTION))
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 3) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 3) (robot_type PAYMENT) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?mpi_one <- (machine_payment_info (machine_id M-RS1) (money ?m_one))
  ?mpi_two <- (machine_payment_info (machine_id M-RS2) (money ?m_two))
  ?check_robot <- (check_robot (robot_id 3) (did_something TRUE))
  ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  (bind ?target (check_payment ?m_one ?m_two))

  ; (printout green "robot three did something " ?task_id " " ?tid " " ?cm  " " ?cr  " " ?cd  " " ?mot  " " ?mat  " " ?robot_state " " ?target crlf)
  ; It has moved
  (if (and (eq ?robot_id 3) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE)) then 
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
  )
  
  ; It has moved
  (if (and (eq ?robot_id 3) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state HOLDING))
  )

  (if (and (eq ?robot_id 3) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cd FALSE)) then 
    ; TODO check ?target == "NONE" and do something else if thats the case
    (modify ?machine_task_overview (machine_task NOT-SET))
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver TRUE))
    (modify ?tasks_overview (move_target ?target))
    (modify ?tasks_overview (machine_target "slide"))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?tasks_overview (state HOLDING))
    (modify ?check_robot (did_something FALSE))
  )

  (if (and (eq ?robot_id 3) (eq ?task_id ?tid) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver FALSE))
    (modify ?tasks_overview (move_target M-BS))
    (modify ?tasks_overview (machine_target "output"))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
    (if (not (eq ?target NONE)) then
      (if (eq ?target M-RS1) then
        (modify ?mpi_one (money (+ ?m_one 1)))
      )
      (if (eq ?target M-RS2) then
        (modify ?mpi_two (money (+ ?m_two 1)))
      )
    )
    (if (eq ?target NONE) then
      (modify ?tasks_overview (robot_type HELPER))
      (printout red "Robot Three should start something different now." crlf)
    )
    (printout green "where should it go now? " ?target " " ?m_one " " ?m_two " soooo?: " (check_payment ?m_one ?m_two) crlf)
  )
)
