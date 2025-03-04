; ==================================================================================
; Manage ROBOTS as Helper
; ==================================================================================
(defrule send-robot-three-to-pickup
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PAYMENT) (task_id ?tid) (can_move TRUE) (can_retrieve FALSE) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  (test (or (eq ?robot_state IDLE) (eq ?robot_state HOLDING)))
  =>
  
  (printout red "ROBOT " ?rid " " ?robot_state " " ?mot " " ?mat " " ?peer-id crlf)

  ;Prepare Basestation PrepareMachine
  (if (eq ?robot_state IDLE) then 
    (assert (order_from_machine (machine_id ?mot) (order_id 0) (robot_id ?rid) (color BASE_BLACK) (position OUTPUT)))
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


; ==================================================================================
; CHECK STUFF
; ==================================================================================
; ==========
; ROBOT as Helper
; ==========
