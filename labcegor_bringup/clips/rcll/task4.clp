; Here is my stuff
(defrule peer-send-agent-task-msg
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT1))
  =>
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (bind ?robot_id 1)
  (bind ?move_msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move_msg "waypoint" "M-CS2")
  (pb-set-field ?move_msg "machine_point" "output")

  (printout info "start testing" crlf)
  (printout info ?peer-id crlf)
  (printout info ?n crlf)

  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 1)
  (pb-set-field ?msg "robot_id" ?robot_id)
  (pb-set-field ?msg "move" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (printout info task_id crlf)
  (printout error "end testing" crlf)
)