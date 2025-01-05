; Here is my stuff
(defglobal ?*global_task_id_base* = 0)

(deftemplate tasks_overview
  (slot robot_id (type INTEGER))
  (slot task_id (type INTEGER))
  (slot can_move (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_retrieve (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_deliver (type SYMBOL) (allowed-values FALSE TRUE))
)

(deftemplate machine_task_overview
  (slot machine_id (type SYMBOL))
  (slot task (type SYMBOL))
)
; facts
(deffacts robottasks
  (tasks_overview (robot_id 1) (task_id 1) (can_move FALSE) (can_retrieve FALSE) (can_deliver FALSE))
  (tasks_overview (robot_id 2) (task_id 1) (can_move FALSE) (can_retrieve FALSE) (can_deliver FALSE))
  (tasks_overview (robot_id 3) (task_id 1) (can_move FALSE) (can_retrieve FALSE) (can_deliver FALSE))
)

(deffacts machine_facts
  (machine_task_overview (machine_id M-CS1) (task 0))
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
  (printout blue "Retrieve: robot: " ?r_id " task " ?task_id crlf)
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



; ==================================================================================
; MOVE ROBOTS & Do Tasks
; ==================================================================================

; Move robot 1
; 1. send Robot 1 to cs1 input
(defrule send-robot-one-to-mashine
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (tasks_overview (robot_id 1) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (test (eq ?n ROBOT1))
  (not (robot-one-is-send))
  =>
  (send_move_to_cmd 1 "M-CS1" "input" ?peer-id ?tid)
  (assert (robot-one-is-send))
)

; 2. & 3. Get Cap from shelf and place on Machine
(defrule buffer-cap-robot-one
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (tasks_overview (robot_id 1) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (test (eq ?n ROBOT1))
  (not (robot-one-buffer-cap))
  => 
  (printout green "BufferStation robot 1 current task id:" ?tid crlf)
  (if (and (eq ?cm FALSE) (eq ?cr TRUE) (not (eq ?tid 1))) then
    (send_robot_to_bufferStation 1 "M-CS1" ?peer-id ?tid)
    (printout blue "BufferStation should do something" ?tid crlf)
    (assert (robot-one-buffer-cap))
  )
)

; 4. Prepare Machine
(defrule prepare_machine
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (tasks_overview (robot_id 1) (task_id ?tid_one) (can_move ?cm_one) (can_retrieve ?cr_one) (can_deliver ?cd_one))
  (robot-one-buffer-cap)
  (not (proces_cap_one_CS1))
  =>
  (printout red "prepare_machine robot_one task_id " ?tid_one " " ?cm_one " " ?cr_one " test: " (< ?tid_one 1) " " (> ?tid_one 1) crlf)
  (if (and (eq ?tid_one 2) (eq ?cm_one TRUE) (eq ?cr_one TRUE)) then
    (send_cmd_to_machine "M-CS1" "RETRIEVE_CAP" ?peer-id)
    (assert (proces_cap_one_CS1))
    (printout blue "the machine should do something " crlf)
    (printout red "part 2/2" crlf)
  ) 
)

; 5. send Robot 2 to cs1 output 
(defrule send-robot-two-to-mashine
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (tasks_overview (robot_id 2) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (not (robot-two-is-send))
  (test (eq ?n ROBOT2))
  =>
  (send_move_to_cmd 2 "M-CS1" "output" ?peer-id ?tid)
  (printout red "part 1/2" crlf)
  (assert (robot-two-is-send))
)

; 6. After 4. finish pickup with second robot
(defrule robot_two_pickup_disk
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (tasks_overview (robot_id 2) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (proces_cap_one_CS1)
  (not (robot_two_picked_up_disk))
  (test (eq ?n ROBOT2))
  => 
  ; if prepare Machine.Successfull and robot_two ready then pick-up
  (if (and (eq ?tid 2) (eq ?cm TRUE) (eq ?cr FALSE)) then
    (send_retrieve_from_cmd 2 "M-CS1" "output" ?peer-id ?tid)
    (assert (robot_two_picked_up_disk))
    (printout blue "Robot 2 tried something " crlf)
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
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 1) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 1) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  
  ; did task 1 for robot 1 finish? 
  (if (and (eq ?robot_id 1) (eq ?task_id 1) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr FALSE)) then 
    (modify ?tasks_overview (can_retrieve TRUE))
    (printout green "robot one finished his task " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (printout green ?task_id ?tid crlf)
  )
  ; did task 2 for robot 1 finish? 
  (if (and (eq ?robot_id 1) (eq ?task_id 2) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE)) then 
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (printout green "robot one finished his task " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (printout green ?task_id ?tid crlf)
  )
  (retract ?pb-msg)
)

; ==========
; ROBOT 2
; ==========
(defrule check-robot_two
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 2) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 2) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  
  ; check task 1 for robot 2
  (if (and (eq ?robot_id 2) (eq ?task_id 1) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr FALSE)) then 
    (modify ?tasks_overview (can_retrieve TRUE))
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (printout green "robot two finished his task " ?task_id crlf)
  )
  ; did task 2 for robot 1 finish? 
  (if (and (eq ?robot_id 1) (eq ?task_id 2) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE)) then 
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (printout green "robot two did something " ?task_id crlf)
    (modify ?tasks_overview (task_id (+ ?task_id 1)))
    (printout green ?task_id ?tid crlf)
  )
  (retract ?pb-msg)
)

; Check Machine 
(defrule check_machine_M-CS1
  (machine (name M-CS1) (state ?s) (type ?t))
  ?mto <- (machine_task_overview (machine_id M-CS1) (task ?mt))
  =>
  (printout red "M-CS1 is in state " ?s " and of type " ?t " and task " ?mt crlf)
)

; (defrule check-rob2
;   (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 2) (ptr ?msg))
;   ?tasks_overview <- (tasks_overview (robot_id 2) (task_id ?tid) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
;   (robot-two-is-send)
;   (not (rob_2_checked))
;   =>
;   (bind ?task_id (pb-field-value ?msg "task_id"))
;   (bind ?robot_id (pb-field-value ?msg "robot_id"))
;   (bind ?successful (pb-field-value ?msg "successful"))
;   (if (and (eq ?robot_id 2)(eq ?successful TRUE)) then 
;     (modify ?tasks_overview (can_move FALSE))
;     (modify ?tasks_overview (task_id (+ ?task_id 1)))
;     (assert(rob_2_checked))
;     (printout green "robot two finished his task " ?task_id crlf)
;   )
; )