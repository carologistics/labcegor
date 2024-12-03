
(pb-set-field ?msg ?field-name ?value)


; Here is my stuff
(defrule peer-send-agent-task-msg
  (client ?pb-peer-create-local-crypto)
  (protobuf-client-connected ?pb-peer-create-local-crypto)
  (not (protobuf-msg))
  =>
  (bind ?msg (pb-create "AgentTask"))

  (printout info "start testing" crlf)
  (pb-set-field ?msg "team_color" "0")
  (pb-set-field ?msg "task_id" "0")
  (pb-set-field ?msg "robot_id" "0")
  (pb-set-field ?msg "move" "C_Z18")
  (pb-send ?peer-id ?msg)
  (pb-destroy ?msg)
  (printout info "end testing" crlf)
)



