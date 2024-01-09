;;; last modify Dec18 2023, by cyuan

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
  ; (not (refbox-phase (value ?old_phase)))
  ; (not (wm-fact (id "/refbox/phase")))
  (not (wm-fact (id "/refbox/team-color")))
  =>
  (assert
    (wm-fact (id "/refbox/team-color") )
    (wm-fact (id "/refbox/phase")  (value PRE_GAME) )
    (wm-fact (id "/refbox/state")  (value WAIT_START) )
    (wm-fact (id "/game/state")  (value WAIT_START) )
    (wm-fact (key refbox beacon seq) (type UINT) (value 1))
  )
)

(defrule refbox-recv-GameState
  ?pf <- (protobuf-msg (type "llsf_msgs.GameState") (ptr ?p) (rcvd-from ?host ?port))
  ?rp <- (wm-fact (id "/refbox/phase")  (value ?phase) )
  ?rs <- (wm-fact (id "/refbox/state")  (value ?state) )
  ?tc <- (wm-fact (id "/refbox/team-color")  (value ?team-color))
  (wm-fact (key config agent team)  (value ?team-name) )
  =>
  (retract ?pf)

  ; for debug
  ;(bind ?team-name "Carologistics")
  ;(bind ?team-color CYAN)
  
  (bind ?new-state (pb-field-value ?p "state"))
  (bind ?new-phase (pb-field-value ?p "phase"))
  (bind ?new-team-color ?team-color)

  (if (and (pb-has-field ?p "team_cyan")
           (eq (pb-field-value ?p "team_cyan") ?team-name))
    then (bind ?new-team-color CYAN))
  (if (and (pb-has-field ?p "team_magenta")
           (eq (pb-field-value ?p "team_magenta") ?team-name))
    then (bind ?new-team-color MAGENTA))

  (if (neq ?new-team-color ?team-color) then
    (printout warn "Switching team color from " ?team-color " to " ?new-team-color crlf)
    (retract ?tc)
    (assert (wm-fact (id "/refbox/team-color") (value ?new-team-color)))
  )

  (if (neq ?phase ?new-phase) then
    (retract ?rp)
    (assert  (wm-fact (id "/refbox/phase")  (value ?new-phase) ))
  )
  (if (neq ?state ?new-state) then
    (retract ?rs)
    (assert  (wm-fact (id "/refbox/state")  (value ?new-state) ))
  )
  (bind ?time (pb-field-value ?p "game_time"))
)

; receive machine information, how to use that ?
(defrule refbox-recv-MachineInfo
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.MachineInfo") (ptr ?p))
  ; (wm-fact (id "/refbox/team-color") (value ?team-color&:(neq ?team-color nil)))
  =>
  ; (retract ?pb-msg)
  ; (printout t "***** Received MachineInfo *****" crlf)
  (bind ?machines (create$)) ;keep track of the machines that actually exist
  
  (foreach ?m (pb-field-list ?p "machines")
    (bind ?m-name (sym-cat (pb-field-value ?m "name")))
    (bind ?machines (insert$ ?machines(+ (length$ ?machines) 1) ?m-name))
    (bind ?m-type (sym-cat (pb-field-value ?m "type")))
    (bind ?m-team (sym-cat (pb-field-value ?m "team_color")))
    (bind ?m-state (sym-cat (pb-field-value ?m "state")))
    
    ; (assert (wm-fact (key machine name) (value ?m-name)))    
    ; (assert (wm-fact (key machine state) (value ?m-state)))   ; 

    (if (not (any-factp ((?wm-fact wm-fact))
              (and  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-state))
                    (eq ?m-name (wm-key-arg ?wm-fact:key m)))))
      then
      ;(if (eq ?team-color ?m-team) then
      ;  (assert (wm-fact (key domain fact mps-state args? m ?m-name s ?m-state) (type BOOL) (value TRUE) ))
      ;)
    ; set available rings for ring-stations
      (if (eq ?m-type RS) then
        (progn$ (?rc (pb-field-list ?m "ring_colors"))
          (assert (wm-fact (key domain fact rs-ring-spec args? m ?m-name r ?rc rn NA) (type BOOL) (value TRUE)))
        )
      )
    )
   (do-for-fact ((?wm-fact wm-fact))
                  (and  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-state))
                        (eq ?m-name (wm-key-arg ?wm-fact:key m))
                        (neq ?m-state (wm-key-arg ?wm-fact:key s)))
      (retract ?wm-fact)
      (assert (wm-fact (key domain fact mps-state args? m ?m-name s ?m-state) (type BOOL) (value TRUE)))
    )
  )
  ;remove machines that do not exist
  (do-for-all-facts ((?wm-fact wm-fact))
      (or   (and  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-team))
              (not (member$ (wm-key-arg ?wm-fact:key m) ?machines))
            )
            (and  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-side-free))
              (not (member$ (wm-key-arg ?wm-fact:key m) ?machines))
            )
            (and  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-state))
              (not (member$ (wm-key-arg ?wm-fact:key m) ?machines))
            )
            (and  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-type))
              (not (member$ (wm-key-arg ?wm-fact:key m) ?machines))
            )
            (and  (wm-key-prefix ?wm-fact:key (create$ domain fact cs-color))
              (not (member$ (wm-key-arg ?wm-fact:key m) ?machines))
            )
            (and  (wm-key-prefix ?wm-fact:key (create$ domain fact rs-ring-spec))
              (not (member$ (wm-key-arg ?wm-fact:key m) ?machines))
              (neq (wm-key-arg ?wm-fact:key r) RING_NONE)
            )
      )
      (retract ?wm-fact)
  )
)

