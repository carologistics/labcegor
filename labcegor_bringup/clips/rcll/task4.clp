
(pb-set-field ?msg ?field-name ?value)


; Here is my stuff
(defrule peer-send-agent-task-msg
  (protobuf-peer (name ?n) (peer-id ?peer-id))
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.AgentTask") (ptr ?p))
  (?n == "ROBOT1")
  =>
  (bind ?msg (protobuf-msg (type "llsf_msgs.AgentTask") (ptr ?p)))

  (printout info "start testing" crlf)
  (printout info ?peer-id crlf)
  (printout info ?n crlf)
  (printout info "start testing" crlf)
  (bind ?msg (pb-create "AgentTask"))
  (pb-set-field ?msg "team_color" "0")
  (pb-set-field ?msg "task_id" "0")
  (pb-set-field ?msg "robot_id" "0")
  (pb-set-field ?msg "move" "C_Z18")
  (pb-brodcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout info "end testing" crlf)
)



