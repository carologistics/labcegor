; Here is my stuff
(defglobal ?*global_task_id_base* = 0)

(deftemplate tasks_overview
  (slot robot_id (type INTEGER))
  (slot can_move (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_retrieve (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_deliver (type SYMBOL) (allowed-values FALSE TRUE))
)

; facts
(deffacts robottasks
  (tasks_overview (robot_id 1) (can_move FALSE) (can_retrieve FALSE) (can_deliver FALSE))
  (tasks_overview (robot_id 2) (can_move FALSE) (can_retrieve FALSE) (can_deliver FALSE))
  (tasks_overview (robot_id 3) (can_move FALSE) (can_retrieve FALSE) (can_deliver FALSE))
)



; ==================================================================================
; FUNCTIONS
; ==================================================================================

; Move
(deffunction send_move_to_cmd (?r_id ?r_target ?m_point ?peer-id)
  (bind ?move_msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move_msg "waypoint" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" (+ ?*global_task_id_base* ?r_id))
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "move" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout red "task_id move" crlf)
  (printout red ?r_id crlf)
  (printout red (+ ?*global_task_id_base* ?r_id) crlf)
  (modify ?*global_task_id_base* (+ ?*global_task_id_base* 3))
)

; Retrieve
(deffunction send_retrieve_from_cmd (?r_id ?r_target ?m_point ?peer-id)
  (bind ?move_msg (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?move_msg "machine_id" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" (+ ?*global_task_id_base* ?r_id))
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "retrieve" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout green "task_id Retrieve" crlf)
  (printout green ?r_id crlf)
  (printout green (+ ?*global_task_id_base* ?r_id) crlf)
  (modify ?*global_task_id_base* (+ ?*global_task_id_base* 3))
)

; Deliver
(deffunction send_deliver_to_cmd (?r_id ?r_target ?m_point ?peer-id)
  (bind ?move_msg (pb-create "llsf_msgs.Deliver"))
  (pb-set-field ?move_msg "machine_id" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" (+ ?*global_task_id_base* ?r_id))
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "deliver" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "task_id delivery" crlf)
  (printout blue ?r_id crlf)
  (printout blue (+ ?*global_task_id_base* ?r_id) crlf)
  (modify ?*global_task_id_base* (+ ?*global_task_id_base* 3))
)

; BufferStation
(deffunction send_robot_to_bufferStation (?r_id ?r_target ?peer-id)
  (bind ?move_msg (pb-create "llsf_msgs.BufferStation"))
  (pb-set-field ?move_msg "machine_id" ?r_target)
  (pb-set-field ?move_msg "shelf_number" 1)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" (+ ?*global_task_id_base* ?r_id))
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "bufferstation" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout blue "task_id BufferStation" crlf)
  (printout blue ?r_id crlf)
  (printout blue (+ ?*global_task_id_base* ?r_id) crlf)
  (modify ?*global_task_id_base* (+ ?*global_task_id_base* 3))
)



; ==================================================================================
; MOVE ROBOTS & Do Tasks
; ==================================================================================

; Move robot 1
; 1. send Robot 1 to cs1 input
(defrule send-robot-one-to-mashine
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (test (eq ?n ROBOT1))
  (not (robot-one-is-send))
  =>
  (send_move_to_cmd 1 "M-CS1" "input" ?peer-id)
  (assert (robot-one-is-send))
  (modify ?tasks_overview (can_move FALSE))
  ;retract ?tasks_overview
)

; 2. & 3. Get Cap from shelf and place on Machine
(defrule buffer-cap-robot-one
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?tasks_overview <- (tasks_overview (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (test (eq ?n ROBOT1))
  (not (robot-one-buffer-cap))
  => 
  (printout blue "task_id BufferStation" crlf)
  (printout blue ?cm crlf)
  (printout blue ?cr crlf)
  (if (and (eq ?cm FALSE) (eq ?cr TRUE)) then
    (send_robot_to_bufferStation 1 "M-CS1" ?peer-id)
    (assert (robot-one-buffer-cap))
  )
)


; 5. send Robot 2 to cs1 output 
(defrule send-robot-two-to-mashine
  (game-state (team-color ?team-color))
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (not (robot-two-is-send))
  (test (eq ?n ROBOT2))
  =>
  (send_move_to_cmd 2 "M-CS1" "output" ?peer-id)
  (assert (robot-two-is-send))
  (printout red task_id crlf)
)



; ==================================================================================
; CHECK STUFF
; ==================================================================================

; Check if Robot 1 did what he was intended to do... 
(defrule check-rob1
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 1) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (robot-one-is-send)
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  (printout green ?task_id " " ?robot_id crlf)
  ; did task 1 finish? 
  (if (and (eq ?robot_id 1) (eq ?task_id 1) (eq ?successful TRUE) (eq ?cm TRUE) (eq ?cr FALSE)) then 
    (modify ?tasks_overview (can_move FALSE))
    (modify ?tasks_overview (can_retrieve TRUE))
    (printout green "robot one finished his task " ?task_id crlf)
    (printout green ?task_id crlf)
  )
  (if (and (eq ?robot_id 1) (eq ?successful TRUE) (eq ?cm FALSE) (eq ?cr TRUE)) then 
    (modify ?tasks_overview (can_move TRUE))
    (modify ?tasks_overview (can_retrieve FALSE))
    (printout green "robot one finished his task " ?task_id crlf)
  )
  ; Todo If Robot id == 1 and task-id == 1 and successful allow for next things to happen
)

(defrule check-rob2
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 2) (ptr ?msg))
  ?tasks_overview <- (tasks_overview (robot_id 2) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (robot-two-is-send)
  (not (rob_2_checked))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?robot_id (pb-field-value ?msg "robot_id"))
  (bind ?successful (pb-field-value ?msg "successful"))
  (if (and (eq ?robot_id 2)(eq ?successful TRUE)) then 
    (modify ?tasks_overview (can_move FALSE))
    (assert(rob_2_checked))
  )
  ; Todo If Robot id == 1 and task-id == 1 and successful allow for next things to happen
)




; 2. Retrieve Caps
(defrule retrieve-cap-robot-one
  ?tasks_overview <- (tasks_overview (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (robot_one_moved)
  (not (robot1_retrieved))
  (test (eq ?n ROBOT1))
  (test (eq ?cr TRUE))
  ; ToDo did previous if existing finished?
  ; ToDo did 1. finished?
  =>
  (send_retrieve_from_cmd 1 "M-CS1" "input" ?peer-id)
  (send_move_to_cmd 1 "M-CS2" "output" ?peer-id)

  (printout yellow task_id crlf)
  (assert (robot1_retrieved))
  (retract ?tasks_overview)
)


; Deliver Caps
(defrule peer-send-agent-task-msg
  ?tasks_overview <- (tasks_overview (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (robot_one_moved)
  (test (eq ?n ROBOT1))
  (not (robot1_delivered))
  (test (eq ?cd TRUE))
  ; ToDo did previous task finished?
  =>
  (send_deliver_to_cmd 1 "M-CS2" "input" ?peer-id)

  (printout green task_id crlf)
  (assert (robot1_delivered))
  (retract ?tasks_overview)
)

; Make Rule to grab message and if "successful" allow for next step
; ToDo: find Shelf and get one disk
; ToDo fetch robot status, for next Rule
; ToDo recieve mashine output