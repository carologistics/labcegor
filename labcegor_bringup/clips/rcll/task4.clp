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
)

; Move robots 
; 1. send Robot 1 to cs1 input
(defrule send-robot-one-to-mashine
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?tasks <- (tasks (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (test (eq ?n ROBOT1))
  (not (robot-one-is-send))
  =>
  (send_move_to_cmd 1 "M-CS1" "input" ?peer-id)
  (assert (robot-one-is-send))
  (assert (?cm FALSE))
  retract ?tasks
)


; Check if Robot 1 did what he was intended to do... 
(defrule check-rob1
  (protobuf-msg (type "llsf_msgs.AgentTask") (client-type PEER) (client-id 1) (ptr ?msg))
  ?tasks <- (tasks (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  =>
  (bind ?task_id (pb-field-value ?msg "task_id"))
  (bind ?succsefull (pb-field-value ?msg "successful"))
  (bind ?task_id (pb-field-value ?msg "robot_id"))
  (if (?succsefull && (eq ?task_id 1)) then (assert (?cm FALSE)))
  ; Todo If Robot id == 1 and task-id == 1 and succesfull allow for next things to happen
  retract ?tasks
)


; 5. send Robot 2 to cs1 output 
(defrule send-robot-two-to-mashine
  (game-state (team-color ?team-color))
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT2))
  =>
  (send_move_to_cmd 2 "M-CS1" "output" ?peer-id)

  (printout red task_id crlf)
)


; 2. Retrieve Caps
(defrule retrieve-cap-robot-one
  ?tasks <- (tasks (robot_id 1) (can_move ?cm) (can_retrieve ?cr) (can_deliver ?cd))
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (robot_one_moved)
  (not (robot1_retrieved))
  (test (eq ?n ROBOT1))
  (?cr)
  ; ToDo did previous if existing finished?
  ; ToDo did 1. finished?
  =>
  (send_retrieve_from_cmd 1 "M-CS1" "input" ?peer-id)

  (printout yellow task_id crlf)
  (assert (robot1_retrieved))
)


; Deliver Caps
(defrule peer-send-agent-task-msg
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (robot_one_moved)
  (test (eq ?n ROBOT1))
  (not (robot1_delivered))
  (?cd)
  ; ToDo did previous task finished?
  =>
  (send_deliver_to_cmd 1 "M-CS2" "input" ?peer-id)

  (printout green task_id crlf)
  (assert (robot1_delivered))
)

; Make Rule to grab message and if "succsefull" allow for next step
; ToDo: find Shelf and get one disk
; ToDo fetch robot status, for next Rule
; ToDo recieve mashine output