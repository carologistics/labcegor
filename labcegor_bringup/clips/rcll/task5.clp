; (defrule deliver_order_based
; (game-state (phase PRODUCTION))
; )

; ==================================================================================
; MOVE ROBOTS & Do Tasks
; ==================================================================================

(defrule random-order-assignment
  (game-state (phase PRODUCTION))
  ?order <- (order (id ?oid))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PRODUCTION) (state IDLE))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned FALSE))
  (not (assigned_order (order_id ?oid)))
  =>
  (modify ?check_robot (is_assigned TRUE))
  (assert (assigned_order (order_id ?oid) (robot_id ?rid)))
  (printout blue "Assigned robot" ?rid " to order " ?oid crlf)
)

; ==================================================================================
; Manage ROBOT1 for Production
; ==================================================================================
(defrule move_robot_order_based
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid) (can_deliver ?cd) 
                                      (can_move TRUE) (can_retrieve FALSE) (robot_type PRODUCTION) 
                                      (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color)); 
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>
  (printout blue "Robot " ?peer-name " robot-id " ?rid crlf)
  ; Get Order
  ; Prepare Basestation PrepareMachine
  (printout green "Where should it go? " ?robot_state " " ?cd crlf)
  (assert (base_order_from_machine (order_id ?oid) (robot_id ?rid) (color ?base-color) (position "INPUT")))
  (if (and (eq ?robot_state IDLE) (eq ?cd FALSE)) then 
    (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state MOVING))
  )
  (if (and (eq ?robot_state HOLDING) (eq ?cd TRUE)) then 
    (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state CARRY))
  )
)

; (modify ?tasks_overview (can_move TRUE))
;     (modify ?tasks_overview (can_retrieve FALSE))
;     (modify ?tasks_overview (can_deliver TRUE))
;     (modify ?tasks_overview (task_id (+ ?task_id 1)))
;     (modify ?check_robot (did_something FALSE))
;     (modify ?machine_task_overview (machine_task NOT-SET))

(defrule pickup_order_based
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid) (can_deliver ?cd) 
                                      (can_move FALSE) (can_retrieve TRUE) (robot_type PRODUCTION) 
                                      (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color))
  (not (base_order_from_machine (robot_id ?rid)))
  ; TODO make machine name dependent on move_target
  (machine (name M-BS) (state ?s))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>
  (printout green ?peer-name " Basestation is in state " ?s " " ?oid " " crlf)
  (if (eq ?s READY-AT-OUTPUT) then
    (send_retrieve_from_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state HOLDING))
  )
  (printout green "will it work?" crlf)
)

; (defrule deliver_order_based
; (game-state (phase PRODUCTION))
; )
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
  (assert (base_order_from_machine (order_id 0) (robot_id 3) (color "BASE_BLACK") (position "OUTPUT")))

  (if (eq ?robot_state IDLE) then 
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
  (not (base_order_from_machine (robot_id 3) ))
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
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 3) (task_id ?tid) (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (test (eq ?n ROBOT3))
  =>
  (send_deliver_to_cmd 3 ?mot ?mat ?peer-id ?tid)
  (modify ?check_robot (did_something TRUE))
  (modify ?tasks_overview (state IDLE))
)


; ==================================================================================
; Manage Machines
; ==================================================================================
(defrule manage_ordered_bases
  (game-state (phase PRODUCTION))
  ?machine_order <- (base_order_from_machine (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name M-BS) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
  =>
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    (prepare_basestation "M-BS" ?pos ?color ?refbox-id)
    (printout blue "prepare for order: " ?incomming-oid " color: " ?color " at: " ?pos " for robot: " ?rid crlf)
    (modify ?machine_task_overview (machine_task WORK))
    (retract ?machine_order)
  )
)


; ==================================================================================
; CHECK STUFF
; ==================================================================================
; ==========
; ROBOTS orderbased
; ==========
(defrule check_progress_off_robot_with_order
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PRODUCTION) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something TRUE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color)); 
  ?mpi_one <- (machine_payment_info (machine_id M-RS1) (money ?m_one))
  ?mpi_two <- (machine_payment_info (machine_id M-RS2) (money ?m_two))
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id ?rid) (ptr ?msg))
  ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))

  ; It moved
  (if (and (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE) (eq ?robot_state MOVING) (eq ?successful TRUE)) then
    (printout green "robot " ?rid " can now grab the base of color: " ?base-color " from order: " ?oid crlf)
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
  )

  ; It Grapped something
  (if (and (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cd FALSE) (eq ?robot_state HOLDING) (eq ?successful TRUE)) then
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?machine_task_overview (machine_task NOT-SET))
    ; Todo get target based on order
    (modify ?tasks_overview (move_target "M-RS1"))
    (modify ?tasks_overview (machine_target "input"))
    (printout green "Yippiiiiiiiiiieee" crlf)
  )
)

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

  ;(printout green "robot three did something " ?task_id " " ?tid " " ?cm  " " ?cr  " " ?cd  " " ?mot  " " ?mat  " " ?robot_state " " ?target crlf)
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
    (modify ?tasks_overview (move_target "M-BS"))
    (modify ?tasks_overview (machine_target "output"))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
    (if (not (eq ?target "NONE")) then
      (if (eq ?target "M-RS1") then
        (modify ?mpi_one (money (+ ?m_one 1)))
      )
      (if (eq ?target "M-RS2") then
        (modify ?mpi_two (money (+ ?m_two 1)))
      )
    )
    (if (eq ?target "NONE") then
      (modify ?tasks_overview (robot_type HELPER))
      (printout red "Robot Three should start something different now." crlf)
    )
    (printout green "where should it go now? " ?target " " ?m_one " " ?m_two " soooo?: " (check_payment ?m_one ?m_two) crlf)
  )
)
