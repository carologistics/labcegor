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
  ?machine_task_overview <- (machine_task_overview (machine_id ?mot) (machine_task ?task) (payment ?payment) (mounted ?mounted))
  =>
  ; Get Order
  ; Prepare Basestation PrepareMachine
  (if (and (eq ?robot_state IDLE) (eq ?cd FALSE) (eq ?mot M-BS)) then 
    (assert (order_from_machine (machine_id M-BS) (order_id ?oid) (robot_id ?rid) (color ?base-color) (position INPUT)))
    (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state MOVING))
  )
  (if (and (eq ?robot_state HOLDING) (eq ?cd TRUE)) then 
    (if (not (or (eq ?mot M-CS1) (eq ?mot M-CS2))) then
      (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
      (modify ?check_robot (did_something TRUE))
      (modify ?tasks_overview (state CARRY))
    )
    (if (or (eq ?mot M-RS1) (eq ?mot M-RS2)) then
      (if (eq ?payment TRUE) then
        (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
        (modify ?check_robot (did_something TRUE))
        (modify ?tasks_overview (state CARRY))
      )
      else
      (if (or (eq ?mot M-CS1) (eq ?mot M-CS2)))
    )
  )
  (if (and (eq ?robot_state IDLE) (eq ?cd FALSE) (not (eq ?mot M-BS))) then 
    (send_move_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state MOVING))
  )
)

(defrule pickup_order_based
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid) (can_deliver ?cd) 
                                      (can_move FALSE) (can_retrieve TRUE) (robot_type PRODUCTION) 
                                      (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  ?assigned_order <- (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color))
  (not (order_from_machine (robot_id ?rid)))
  (machine (name ?machine-name&:(eq ?machine-name (sym-cat ?mot))) (state ?s))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>
  (if (eq ?s READY-AT-OUTPUT) then
    (send_retrieve_from_cmd ?rid ?mot ?mat ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state HOLDING))
  )
  (if (and (eq ?mot M-DS) (eq ?mat "Output") (eq ?s IDLE)) then
    (modify ?tasks_overview (robot_id 1) (robot_type PRODUCTION) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (state IDLE) (move_target M-BS) (machine_target "Input" ))
    (modify ?check_robot (robot_id 1) (did_something FALSE) (is_assigned TRUE) (go_to_next_step TRUE))
    (modify ?assigned_order (order_id (+ ?oid 1)) (robot_id 1) (ready_for_next_step FALSE))
  )
)

(defrule deliver_part_to_machine_order_based
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (task_id ?tid)
                          (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (robot_type PRODUCTION) 
                          (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  =>
  (send_deliver_to_cmd ?rid ?mot ?mat ?peer-id ?tid)
  (modify ?check_robot (did_something TRUE))
  (modify ?tasks_overview (state IDLE))
)

; ==================================================================================
; CHECK STUFF
; ==================================================================================
(defrule check_progress_off_robot_with_order
  (game-state (phase PRODUCTION))
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PRODUCTION) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something TRUE) (is_assigned TRUE))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color) (ring-colors $?ring-colors)); 
  ?assigned_order <- (assigned_order (order_id ?order_id) (robot_id ?rid))
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id ?rid) (ptr ?msg))
  ?machine_task_overview <- (machine_task_overview (machine_id ?mot) (payment ?payment) (mounted ?mounted))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))

  (if (and (eq ?task_id ?tid) (eq ?robot_id ?rid))then
    ; It moved
    (if (eq ?successful TRUE) then
      (if (and (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE) (eq ?robot_state MOVING) (eq ?mat "Input")) then
        (modify ?tasks_overview (can_move FALSE))
        (modify ?tasks_overview (can_retrieve TRUE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?check_robot (did_something FALSE))
        (modify ?tasks_overview (state IDLE))
      )

      (if (and (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE) (eq ?robot_state MOVING) (eq ?mat "Output")) then
        (modify ?tasks_overview (can_move FALSE))
        (modify ?tasks_overview (can_retrieve TRUE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?check_robot (did_something FALSE))
        (modify ?tasks_overview (state IDLE))
      )

      ; It Grapped something
      (if (and (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cd FALSE) (eq ?robot_state HOLDING)) then
        (bind ?target (check_order ?oid))
        (modify ?tasks_overview (can_move TRUE))
        (modify ?tasks_overview (can_retrieve FALSE))
        (modify ?tasks_overview (can_deliver TRUE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?tasks_overview (move_target ?target))
        (modify ?check_robot (did_something FALSE))
        (modify ?machine_task_overview (machine_task NOT-SET))
        (modify ?tasks_overview (machine_target "Input"))
      )

      ; It moved to deliver
      (if (and (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd TRUE) (eq ?robot_state CARRY)) then
        (modify ?tasks_overview (can_move FALSE))
        (modify ?tasks_overview (can_deliver TRUE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?check_robot (did_something FALSE))
        (modify ?tasks_overview (state HOLDING))
      )

      ; It delivered 
      (if (and (eq ?cm FALSE) (eq ?cr FALSE) (eq ?cd TRUE) (eq ?robot_state IDLE)) then
        (bind ?color (get_next_order_color ?oid TRUE))

        (if (or (eq ?mot M-RS1) (eq ?mot M-RS2)) then
            (modify ?machine_task_overview (payment (- ?payment (get_cost ?color))))
          else
          (if (or (eq ?mot M-CS1) (eq ?mot M-CS2)) then
            (modify ?machine_task_overview (mounted FALSE))
          )
        )
        (assert (order_from_machine (machine_id ?mot) (order_id ?oid) (robot_id ?rid) (color ?color) (operation MOUNT_CAP) (position ?mat)))
        (modify ?tasks_overview (machine_target "Output"))
        (modify ?tasks_overview (can_move TRUE))
        (modify ?tasks_overview (can_retrieve FALSE))
        (modify ?tasks_overview (can_deliver FALSE))
        (modify ?tasks_overview (task_id (+ ?task_id 1)))
        (modify ?check_robot (did_something FALSE))
        (modify ?tasks_overview (state IDLE))
      )
    )
  )
)
