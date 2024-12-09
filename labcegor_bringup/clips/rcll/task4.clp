; Here is my stuff
(defglobal ?*global_task_id_base* = 0)

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
)

; Move robots 
; 1. send Robot 1 to cs1 input
(defrule send-robot-one-to-mashine
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT1))
  =>
  (send_move_to_cmd 1 "M-CS1" "input" ?peer-id)

  (printout info task_id crlf)
)


; 5. send Robot 2 to cs1 output 
(defrule send-robot-two-to-mashine
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT2))
  =>
  (send_move_to_cmd 2 "M-CS1" "output" ?peer-id)

  (printout info task_id crlf)
)

; 2. Retrieve Caps
(defrule retrieve-cap-robot-one
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT1))
  =>
  (send_retrieve_from_cmd 1 "M-CS1" "input" ?peer-id)

  (printout info task_id crlf)
)


; Deliver Caps
(defrule peer-send-agent-task-msg
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT1))
  =>
  (send_deliver_to_cmd 1 "M-CS1" "input" ?peer-id)

  (printout info task_id crlf)
)

; Make Rule to grab message and if "succsefull" allow for next step
; ToDo: find Shelf and get one disk
; ToDo fetch robot status, for next Rule
; ToDo recieve mashine output