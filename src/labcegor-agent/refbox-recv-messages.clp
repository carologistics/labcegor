;;; last modify Dec18 2023, by cyuan
;;; assert fact rather than use wm-fact, but not work in game-state switching, and need to additionally move recv information part in front of domain load in clips_executive.yaml

;(deftemplate refbox-phase
;   (slot value (type SYMBOL))
;)

;(deftemplate refbox-state
;   (slot value (type SYMBOL))
;)

;(deftemplate game-state
;   (slot value (type SYMBOL))
;)


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
  (not (wm-fact (id "/refbox/phase")))
  ; (not (wm-fact (id "/refbox/state"))) 
  
  ; (not (refbox-state (value ?new_state)))
  ; (not (wm-fact (key refbox state) (value ?old-state))) 
  =>
  (assert
    ; (refbox-phase (value PRE_GAME))
    ; (refbox-state (value WAIT_START))
    ; (game-state (value WAIT_START))
    (wm-fact (id "/refbox/phase")  (value PRE_GAME) )
    (wm-fact (id "/refbox/state")  (value WAIT_START) )
    (wm-fact (id "/game/state")  (value WAIT_START) )
    (wm-fact (key refbox beacon seq) (type UINT) (value 1))
  )
)

(defrule refbox-recv-GameState
  ?pf <- (protobuf-msg (type "llsf_msgs.GameState") (ptr ?p) (rcvd-from ?host ?port))
  ; ?rp <- (refbox-phase (value ?phase))
  ; ?rs <- (refbox-state (value ?state))
  ?rp <- (wm-fact (id "/refbox/phase")  (value ?phase) )
  ?rs <- (wm-fact (id "/refbox/state")  (value ?state) )
  =>
  (retract ?pf)

  (bind ?new-state (pb-field-value ?p "state"))
  (bind ?new-phase (pb-field-value ?p "phase"))
  (if (neq ?phase ?new-phase) then
    (retract ?rp)
    ; (assert (refbox-phase (value ?new-phase)))
    (assert  (wm-fact (id "/refbox/phase")  (value ?new-phase) ))
  )
  (if (neq ?state ?new-state) then
    (retract ?rs)
    ; (assert (refbox-state (value ?new-state)))
    (assert  (wm-fact (id "/refbox/state")  (value ?new-state) ))
  )
  (bind ?time (pb-field-value ?p "game_time"))
)


; how to use ?
(defrule refbox-recv-RobotInfo
  ?pf <- (protobuf-msg (type "llsf_msgs.RobotInfo") (ptr ?r))
  =>
  (foreach ?p (pb-field-list ?r "robots")
    (bind ?state (sym-cat (pb-field-value ?p "state")))
    (bind ?robot (sym-cat (pb-field-value ?p "name")))
    (bind ?old-state nil)
    (do-for-fact ((?wm wm-fact)) (wm-key-prefix ?wm:key (create$ monitoring state args? r ?robot))
      (bind ?old-state ?wm:value)
      (retract ?wm)
    )
    (assert (wm-fact (key monitoring state args? r ?robot) (is-list FALSE) (type SYMBOL) (value ?state)))
    (if (and (eq ?old-state MAINTENANCE)
             (eq ?state ACTIVE))
     then
      (assert (wm-fact (key central agent robot-waiting args? r ?robot)))
    )
    (if (and (eq ?old-state ACTIVE)
             (neq ?state ACTIVE))
     then
      (assert (reset-robot-in-wm ?robot))
    )
  )
)


; receive machine information, how to use that ?
(defrule refbox-recv-MachineInfo
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.MachineInfo") (ptr ?p))
  ; (wm-fact (id "/refbox/team-color") (value ?team-color&:(neq ?team-color nil)))
  =>
  ; (printout t "***** Received MachineInfo *****" crlf)
  (bind ?machines (create$)) ;keep track of the machines that actually exist

  (foreach ?m (pb-field-list ?p "machines")
    (bind ?m-name (sym-cat (pb-field-value ?m "name")))
    (bind ?machines (insert$ ?machines(+ (length$ ?machines) 1) ?m-name))
    (bind ?m-type (sym-cat (pb-field-value ?m "type")))
    (bind ?m-team (sym-cat (pb-field-value ?m "team_color")))
    (bind ?m-state (sym-cat (pb-field-value ?m "state")))
    (if (not (any-factp ((?wm-fact wm-fact))
              (and  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-state))
                    (eq ?m-name (wm-key-arg ?wm-fact:key m)))))
      then
      (if (eq ?team-color ?m-team) then
        (assert (wm-fact (key domain fact mps-state args? m ?m-name s ?m-state) (type BOOL) (value TRUE) ))
      )
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

