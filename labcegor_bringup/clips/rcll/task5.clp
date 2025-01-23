; Here is my stuff
(defglobal ?*global_task_id_base* = 0)

(deftemplate tasks_overview
  (slot robot_id (type INTEGER))
  (slot task_id (type INTEGER))
  (slot can_move (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_retrieve (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_deliver (type SYMBOL) (allowed-values FALSE TRUE))
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
)
; facts
(deffacts robottasks
  (tasks_overview (robot_id 1) (task_id 1) (can_move TRUE) (can_retrieve TRUE) (can_deliver TRUE) (move_target "M-CS1") (machine_target "input" ))
  (tasks_overview (robot_id 2) (task_id 1) (can_move TRUE) (can_retrieve TRUE) (can_deliver TRUE) (move_target "M-CS1") (machine_target "output" ))
  (tasks_overview (robot_id 3) (task_id 1) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (move_target "M-BS") (machine_target "output" ))
  (check_robot (robot_id 1) (did_something FALSE))
  (check_robot (robot_id 2) (did_something FALSE))
  (check_robot (robot_id 3) (did_something FALSE))
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
  (pb-set-field ?prep-msg "side" "OUTPUT")
  (pb-set-field ?prep-msg "color" "BASE_BLACK")

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
  (if(<= ?m_one 3)then
    (return "M-RS1")
  )
  (if(<= ?m_two 3) then
    (return "M-RS2")
  )
  (return "NONE")
)



; ==================================================================================
; MOVE ROBOTS & Do Tasks
; ==================================================================================

; ; Move robot 1
; ; 1. send Robot 1 to cs1 input
; (defrule send-robot-one-to-mashine
;   (protobuf-peer (name ?n) (peer-id ?peer-id))
;   (tasks_overview (robot_id 1) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
;   (test (eq ?n ROBOT1))
;   (not (robot1_send_to_machine))
;   =>
;   (send_move_to_cmd 1 ?mot ?mat ?peer-id ?tid)
;   (assert (robot1_send_to_machine))
; )

; ; 2. & 3. Get Cap from shelf and place on Machine
; (defrule buffer-cap-robot-one
;   (protobuf-peer (name ?n) (peer-id ?peer-id))
;   (tasks_overview (robot_id 1) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
;   (test (eq ?n ROBOT1))
;   (not (robot1_buffer_cap))
;   => 
;   (printout green "BufferStation robot 1 current task id:" ?tid crlf)
;   (if (and (eq ?cm FALSE) (eq ?cr TRUE) (not (eq ?tid 1))) then
;     (send_robot_to_bufferStation 1 ?mot ?peer-id ?tid)
;     (printout blue "BufferStation should do something" ?tid crlf)
;     (assert (robot1_buffer_cap))
;   )
; )

; ; 4. Prepare Machine
; (defrule prepare_machine
;   (protobuf-peer (name refbox-private) (peer-id ?peer-id))
;   (tasks_overview (robot_id 1) (task_id ?tid_one) (can_move ?cm_one) (can_retrieve ?cr_one) (can_deliver ?cd_one) (move_target ?mot) (machine_target ?mat))
;   (not (proces_cap_one_CS1))
;   =>
;   (printout red "prepare_machine robot_one task_id " ?tid_one " " ?cm_one " " ?cr_one " test: " (< ?tid_one 1) " " (> ?tid_one 1) crlf)
;   (printout green (and (eq ?tid_one 3) (eq ?cm_one FALSE) (eq ?cr_one FALSE)) crlf)
;   (if (and (eq ?tid_one 3) (eq ?cm_one FALSE) (eq ?cr_one FALSE)) then
;     (send_cmd_to_machine ?mot "RETRIEVE_CAP" ?peer-id)
;     (assert (proces_cap_one_CS1))
;     (printout blue "the machine should do something " crlf)
;     (printout red "part 2/2" crlf)
;   ) 
; )

; ; 5. send Robot 2 to cs1 output 
; (defrule send-robot-two-to-mashine
;   (protobuf-peer (name ?n) (peer-id ?peer-id))
;   (tasks_overview (robot_id 2) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
;   (test (eq ?n ROBOT2))
;   (not (robot2_send_to_machine))
;   =>
;   (send_move_to_cmd 2 ?mot ?mat ?peer-id ?tid)
;   (printout red "part 1/2" crlf)
;   (assert (robot2_send_to_machine))
; )

; ; 6. After 4. finish pickup with second robot
; (defrule robot_two_pickup_disk
;   (protobuf-peer (name ?n) (peer-id ?peer-id))
;   (tasks_overview (robot_id 2) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
;   (test (eq ?n ROBOT2))
;   (and (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cc TRUE))
;   (proces_cap_one_CS1)
;   (M-CS1_finished_task1)
;   (not (robot_two_picked_up_disk))
;   => 
;   ; if prepare Machine.Successful and robot_two ready then pick-up
;   (if (and (eq ?tid 2) (eq ?cm TRUE) (eq ?cr FALSE)) then
;     (send_retrieve_from_cmd 2 ?mot ?mat ?peer-id ?tid)
;     (assert (robot_two_picked_up_disk))
;     (printout blue "Robot 2 tried something " crlf)
;   )
; )

; ==================================================================================
; Manage ROBOTS 3
; ==================================================================================
(defrule send-robot-three-to-pickup
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (tasks_overview (robot_id 3) (task_id ?tid) (can_move TRUE) (can_retrieve ?FALSE) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (machine (name M-BS) (state ?s))
  (test (eq ?n ROBOT3))
  =>
  ;Prepare Basestation PrepareMachine
  (prepare_basestation "M-BS" "OUTPUT" "BASE_BLACK" refbox-private)
  (send_move_to_cmd 3 ?mot ?mat ?peer-id ?tid)
  (printout red "part 1/3 " ?n crlf)
  (modify ?check_robot (did_something TRUE))
)

(defrule robot-three-pickup-base
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (tasks_overview (robot_id 3) (task_id ?tid) (can_move FALSE) (can_retrieve TRUE) (can_deliver FALSE) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (machine (name M-BS) (state ?s))
  (test (eq ?n ROBOT3))
  =>
  (printout red "Basestation is in state " ?s crlf)
  (if (eq ?s READY-AT-OUTPUT) then
    (send_retrieve_from_cmd 3 ?mot ?mat ?peer-id ?tid)
    ;(printout blue "part 2/3" crlf)
    (modify ?check_robot (did_something TRUE))
  )
)


(defrule robot-three-deliver-base
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (tasks_overview (robot_id 3) (task_id ?tid) (can_move FALSE) (can_retrieve FALSE) (can_deliver TRUE) (move_target ?mot) (machine_target ?mat))
  ?check_robot <- (check_robot (robot_id 3) (did_something FALSE))
  (test (eq ?n ROBOT3))
  =>
  (send_deliver_to_cmd 3 ?mot ?mat ?peer-id ?tid)
  ;(printout blue "part 3/3" crlf)
  (modify ?check_robot (did_something TRUE))
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
    (printout green "robot one finished his task " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (printout green ?task_id ?tid crlf)
  )
  ; did task 2 for robot 1 finish? 
  (if (and (eq ?robot_id 1) (eq ?task_id 2) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE)) then 
    (modify ?tasks_overview (can_retrieve FALSE))
    (printout green "robot one finished his task " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (printout green ?task_id ?tid crlf)
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
; ROBOT 3
; ==========
(defrule check-robot_three
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 3) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 3) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd) (move_target ?mot) (machine_target ?mat))
  (machine_payment_info (machine_id M-RS1) (money ?m_one))
  (machine_payment_info (machine_id M-RS2) (money ?m_two))
  ?check_robot <- (check_robot (robot_id 3) (did_something TRUE))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  (bind ?target (check_payment ?m_one ?m_two))
  
  ; It has moved
  (if (and (eq ?robot_id 3) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd FALSE)) then 
    (printout green "robot three finished his task " ?task_id  crlf)
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
  )
  
  ; It has moved
  (if (and (eq ?robot_id 3) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
    (printout green "robot three finished his task " ?task_id " " ?target crlf)
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
  )

  (if (and (eq ?robot_id 3) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE) (eq ?cd FALSE)) then 
    ; TODO check ?target == "NONE" and do something else if thats the case
    (printout green "robot three did something " ?task_id " " ?target crlf)
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver TRUE))
    (modify ?tasks_overview (move_target ?target))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
  )

  (if (and (eq ?robot_id 3) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr FALSE) (eq ?cd TRUE)) then 
    (printout green "robot three did something " ?task_id " " ?target crlf)
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (modify ?tasks_overview (can_deliver FALSE))
    (modify ?tasks_overview (move_target "M-BS"))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (modify ?check_robot (did_something FALSE))
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