; (defrule deliver_order_based
; (game-state (phase PRODUCTION))
; )

; ==================================================================================
; MOVE ROBOTS & Do Tasks
; ==================================================================================

(defrule random-order-assignment
  (game-state (phase PRODUCTION))
  ?order <- (adjustable_order (id ?oid))
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
  ?machine_order <- (order_from_machine (machine_id M-BS) (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name M-BS) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id M-BS) (machine_task ?task))
  =>
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    (prepare_machine_BS "M-BS" ?pos ?color ?refbox-id)
    (printout blue "prepare for order: " ?incomming-oid " color: " ?color " at: " ?pos " for robot: " ?rid crlf)
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
  
    (printout red "M-RS" crlf)
    (prepare_machine_RS ?machine_id ?color ?refbox-id)
  
    (printout red "prepare for order: " ?incomming-oid " with machine " ?machine_id" eq " (or (eq ?machine_id M-RS1) (eq ?machine_id M-RS2)) " color: " ?color " at: " ?pos " for robot: " ?rid crlf)
    (modify ?machine_task_overview (machine_task WORK))
    (retract ?machine_order)
  )
)

(defrule manage_ordered_Delivery
  (game-state (phase PRODUCTION))
  ?machine_order <- (order_from_machine (machine_id M-DS) (order_id ?incomming-oid) (robot_id ?rid) (color ?color) (position ?pos) (operation ?operation))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name ?machine_id) (state ?s))
  ?machine_task_overview <- (machine_task_overview (machine_id ?machine_id) (machine_task ?task))
  =>
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    
    (printout red "M-DS" crlf)
    (prepare_machine_DS ?machine_id ?incomming-oid ?refbox-id)

    (printout red "prepare for order: " ?incomming-oid " with machine " ?machine_id" eq " (eq ?machine_id M-DS) " color: " ?color " at: " ?pos " for robot: " ?rid crlf)
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
  (if (and (eq ?s IDLE) (not (eq ?task WORK))) then
    
    (printout red "M-CS " ?machine_id " " ?operation crlf)
    (prepare_machine_CS ?machine_id ?operation ?refbox-id)
    (modify ?machine_task_overview (machine_task WORK))
    (retract ?machine_order)
  )
)


(defrule make_orders_change_again
  ?order <- (order (id ?id) (name ?name) (workpiece ?workpiece) (complexity ?complexity) (base-color ?base-color) (ring-colors ?ring-colors) (cap-color ?cap-color) (quantity-requested ?quantity-requested) (quantity-delivered ?quantity-delivered) (quantity-delivered-other ?quantity-delivered-other) (delivery-begin ?delivery-begin) (delivery-end ?delivery-end) (competitiv ?competitiv))
  ; ?adjustable_order <- ((id ?adjustable_id) (name ?adjustable_name) (workpiece ?adjustable_workpiece) (complexity ?adjustable_complexity) (base-color ?adjustable_base-color) (ring-colors ?adjustable_ring-colors) (cap-color ?adjustable_cap-color) (quantity-requested ?adjustable_quantity-requested) (quantity-delivered ?adjustable_quantity-delivered) (quantity-delivered-other ?adjustable_quantity-delivered-other) (delivery-begin ?adjustable_delivery-begin) (delivery-end ?adjustable_delivery-end) (competitiv ?adjustable_competitiv))
  (not (adjustable_order (id ?id)))
  => 
  (assert (adjustable_order (id ?id) (name ?name) (workpiece ?workpiece) (complexity ?complexity) (base-color ?base-color) (ring-colors ?ring-colors) (cap-color ?cap-color) (quantity-requested ?quantity-requested) (quantity-delivered ?quantity-delivered) (quantity-delivered-other ?quantity-delivered-other) (delivery-begin ?delivery-begin) (delivery-end ?delivery-end) (competitiv ?competitiv)))
)
