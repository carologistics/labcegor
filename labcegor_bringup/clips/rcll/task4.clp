(assert global-task-id 0)

; Here is my stuff
(defrule peer-send-agent-task-msg
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT1))
  =>
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (bind ?robot_id 1)
  (bind ?move_msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move_msg "waypoint" "M-CS2")
  (pb-set-field ?move_msg "machine_point" "outpot")

  (printout info "start testing" crlf)
  (printout info ?peer-id crlf)
  (printout info ?n crlf)

  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" global-task-id + ?robot_id)
  (pb-set-field ?msg "robot_id" ?robot_id)
  (pb-set-field ?msg "move" ?move_msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (modify global-task_id (+ global-task_id 3))

  (printout info task_id crlf)
  (printout info "end testing" crlf)
)