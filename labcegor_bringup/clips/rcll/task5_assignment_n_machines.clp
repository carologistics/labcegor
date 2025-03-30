; ==================================================================================
; MOVE ROBOTS & Do Tasks
; ==================================================================================

(defrule make_orders_change_again
  ?adjustable_order <- (adjustable_order (id ?oid) (name NOT-SET))
  (order (id ?oid) (name ?name) (workpiece ?workpiece) (complexity ?complexity) (base-color ?base-color) (ring-colors $?ring-colors) (cap-color ?cap-color) (quantity-requested ?quantity-requested) (quantity-delivered ?quantity-delivered) (quantity-delivered-other ?quantity-delivered-other) (delivery-begin ?delivery-begin) (delivery-end ?delivery-end))
  => 
  (printout yellow "assign order " ?oid " " crlf)
  (retract ?adjustable_order)
  (assert (adjustable_order (id ?oid) (name ?name) (workpiece ?workpiece) (complexity ?complexity) (base-color ?base-color) (ring-colors ?ring-colors) (cap-color ?cap-color) (quantity-requested ?quantity-requested) (quantity-delivered ?quantity-delivered) (quantity-delivered-other ?quantity-delivered-other) (delivery-begin ?delivery-begin) (delivery-end ?delivery-end)))
  ;?adjustable_order <- ((id ?adjustable_id) (name ?adjustable_name) (workpiece ?adjustable_workpiece) (complexity ?adjustable_complexity) (base-color ?adjustable_base-color) (ring-colors ?adjustable_ring-colors) (cap-color ?adjustable_cap-color) (quantity-requested ?adjustable_quantity-requested) (quantity-delivered ?adjustable_quantity-delivered) (quantity-delivered-other ?adjustable_quantity-delivered-other) (delivery-begin ?adjustable_delivery-begin) (delivery-end ?adjustable_delivery-end) (competitiv ?adjustable_competitiv))
)

; ==================================================================================
; Manage Machines
; ==================================================================================
(defrule manage_ordered_bases
  (game-state (phase PRODUCTION))
  ?machine_order <- (order_from_machine (machine_id M-BS) (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name M-BS) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
  =>
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    (prepare_machine_BS ?pos ?color ?refbox-id)
    (modify ?machine_task_overview (machine_task WORK))
    (retract ?machine_order)
  )
)

(defrule manage_ordered_rings
  (game-state (phase PRODUCTION))
  ?machine_order <- (order_from_machine (machine_id ?machine_id&:(or (eq ?machine_id M-RS1) (eq ?machine_id M-RS2)) ) (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos) (operation ?operation))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name ?machine_id) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id ?machine_id) (machine_task ?task))
  =>
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    (prepare_machine_RS ?machine_id ?color ?refbox-id)
    (modify ?machine_task_overview (machine_task WORK))
    (retract ?machine_order)
  )
)

(defrule manage_ordered_delivery
  (game-state (phase PRODUCTION))
  ?machine_order <- (order_from_machine (machine_id M-DS) (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos) (operation ?operation))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name M-DS) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id M-DS) (machine_task ?task))
  =>
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    (prepare_machine_DS ?incomming-oid ?refbox-id)
    (modify ?machine_task_overview (machine_task WORK))
    (retract ?machine_order)
  )
)

(defrule manage_ordered_caps
  (game-state (phase PRODUCTION))
  ?machine_order <- (order_from_machine (machine_id ?machine_id&:(or (eq ?machine_id M-CS1) (eq ?machine_id M-CS2))) (order_id ?incomming-oid) (robot_id ?rid) (operation ?operation))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name ?machine_id) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id ?machine_id) (machine_task ?task))
  =>
  (prepare_machine_CS ?machine_id ?operation ?refbox-id)
  (modify ?machine_task_overview (machine_task WORK))
  (retract ?machine_order)
)
