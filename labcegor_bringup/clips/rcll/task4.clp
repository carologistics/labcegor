; Asserted whenever a message is received
(deftemplate protobuf-msg
  (slot type (type STRING))            ; (package + "." +) message-name
  (slot comp-id (type INTEGER))
  (slot msg-type (type INTEGER))
  (slot rcvd-via (type SYMBOL)
    (allowed-values STREAM BROADCAST)
  )
  (multislot rcvd-from                 ; address and port
    (cardinality 2 2)
  )
  (slot rcvd-at (type FLOAT))          ; ros timestamp in seconds
  (slot client-type (type SYMBOL)
    (allowed-values SERVER CLIENT PEER)
  )
  (slot client-id (type INTEGER))
  (slot ptr (type EXTERNAL-ADDRESS))
)

; Asserted whenever a message handled by a  client could not be processed
(deftemplate protobuf-receive-failed
  (slot comp-id (type INTEGER))
  (slot msg-type (type INTEGER))
  (slot rcvd-via (type SYMBOL)
    (allowed-values STREAM BROADCAST)
  )
  (multislot rcvd-from (cardinality 2 2))
  (slot client-id (type INTEGER))
  (slot message (type STRING))
)

; Asserted whenever a message handled by a server could not be processed
(deftemplate protobuf-server-receive-failed
  (slot comp-id (type INTEGER))
  (slot msg-type (type INTEGER))
  (slot rcvd-via (type SYMBOL)
    (allowed-values STREAM BROADCAST)
  )
  (multislot rcvd-from (cardinality 2 2))
  (slot client-id (type INTEGER))
  (slot message (type STRING))
)

; asynchronously asserted once a client is created via pb-connect
(protobuf-client-connected ?client-id)
; asynchronously asserted once a client is disconnected via pb-disconnect
(protobuf-client-disconnected ?client-id)
; asynchronously asserted once a server is created via pb-server-enable
(protobuf-server-client-connected ?client-id ?endpoint ?port)
; asynchronously asserted once a server is created via pb-server-disable
(protobuf-server-client-connected ?client-id)



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


; Here is my stuff
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



