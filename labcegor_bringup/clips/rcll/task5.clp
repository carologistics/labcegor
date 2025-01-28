; Here is my stuff
(defglobal ?*global_task_id_base* = 0)

(deftemplate tasks_overview
  (slot robot_id (type INTEGER))
  (slot robot_type (type SYMBOL) (allowed-values PRODUCTION PAYMENT HELPER))
  (slot task_id (type INTEGER))
  (slot can_move (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_retrieve (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_deliver (type SYMBOL) (allowed-values FALSE TRUE))
  (slot state (type SYMBOL) (allowed-values IDLE MOVING CARRY HOLDING SOMETHING))
  (slot move_target (type STRING))
  (slot machine_target (type STRING))
)

(deftemplate machine_task_overview
  (slot machine_id (type SYMBOL))
  (slot machine_task (type SYMBOL))
)

(deftemplate machine_payment_info
  (slot machine_id (type SYMBOL))
  (slot money (type INTEGER))
)

(deftemplate check_robot
  (slot robot_id (type INTEGER))
  (slot did_something (type SYMBOL) (allowed-values FALSE TRUE))
  (slot is_assigned (type SYMBOL) (allowed-values FALSE TRUE))
)

(deftemplate assigned_order
  (slot order_id (type INTEGER))
  (slot robot_id (type INTEGER))
)

(deftemplate base_order_from_machine
  (slot order_id (type INTEGER))
  (slot robot_id (type INTEGER))
  (slot color (type STRING))
  (slot position (type STRING))
)

; facts
(deffacts robottasks
  (tasks_overview (robot_id 1) (robot_type PRODUCTION) (task_id 1) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (state IDLE) (move_target "M-BS") (machine_target "input" ))
  (tasks_overview (robot_id 2) (robot_type PRODUCTION) (task_id 1) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (state IDLE) (move_target "M-BS") (machine_target "output" ))
  (tasks_overview (robot_id 3) (robot_type PAYMENT) (task_id 1) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (state IDLE) (move_target "M-BS") (machine_target "output" ))
  (check_robot (robot_id 1) (did_something FALSE) (is_assigned FALSE))
  (check_robot (robot_id 2) (did_something FALSE) (is_assigned FALSE))
  (check_robot (robot_id 3) (did_something FALSE) (is_assigned FALSE))
)

(deffacts machine_facts
  (machine_task_overview (machine_id M-CS1) (machine_task NOT-SET))
  (machine_task_overview (machine_id M-BS) (machine_task NOT-SET))
  (machine_payment_info (machine_id M-RS1) (money 0))
  (machine_payment_info (machine_id M-RS2) (money 0))
)


; ==================================================================================
; FUNCTIONS
; ==================================================================================

; Move
(deffunction send_move_to_cmd (?r_id ?r_target ?m_point ?peer-id ?task_id)
  (bind ?move_msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move_msg "waypoint" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "move" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "Move: robot: " ?r_id " task " ?task_id crlf)
)

; Retrieve
(deffunction send_retrieve_from_cmd (?r_id ?r_target ?m_point ?peer-id ?task_id)
  (bind ?move_msg (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?move_msg "machine_id" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "retrieve" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "Retrieve: robot: " ?r_id " task " ?task_id " " ?r_target " " ?m_point " " ?peer-id crlf)
)

; Deliver
(deffunction send_deliver_to_cmd (?r_id ?r_target ?m_point ?peer-id ?task_id)
  (bind ?move_msg (pb-create "llsf_msgs.Deliver"))
  (pb-set-field ?move_msg "machine_id" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "deliver" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "delivery: robot: " ?r_id " task " ?task_id crlf)
)

; BufferStation
(deffunction send_robot_to_bufferStation (?r_id ?r_target ?peer-id ?task_id)
  (bind ?buffer_msg (pb-create "llsf_msgs.BufferStation"))
  (pb-set-field ?buffer_msg "machine_id" ?r_target)
  (pb-set-field ?buffer_msg "shelf_number" 1)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?task_id)
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "buffer" ?buffer_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "BufferStation: robot: " ?r_id " task " ?task_id crlf)
)

; Retrieve from Machine
(deffunction send_cmd_to_machine (?m_id ?operation ?peer-id)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionCS")) 
  (pb-set-field ?prep-msg "operation" ?operation) ; "RETRIEVE_CAP")

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_cs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)

; Prepare Machine
(deffunction prepare_basestation (?m_id ?side ?color ?peer-id)
  (printout red "first message in prepare_basestation" ?m_id " " ?side " " ?color " " ?peer-id crlf)
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionBS")) 
  (pb-set-field ?prep-msg "side" ?side)
  (pb-set-field ?prep-msg "color" ?color)

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m_id)
  (pb-set-field ?msg "instruction_bs" ?prep-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red ?m_id " " ?side " " ?color " " ?peer-id crlf)
)

; Which Machine to bribe?
(deffunction check_payment (?m_one ?m_two)
  ;(printout green "The Ring-stations should have " ?m_one " and " ?m_two crlf)
  (if(< ?m_one 3)then
    (return "M-RS1")
  )
  (if(< ?m_two 3) then
    (return "M-RS2")
  )
  (return "NONE")
)

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
  (printout red "Test Assigned robot" ?rid " to order " ?oid crlf)
)

; ==================================================================================
; Manage ROBOT1 for Production
; ==================================================================================
(defrule move_robot_order_based
  ?tasks_overview <- (tasks_overview (robot_id ?rid) (robot_type PRODUCTION) (task_id ?tid) (state ?robot_state))
  ?check_robot <- (check_robot (robot_id ?rid) (did_something FALSE) (is_assigned TRUE))
  (assigned_order (order_id ?oid) (robot_id ?rid))
  ?order <- (order (id ?oid) (name ?order-name) (base-color ?base-color)); (workpiece ?workpiece) (complexity ?complexity) (ring-colors $?ring-colors) (cap-color ?cap-color) (quantity-requested ?requested) (quantity-delivered ?delivered) (quantity-delivered-other ?other) (delivery-begin ?begin) (delivery-end ?end) (competitive ?competitive))
  (protobuf-peer (name ?peer-name&:(eq ?peer-name (sym-cat ROBOT ?rid))) (peer-id ?peer-id))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name M-BS) (state ?s))
  =>
  (printout blue "Robot " ?peer-name " robot-id " ?rid crlf)
  ; Todo send robot
  ; todo check if robot is 
  ;Get Order
  ;Prepare Basestation PrepareMachine
  (if (eq ?s IDLE) then
    (prepare_basestation "M-BS" "INPUT" ?base-color ?refbox-id)
  )
  (if (eq ?robot_state IDLE) then 
    (send_move_to_cmd ?rid "M-BS" "input" ?peer-id ?tid)
    (modify ?check_robot (did_something TRUE))
    (modify ?tasks_overview (state MOVING))
  )
)


; (defrule send-robot-one-to-pickup
;   (protobuf-peer (name ?n) (peer-id ?peer-id))
;   (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
;   (machine (name M-BS) (state ?s))
;   ?tasks_overview <- (tasks_overview (robot_id 1) (robot_type PRODUCTION) (task_id ?tid) (can_move TRUE) (can_retrieve FALSE) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
;   ?check_robot <- (check_robot (robot_id 1) (did_something FALSE))
;   (test (eq ?n ROBOT1))
;   (test (or (eq ?robot_state IDLE) (eq ?robot_state HOLDING)))
;   =>
;   ;Get Order
;   ;Prepare Basestation PrepareMachine
;   (if (eq ?s IDLE) then
;     (prepare_basestation "M-BS" "OUTPUT" "BASE_BLACK" ?refbox-id)
;   )
;   (if (eq ?robot_state IDLE) then 
;     (send_move_to_cmd 1 ?mot ?mat ?peer-id ?tid)
;     (modify ?check_robot (did_something TRUE))
;     (modify ?tasks_overview (state MOVING))
;   )
;   (if (eq ?robot_state HOLDING) then 
;     (send_move_to_cmd 1 ?mot ?mat ?peer-id ?tid)
;     (modify ?check_robot (did_something TRUE))
;     (modify ?tasks_overview (state CARRY))
;   )
;   (printout red "CARRY " ?n " " ?robot_state " " ?mot " " ?mat " " ?peer-id crlf)
; )

; ==================================================================================
; Manage ROBOTS 3 for Payment
; ==================================================================================
(defrule send-robot-three-to-pickup
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name M-BS) (state ?s))
  ?tasks_overview <- (tasks_overview (robot_id 3) (robot_type PAYMENT) (task_id ?tid) (can_move TRUE) (can_retrieve FALSE) (can_deliver ?cd) (state ?robot_state) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (test (eq ?n ROBOT3))
  (test (or (eq ?robot_state IDLE) (eq ?robot_state HOLDING)))
  =>
  ;Prepare Basestation PrepareMachine
  ; (if (eq ?s IDLE) then
  ;   (prepare_basestation "M-BS" "OUTPUT" "BASE_BLACK" ?refbox-id)
  ; )
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
  (machine (name M-BS) (state ?s))
  (test (eq ?n ROBOT3))
  =>
  (printout red "Basestation is in state " ?s crlf)
  (if (eq ?s READY-AT-OUTPUT) then
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
  (base_order_from_machine (order_id ?oid) (robot_id ?rid) (color ?color) (position ?pos))
  (protobuf-peer (name refbox-private) (peer-id ?refbox-id))
  (machine (name M-BS) (state ?s))
  =>
  (if (eq ?s IDLE) then
    (prepare_basestation "M-BS" ?pos ?color ?refbox-id)
  )
)


; ==================================================================================
; CHECK STUFF
; ==================================================================================
; ==========
; ROBOT 1
; ==========
; Check if Robot 1 did what he was intended to do... 
(defrule check-robot_one
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 1) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 1) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  ;(printout red ?task_id " " ?robot_id " " ?successful " " ?tid " " ?cm " " ?cr " " ?cd crlf)

  ; did task 1 for robot 1 finish? 
  (if (and (eq ?robot_id 1) (eq ?task_id 1) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr TRUE)) then 
    (modify ?tasks_overview (can_move FALSE))
    ; (printout green "robot one finished his task " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    ; (printout green ?task_id ?tid crlf)
  )
  ; did task 2 for robot 1 finish? 
  (if (and (eq ?robot_id 1) (eq ?task_id 2) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE)) then 
    (modify ?tasks_overview (can_retrieve FALSE))
    ; (printout green "robot one finished his task " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    ; (printout green ?task_id ?tid crlf)
  )
)

; ==========
; ROBOT 2
; ==========
(defrule check-robot_two_first_task
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 2) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 2) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  
  ; check task 1 for robot 2
  (if (and (eq ?robot_id 2) (eq ?task_id 1) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr TRUE)) then 
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    ; (printout green "robot two finished his task " ?task_id crlf)
  )

  ; did task 2 for robot 1 finish? 
  (if (and (eq ?robot_id 2) (eq ?task_id 2) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE)) then 
    (modify ?tasks_overview (can_retrieve FALSE))
    ; (printout green "robot two did something " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    ; (printout green ?task_id ?tid crlf)
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

; Check Machine 
(defrule check_machine_M-CS1
  ;(machine (name M-CS1) (state ?s) (type ?t))
  (machine (name M-BS) (state ?s) (type ?t))
  (machine_task_overview (machine_id M-CS1) (machine_task ?mt))
  (not (M-CS1_finished_task1))
  =>
  (printout red "M-BS is in state " ?s " and of type " ?t " and task " ?mt " "(eq ?s READY-AT-OUTPUT)crlf)
  (if (eq ?s READY-AT-OUTPUT) then
    (assert (M-CS1_finished_task1))
  )
)