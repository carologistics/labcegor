; Here is my stuff
(defglobal ?*global_task_id_base* = 0)

; create function for send task
(deffunction send_target_to_robot (?r_id ?r_target ?m_point ?peer-id)
  (bind ?move_msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move_msg "waypoint" ?r_target)
  (pb-set-field ?move_msg "machine_point" ?m_point)
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" (+ ?global_task_id_base ?r_id))
  (pb-set-field ?msg "robot_id" ?r_id)
  (pb-set-field ?msg "move" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)


 
(defrule peer-send-agent-task-msg
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT1))
  =>
  (send_target_to_robot 1 "M-CS2" "output" ?peer-id)

  (printout info task_id crlf)
  (printout red "end testing" crlf)
)