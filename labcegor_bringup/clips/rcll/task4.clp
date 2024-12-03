; Here is my stuff
(defrule peer-send-agent-task-msg
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  (test (eq ?n ROBOT1))
  =>
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (printout info "start testing" crlf)
  (printout info ?peer-id crlf)
  (printout info ?n crlf)
  (printout info "start testing" crlf)
  (pb-set-field ?msg "team_color" 0)
  (pb-set-field ?msg "task_id" 0)
  (pb-set-field ?msg "robot_id" 0)
  (pb-set-field ?msg "move" "C_Z18")
  (pb-brodcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout info "end testing" crlf)
)



