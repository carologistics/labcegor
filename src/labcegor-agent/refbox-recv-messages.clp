;;; last modify Jan11 2024, by cyuan

(deftemplate order
  (slot id (type INTEGER))
  (slot name (type SYMBOL))
  (slot workpiece (type SYMBOL))
  (slot complexity (type SYMBOL))

  (slot base-color (type SYMBOL))
  (multislot ring-colors (type SYMBOL))
  (slot cap-color (type SYMBOL))

  (slot quantity-requested (type INTEGER))
  (slot quantity-delivered (type INTEGER))
  (slot quantity-delivered-other (type INTEGER))

  (slot delivery-begin (type INTEGER))
  (slot delivery-end (type INTEGER))
  (slot competitive (type SYMBOL))
)

(deftemplate machine
   (slot name (type SYMBOL))
   (slot type (type SYMBOL))
   (slot team-color (type SYMBOL))
   (slot zone (type SYMBOL))
   (slot rotation (type INTEGER))
   (slot state (type SYMBOL))
)

(deftemplate ring-assignment
  (slot machine (type SYMBOL))
  (multislot colors (type SYMBOL))
)


(deftemplate ring-spec
  (slot color (type SYMBOL))
  (slot cost (type INTEGER))
)

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

(defrule refbox-recv-MachineInfo
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.MachineInfo") (ptr ?p))
  (wm-fact (id "/refbox/team-color") (value ?team-color&:(neq ?team-color nil)))
  =>
  (foreach ?m (pb-field-list ?p "machines")
    (bind ?m-name (sym-cat (pb-field-value ?m "name")))
    (bind ?m-type (sym-cat (pb-field-value ?m "type")))
    (bind ?m-team (sym-cat (pb-field-value ?m "team_color")))
    (bind ?m-state (sym-cat (pb-field-value ?m "state")))
    
    (bind ?rot  FALSE)
    (bind ?zone NOT-SET)

    (if (pb-has-field ?m "rotation") then
      (bind ?rot  (pb-field-value ?m "rotation"))
    )
    (if (pb-has-field ?m "zone") then
      (bind ?zone (pb-field-value ?m "zone"))
    )

    (if (eq ?m-type RS) then
      (assert (ring-assignment (machine ?m-name) (colors (pb-field-list ?m "ring_colors"))))
    )
    (assert (machine (name ?m-name) (type ?m-type) (team-color ?m-team) (state ?m-state) (zone ?zone) (rotation ?rot)))
  )
  (delayed-do-for-all-facts ((?m1 machine) (?m2 machine)) (and (< (fact-index ?m1) (fact-index ?m2)) (eq ?m1:name ?m2:name))
    (retract ?m1)
  )
  (delayed-do-for-all-facts ((?ra1 ring-assignment) (?ra2 ring-assignment)) (and (< (fact-index ?ra1) (fact-index ?ra2)) (eq ?ra1:machine ?ra2:machine))
    (retract ?ra1)
  )
  ; (retract ?pb-msg)
)

(defrule refbox-recv-MachineReportInfo
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.MachineReportInfo") (ptr ?p))
  =>
  (bind ?machines (create$))

  (foreach ?m (pb-field-list ?p "reported_types")
    (bind ?m-name (sym-cat (pb-field-value ?m "name")))
    (if (and
          (any-factp ((?wm-fact wm-fact))
              (and (wm-key-prefix ?wm-fact:key (create$ domain fact mps-state))
                    (eq (wm-key-arg ?wm-fact:key m) ?m-name)
              )
          )
          (not
            (any-factp ((?wm-fact wm-fact))
                (and (wm-key-prefix ?wm-fact:key (create$ refbox explored-machine))
                      (eq (wm-key-arg ?wm-fact:key m) ?m-name)
                )
            )
          )
        )
      then
        (assert (wm-fact (key refbox explored-machine args? m ?m-name)))
    )
  )
)


(defrule refbox-recv-OrderInfo
  "Assert products sent by the refbox."
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.OrderInfo") (ptr ?ptr))
  (wm-fact (id "/refbox/team-color") (value ?team-color&:(neq ?team-color nil)))
  =>
  (foreach ?o (pb-field-list ?ptr "orders")
    (bind ?id (pb-field-value ?o "id"))
    (bind ?name (sym-cat O ?id))
    ;check if the order is new
    (bind ?complexity (pb-field-value ?o "complexity"))
    (bind ?competitive (pb-field-value ?o "competitive"))
    (bind ?quantity-requested (pb-field-value ?o "quantity_requested"))
    (bind ?begin (pb-field-value ?o "delivery_period_begin"))
    (bind ?end (pb-field-value ?o "delivery_period_end"))
    (if (pb-has-field ?o "base_color") then
      (bind ?base (pb-field-value ?o "base_color"))
    else
      (bind ?base UNKNOWN)
    )
    (bind ?cap (pb-field-value ?o "cap_color"))
    (bind ?ring-colors (pb-field-list ?o "ring_colors"))
    (if (eq ?team-color CYAN) then
      (bind ?qd-them (pb-field-value ?o "quantity_delivered_magenta"))
      (bind ?qd-us (pb-field-value ?o "quantity_delivered_cyan"))
    else
      (bind ?qd-them (pb-field-value ?o "quantity_delivered_cyan"))
      (bind ?qd-us (pb-field-value ?o "quantity_delivered_magenta"))
    )
    (assert (order 
      (id ?id)
      (name ?name)
      (complexity ?complexity)
      (competitive ?competitive)
      (quantity-requested ?quantity-requested)
      (delivery-begin ?begin)
      (delivery-end ?end)
      (base-color ?base)
      (ring-colors ?ring-colors)
      (cap-color ?cap)
      (quantity-delivered ?qd-us)
      (quantity-delivered-other ?qd-them)
    ))
  )
  (delayed-do-for-all-facts ((?o1 order) (?o2 order)) (and (< (fact-index ?o1) (fact-index ?o2)) (eq ?o1:id ?o2:id))
   (retract ?o1)
  )
  (retract ?pb-msg)
)

(defrule refbox-recv-RingInfo
  ?pb-msg <- (protobuf-msg (type "llsf_msgs.RingInfo") (ptr ?p))
  =>
  (foreach ?r (pb-field-list ?p "rings")
    (bind ?color (pb-field-value ?r "ring_color"))
    (bind ?raw-material (pb-field-value ?r "raw_material"))
    (assert (ring-spec (color ?color) (cost ?raw-material)))
  )
  (delayed-do-for-all-facts ((?rs1 ring-spec) (?rs2 ring-spec)) (and (< (fact-index ?rs1) (fact-index ?rs2)) (eq ?rs1:color ?rs2:color))
   (retract ?rs1)
  )
)

