; ==================================================================================
; MOVE ROBOTS & Do Tasks
; ==================================================================================

(defrule random-order-assignment
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
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid) (robot_type PRODUCTION) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color)); 
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>
  (printout blue "Robot " ?peer-name " robot-id " ?rid crlf)
  ; Todo send robot
  ; todo check if robot is 
  ;Get Order
  ;Prepare Basestation PrepareMachine
  (assert (base_order_from_machine (order_id ?oid) (robot_id ?rid) (color ?base-color) (position "INPUT")))
  (if (eq ?robot_state IDLE) then 
    (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state MOVING))
  )
)

(defrule pickup_order_based
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid) (robot_type PRODUCTION) (state ?robot_state))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color)); 
  ; TODO make machine name dependent on move_target
  (machine (name M-BS) (state ?s) (order ?machine_oid))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>
  (printout green "Basestation is in state " ?s " " ?oid " " ?machine_oid crlf)
  (if (and (eq ?s READY-AT-OUTPUT) (eq ?oid ?machine_oid)) then
    (send_retrieve_from_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state HOLDING))
  )
)

; (defrule deliver_order_based
; )
; ==================================================================================
; Manage ROBOTS 3 for Payment
; ==================================================================================
(defrule send-robot-three-to-pickup
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 3) (robot_type PAYMENT) (task_id ?tid) (can_move TRUE) (can_retrieve FALSE) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (test (eq ?n ROBOT3))
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
  (printout red "CARRY " ?n " " ?robot_state " " ?mot " " ?mat " " ?peer-id crlf)
)

(defrule robot-three-pickup-base
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 3) (task_id ?tid) (can_move FALSE) (can_retrieve TRUE) (can_deliver FALSE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (machine (name M-BS) (state ?s) (order ?oid))
  (test (eq ?n ROBOT3))
  =>
  (printout red "Basestation is in state " ?s " " ?oid crlf)
  (if (and (eq ?s READY-AT-OUTPUT) (eq ?oid 0)) then
    (send_retrieve_from_cmd 3 ?mot ?mat ?peer-id ?tid)
    ; (printout blue "part 2/3 " robot_state crlf)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state HOLDING))
  )
)

(defrule robot-three-deliver-base
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 3) (task_id ?tid) (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (test (eq ?n ROBOT3))
  =>
  (send_deliver_to_cmd 3 ?mot ?mat ?peer-id ?tid)
  ; (printout blue "part 3/3 " robot_state crlf)
  (modify ?check_robot (did_something TRUE))
  (modify ?tasks_overview (state IDLE))
)


; ==================================================================================
; Manage Machines
; ==================================================================================
(defrule manage_ordered_bases
  ?machine_order <- (base_order_from_machine (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  ?machine <- (machine (name M-BS) (state ?s))
  =>
  (if (eq ?s IDLE) then
    (prepare_basestation "M-BS" ?pos ?color ?refbox-id)
    (printout blue "prepare for order: " ?incomming-oid " color: " ?color " at: " ?pos " for robot: " ?rid crlf)
    (modify ?machine (oid ?incomming-oid))
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
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PRODUCTION) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color)); 
  ?mpi_one <- (machine_payment_info (machine_id M-RS1) (money ?m_one))
  ?mpi_two <- (machine_payment_info (machine_id M-RS2) (money ?m_two))
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id ?rid) (ptr ?msg))
  (not (base_order_from_machine (order_id ?oid) (robot_id ?rid)))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  (printout red "not yet there" crlf)
  (if (and (eq ?cm TRUE) (eq ?robot_state MOVING) (eq ?successful TRUE)) then
    (printout green "robot " ?rid " can now grab the base of color: " ?base-color " from order: " ?oid crlf)
  )
)



; ==========
; ROBOT 3 for Payment
; ==========
(defrule check-robot_three
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 3) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 3) (robot_type PAYMENT) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?mpi_one <- (machine_payment_info (machine_id M-RS1) (money ?m_one))
  ?mpi_two <- (machine_payment_info (machine_id M-RS2) (money ?m_two))
  ?check_robot <- (check_robot (robot_id 3) (did_something TRUE))
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
