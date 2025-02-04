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
