(defrule refbox-recv-BeaconSignal
  ?pf <- (protobuf-msg (type "llsf_msgs.BeaconSignal") (ptr ?p))
  (time $?now)
  =>
  (bind ?beacon-name (pb-field-value ?p "peer_name"))
  (printout debug "Beacon Recieved from " ?beacon-name crlf)
  (retract ?pf)
)

(defrule refbox_init
  (executive-init)
  (time $?now)
  (not (wm-fact (id "/refbox/phase")))
  (not (wm-fact (key refbox state) (value ?old-state)))
  =>
  (assert
    (wm-fact (id "/refbox/phase")  (value PRE_GAME) )
    (wm-fact (id "/refbox/state")  (value WAIT_START) )
    (wm-fact (id "/game/state")  (value WAIT_START) )
  )
)

(defrule refbox-recv-GameState
  ?pf <- (protobuf-msg (type "llsf_msgs.GameState") (ptr ?p) (rcvd-from ?host ?port))
  ?rp <- (wm-fact (id "/refbox/phase")  (value ?phase) )
  ?rs <- (wm-fact (id "/refbox/state")  (value ?state) )
  =>
  (retract ?pf ?rp ?rs)
  (bind ?new-state (pb-field-value ?p "state"))
  (bind ?new-phase (pb-field-value ?p "phase"))
  (if (neq ?phase ?new-phase) then
    (retract ?rp)
    (assert  (wm-fact (id "/refbox/phase")  (value ?new-phase) ))
  )
  (if (neq ?state ?new-state) then
    (retract ?rs)
    (assert  (wm-fact (id "/refbox/state")  (value ?new-state) ))
  )
  (bind ?time (pb-field-value ?p "game_time"))
  ; (bind ?sec (pb-field-value ?time "sec"))
  ; (bind ?nsec (pb-field-value ?time "nsec"))
)
