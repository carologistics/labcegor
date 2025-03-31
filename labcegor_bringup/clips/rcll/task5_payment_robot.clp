; ==================================================================================
; Manage ROBOTS 3 for Payment
; ==================================================================================
(defrule send-robot-payment-to-pickup
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PAYMENT) (task_id ?tid) (can_move TRUE) (can_retrieve FALSE) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  (test (or (eq ?robot_state IDLE) (eq ?robot_state HOLDING)))
  =>
  (bind ?target (get_target_for_payment ?rid))
  (printout red "ROBOT" ?rid " is in line 13 and should move to " ?mot " " ?mat " " ?robot_state " " ?target crlf)
  ;Prepare Basestation PrepareMachine
  (if (eq ?robot_state IDLE) then
    (if (eq ?mot M-BS) then
      (if (eq ?target (sym-cat M-CS (- ?rid 1))) then
        (modify ?tasks_overview (move_target ?target))
        (bind ?mot ?target)
        else
        (assert (order_from_machine (machine_id ?mot) (order_id 0) (robot_id ?rid) (color BASE_BLACK) (position OUTPUT)))
      )
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

(defrule robot-payment-pickup-base
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PAYMENT) (task_id ?tid) (can_move FALSE) (can_retrieve TRUE) (can_deliver FALSE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  (machine (name ?mot) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id ?mot) (machine_task ?task) (payment ?payment) (mounted ?mounted))
  =>
  (printout red "ROBOT" ?rid " is in line 44 and should pickup at " ?mot " " ?mat " mounted:" ?mounted " " ?s crlf)
  (if (or (eq ?mot M-CS1) (eq ?mot M-CS2)) then
    (if (eq ?mounted FALSE) then 
      (send_retrieve_from_cmd ?rid ?mot "Shelf" ?peer-id ?tid)
    )
  )
  (if (eq ?s READY-AT-OUTPUT) then
    (send_retrieve_from_cmd ?rid ?mot ?mat ?peer-id ?tid)
  )
  (modify ?check_robot (did_something TRUE))
  (modify ?tasks_overview (state HOLDING))
)

(defrule robot-payment-deliver-base
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PAYMENT) (task_id ?tid) (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>

  (printout red "ROBOT" ?rid " is in line 67 and should deliver to " ?mot " " ?mat " " ?robot_state crlf)
  (send_deliver_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
  (modify ?check_robot (did_something TRUE))
  (modify ?tasks_overview (state IDLE))
)

; ==================================================================================
; CHECK STUFF for Payment Robots
; ==================================================================================
(defrule check_robot_payment
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PAYMENT) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something TRUE))
  ?machine_task_overview <- (machine_task_overview (machine_id ?mot) (machine_task ?task) (payment ?payment) (mounted ?mounted))
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id ?rid) (ptr ?msg))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  (bind ?target (get_target_for_payment ?rid))

  (if (and (eq ?robot_id ?rid) (eq ?task_id ?tid)) then
    (printout green "ROBOT" ?rid " task " ?tid " " ?cm " " ?cr " " ?cd " " ?mot " " ?mat " " ?target crlf)
    (if (eq ?successful TRUE) then
  
      ; It has moved without something in the gripper
      (if (and (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE)) then 
        (printout red "ROBOT" ?rid " is in line 98 and should have moved to " ?mot " " ?mat crlf)
        (modify ?tasks_overview (can_move FALSE))
        (modify ?tasks_overview (can_retrieve TRUE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?check_robot (did_something FALSE))
        (modify ?tasks_overview (state IDLE))
      )
      
      ; It has moved while carring something
      (if (and (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
        (printout red "ROBOT" ?rid " is in line 108 and should have moved to " ?mot " " ?mat crlf)
        (modify ?tasks_overview (can_move FALSE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?check_robot (did_something FALSE))
        (modify ?tasks_overview (state HOLDING))
      )

      ; It has picked something up
      (if (and (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cd FALSE)) then 
        (printout red "ROBOT" ?rid " is in line 118 and should have picked somthing up at " ?mot " " ?mat crlf)
        
        ; It carries a base
        (if (or (not (or (eq ?mot M-CS1) (eq ?mot M-CS2))) (eq ?mounted TRUE) )then
          (modify ?tasks_overview (move_target (sym-cat M-RS (- ?rid 1)))) ; Robot2 is send to RS1 and robot3 is send to RS2
          (modify ?tasks_overview (machine_target "Slide"))
        )
        ; It carries a cap-carrier
        (if (and (or (eq ?mot M-CS1) (eq ?mot M-CS2)) (eq ?mounted FALSE) )then
          (modify ?tasks_overview (machine_target "Input"))
        )

        (modify ?machine_task_overview (machine_task NOT-SET))
        (modify ?tasks_overview (can_move TRUE))
        (modify ?tasks_overview (can_retrieve FALSE))
        (modify ?tasks_overview (can_deliver TRUE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?tasks_overview (state HOLDING))
        (modify ?check_robot (did_something FALSE))
      )

      ; It Delivered somthing
      (if (and (eq ?cm FALSE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
        (printout red "ROBOT" ?rid " is in line 139 and should delivered something to " ?mot " " ?mat " target " ?target " mounted? " ?mounted " payment:" ?payment crlf)
  
        (if (or (eq ?mot M-CS1) (eq ?mot M-CS2)) then
          (if (eq ?mounted FALSE) then 
            (assert (order_from_machine (machine_id ?mot) (order_id 0) (robot_id ?rid) (operation RETRIEVE_CAP)))
            (modify ?machine_task_overview (mounted TRUE))
          )
          else
          (if (and (or (eq ?mot M-RS1) (eq ?mot M-RS2)) (eq ?mat "Slide")) then
            (modify ?machine_task_overview (payment (+ ?payment 1)))
            (modify ?tasks_overview (move_target M-BS))
          )
        )

        (modify ?tasks_overview (can_move TRUE))
        (modify ?tasks_overview (can_retrieve FALSE))
        (modify ?tasks_overview (can_deliver FALSE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?check_robot (did_something FALSE))
        (modify ?tasks_overview (state IDLE))
        (modify ?tasks_overview (machine_target "Output"))
      )
    )
  )
)
