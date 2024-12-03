; functions for processing messages:
(bind ?res (pb-field-names ?msg))
(bind ?res (pb-field-type ?msg ?field-name))
(bind ?res (pb-has-field ?msg ?field-name))
(bind ?res (pb-field-label ?msg ?field-name))
(bind ?res (pb-field-value ?msg ?field-name))
(bind ?res (pb-field-list ?msg ?field-name))
(bind ?res (pb-field-is-list ?msg ?field-name))
(bind ?res (pb-create ?full-name))
(pb-set-field ?msg ?field-name ?value)
(pb-add-list ?msg ?field-name ?list)
;
(bind ?res (pb-tostring ?msg))

; functions for using a stream server or clients
(pb-server-enable ?port)
(pb-server-disable)
(pb-send ?client-id ?msg)
(bind ?res (pb-connect ?host ?port))
(pb-disconnect ?client-id)

; functions for using broadcast peers
(bind ?res (pb-peer-create ?address ?port))
(bind ?res (pb-peer-create-local ?address ?send-port ?recv-port))
(bind ?res (pb-peer-create-crypto ?address ?port ?crypto ?cypher))
(bind ?res (pb-peer-create-local-crypto ?address ?send-port ?recv-port ?crypto ?cypher))
(pb-peer-destroy ?peer-id)
(pb-peer-setup-crypto ?peer-id ?key ?cypher)
(pb-broadcast ?peer-id ?msg)

; In order to use types from a linked library, they need to be registered via this function first.
(bind ?res (pb-register-type ?full-name))    ; returns TRUE if successful, FALSE otherwise

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



