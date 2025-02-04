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
  (if (and (eq ?robot_state IDLE) (eq ?cd FALSE)) then 
    (assert (base_order_from_machine (order_id ?oid) (robot_id ?rid) (color ?base-color) (position "INPUT")))
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

(defrule deliver_part_to_machine_order_based
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid)
                          (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (robot_type PRODUCTION) 
                          (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color))
  =>
  (printout green "what will id do?" crlf)
)

; (defrule deliver_order_based
; (game-state (phase PRODUCTION))
; )

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
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color) (ring-colors $?ring-colors)); 
  ?mpi_one <- (machine_payment_info (machine_id M-RS1) (money ?m_one))
  ?mpi_two <- (machine_payment_info (machine_id M-RS2) (money ?m_two))
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id ?rid) (ptr ?msg))
  ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))

  ; It moved
  (if (and (eq ?task_id ?tid) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE) (eq ?robot_state MOVING) (eq ?successful TRUE)) then
    (printout green "robot " ?rid " can now grab the base of color: " ?base-color " from order: " ?oid crlf)
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
  )

  ; It Grapped something
  (if (and (eq ?task_id ?tid) (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cd FALSE) (eq ?robot_state HOLDING) (eq ?successful TRUE)) then
    (bind ?target (check_order ?oid))
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?tasks_overview (move_target ?target))
    (modify ?check_robot (did_something FALSE))
    (modify ?machine_task_overview (machine_task NOT-SET))
    ; Todo get target based on order
    (modify ?tasks_overview (machine_target "input"))
    (printout green "Yippiiiiiiiiiieee" crlf)
  )

  ; It moved to deliver
  (if (and (eq ?task_id ?tid) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd TRUE) (eq ?robot_state CARRY) (eq ?successful TRUE)) then
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_deliver TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state HOLDING))
  )

  ; It delivered 
  (if (and (eq ?task_id ?tid) (eq ?cm FALSE) (eq ?cr FALSE) (eq ?cd TRUE) (eq ?robot_state HOLDING) (eq ?successful TRUE)) then
    ; TODO check if differenz between cm true or false for retrevial of product....
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (modify ?tasks_overview (can_deliver FALSE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
    (modify ?tasks_overview (state IDLE))
  )
)
