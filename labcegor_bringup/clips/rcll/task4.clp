(defrule send-robot-task
  "Send a movement task to a robot"
  (robot (state ACTIVE) (name ?robot-name))
  (game-state (state RUNNING))
  =>
  (printout t "Sending move command to " ?robot-name crlf)
  (bind ?task (pb-create "llsf_msgs.AgentTask"))
  (pb-field-set ?task "task_id" 1)
  (pb-field-set ?task "robot_id" 101)
  (pb-field-create-message ?task "move")
  (pb-field-set ?task "move.waypoint" "Zone1")
  (pb-send-message ?task)
)

(defrule peer-send-agent-task-msg
  (client ?pb-peer-create-local-crypto)
  (protobuf-client-connected ?pb-peer-create-local-crypto)
  (not (protobuf-msg))
  =>
  (bind ?msg (pb-create "AgentTask"))

  (printout info "start testing" ?var crlf)
  (pb-set-field ?msg "team_color" "0")
  (pb-set-field ?msg "task_id" "0")
  (pb-set-field ?msg "robot_id" "0")
  (pb-set-field ?msg "move" "C_Z18")
  (pb-send ?c-id ?msg)
  (pb-destroy ?msg)
  (printout info "end testing" ?var crlf)
)

(defrule peer-send-msg
  (client ?c-id)
  (protobuf-client-connected ?c-id)
  (not (protobuf-msg))
  =>
  (bind ?msg (pb-create "SearchRequest"))
  (pb-set-field ?msg "query" "hello")
  (pb-set-field ?msg "page_number" ?c-id)
  (pb-set-field ?msg "results_per_page" ?c-id)
  (pb-send ?c-id ?msg)
  (pb-destroy ?msg)
)

(defrule protobuf-msg-read
  (protobuf-msg (type ?type) (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type ?c-type) (client-id ?c-id) (ptr ?ptr))
  =>
  (printout blue ?c-id "("?c-type") received" ?type
    " (" ?comp-id " " ?msg-type ") from " ?address ":" ?port "
    " (- (now)  ?rcvd-at) "s ago" crlf
  )
  (bind ?var (pb-tostring ?ptr))
  (printout yellow ?var crlf)
)

(defrule protobuf-close
  (executive-finalize)
  ?f <- (client ?any-client)
  =>
  (pb-disconnect ?any-client)
  (pb-server-disable)
  (retract ?f)
)