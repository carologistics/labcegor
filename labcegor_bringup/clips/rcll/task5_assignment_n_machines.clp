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
; (defrule manage_ordered_bases
;   (game-state (phase PRODUCTION))
;   ?machine_order <- (order_from_machine (machine_id M-BS) (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos))
;   (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
;   (machine (name M-BS) (state ?s))
;   ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
;   =>
;   (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
;     (prepare_machine_BS "M-BS" ?pos ?color ?refbox-id)
;     (printout blue "prepare for order: " ?incomming-oid " color: " ?color " at: " ?pos " for robot: " ?rid crlf)
;     (modify ?machine_task_overview (machine_task WORK))
;     (retract ?machine_order)
;   )
; )

(defrule manage_ordered_rings
  (game-state (phase PRODUCTION))
  ?machine_order <- (order_from_machine (machine_id ?mid) (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos) (operation ?operation))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name ?machine-name) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id ?mid) (machine_task ?task))
  =>
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    (if (eq ?machine-name "M-BS") then
      (printout red "M-BS" crlf)
      (prepare_machine_BS "M-BS" ?pos ?color ?refbox-id)
    )
    (if (or (eq ?machine-name "M-RS1") (eq ?machine-name "M-RS2")) then
      (printout red "M-RS" crlf)
      (prepare_machine_RS ?mid ?color ?refbox-id)
    )
    (if (eq ?machine-name "M-CS") then
      (printout red "M-CS" crlf)
      (prepare_machine_CS ?mid ?operation ?refbox-id)
    )
    (if (eq ?machine-name "M-DS") then
      (printout red "M-DS" crlf)
      (prepare_machine_DS ?mid ?incomming-oid ?refbox-id)
    )
    (printout red "prepare for order: " ?incomming-oid " with machine " ?mid " color: " ?color " at: " ?pos " for robot: " ?rid crlf)
    (modify ?machine_task_overview (machine_task WORK))
    (retract ?machine_order)
  )
)
