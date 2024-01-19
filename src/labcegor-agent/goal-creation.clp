(defrule goal-creation-prepare-cap
    "cap carrier from shelf -> input"
    ?g <- (goal (id ?goal-id) (class PREPARE-CAPS)(mode FORMULATED))
    (wm-fact (key refbox team-color) (value ?team-color))
    (wm-fact (key domain fact wp-on-shelf args? wp ?cc m ?mps spot ?spot))
    (wm-fact (key domain fact wp-cap-color args? wp ?cc color ?cap-color))

    (wm-fact (key domain fact self args? r ?robot))
    (not (wm-fact (key domain fact holding args? r ?robot wp ?wp-h)))

    (wm-fact (key domain fact mps-type args? m ?mps t CS))
    (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))
    (not (wm-fact (key domain fact wp-at args? wp ?wp-a m ?mps side INPUT)))
    =>
    (printout t "Goal " FILL-CAP " formulated" crlf)

    (assert (goal (id (sym-cat FILL-CAP- (gensym*)))
                (class FILL-CAP) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        mps ?mps
                        cc ?cc
                )
                (required-resources (sym-cat ?mps -INPUT) ?cc)
  ))
)

(defrule goal-creation-rmv-capless-carriers
    " Remove a capless capcarrier from the output of a CS"

  (goal (id ?goal-id) (class CAP-CLEAR) (mode FORMULATED))
  (wm-fact (key refbox team-color) (value ?team-color))
  
  (wm-fact (key domain fact self args? r ?robot))
  (not (wm-fact (key domain fact holding args? r ?robot wp ?wp-h)))
 
  (wm-fact (key domain fact mps-type args? m ?mps t CS))
  (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))

  (wm-fact (key domain fact wp-at args? wp ?wp m ?mps side OUTPUT))
  (wm-fact (key domain fact wp-cap-color args? wp ?wp col CAP_NONE))
  =>
  (printout t "Goal " CLEAR-MPS " ("?mps") formulated" crlf)

  (assert (goal (id (sym-cat CLEAR-MPS- (gensym*)))
                (class CLEAR-MPS) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        mps ?mps
                        wp ?wp
                        side OUTPUT
                )
                (required-resources (sym-cat ?mps -OUTPUT) ?wp)
    ))
)

(defrule goal-creation-clear-bs
  "Take wp -> BS OUTPUT"
  
  (goal (id ?goal-id) (class GETBASE) (mode FORMULATED))
  (wm-fact (key refbox team-color) (value ?team-color))
  
  (wm-fact (key domain fact self args? r ?robot))
  (not (wm-fact (key domain fact holding args? r ?robot wp ?wp-h)))

  (wm-fact (key domain fact mps-type args? m ?mps t BS))
  (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))
  
  (wm-fact (key domain fact wp-at args? wp ?wp m ?mps side ?side))
  =>
  (printout t "Goal " BSOUT " ("?mps") formulated" crlf)
  (assert (goal (id (sym-cat BSOUT- (gensym*)))
                (class BSOUT) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        mps ?mps
                        wp ?wp
                        side ?side
                )
                (required-resources (sym-cat ?mps - ?side) ?wp)
  ))
)

; move to BS, take a base from BS, move to RS, put wp to RS.
; move to RS output and take wp from RS output.
(defrule goal-creation-get-base-to-rs-first-run

  ?trigger_goal <- (goal (id ?goal-id) (class tribs-rs-firstrun) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
  (wm-fact (id "/refbox/team-color") (value ?team-color&:(neq ?team-color nil))) 
  
  ; robot assign, optional: random assignment
  (wm-fact (key domain fact at args? r ?robot x ?loc)) 
  
  (order (id ?order-id) (base-color ?wp))

  ;RS ;rs machine is determined by ring-color in order, and color in ring-assignment 
  ; ring-assignment (machine ?rs) (colors XXX XXX)
  ; ring-assignment (machine ?rs) (colors XXX XXX)

  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color)) 
  )

  =>
  (bind ?bs C-BS) ; must be this name because only one BS
  (bind ?bs-side INPUT) ; hard code now
  (bind ?rs-side INPUT) ; hard code now


  (printout t "Goal " bs-rs-firstrun " formulated" crlf)
  (assert (goal (id (sym-cat bs-rs-firstrun- (gensym*)))
                (class bs-run-firstrun)
                (parent ?goal-id) (sub-type SIMPLE)
                             (params robot ?robot
                                     bs ?bs
                                     bs-side ?bs-side
                                     rs ?rs
                                     rs-side ?rs-side
                                     wp ?wp
				     ring ?ring-color
                                     )
                            (required-resources ?wp)
  ))
  (retract ?trigger_goal)
)


(defrule goal-creation-get-base-to-rs-run
  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop-run) (params order-id ?order-id ring-color ?ring-color))
  ?premise_goal <- (goal (id ?premise_goal_id) (class bs-run-firstrun) (outcome COMPLETED) (params robot ?robot bs ?bs bs-side ?bs-side rs ?pre_rs rs-side ?pre_rs-side wp ?wp))
  
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )

  =>
  (bind ?rs-side INPUT)
  (assert (goal (id (sym-cat rs-loop-run- (gensym*)))
                (class rs-loop-run)
                (parent ?goal-id) (sub-type SIMPLE)
                              (params robot ?robot
    				      rs ?rs
                                      rs-side ?rs-side
                                      wp ?wp)))
  (retract ?trigger_goal)
)



(defrule goal-creation-prefill-ring-station
  "Fill a ring station with the currently holding workpiece"

  (goal (id ?goal-id) (class PREPARE-RINGS) (mode FORMULATED))
  (wm-fact (key refbox team-color) (value ?team-color))
  ;Robot
  (wm-fact (key domain fact self args? r ?robot))
  (wm-fact (key domain fact wp-usable args? wp ?wp))
  (wm-fact (key domain fact holding args? r ?robot wp ?wp-h))
  ;MPS-RS
  (wm-fact (key domain fact mps-type args? m ?mps t RS))
  (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))
  (wm-fact (key domain fact rs-filled-with args? m ?mps n ?rs-before&ZERO|ONE|TWO))
  (wm-fact (key domain fact rs-inc args? summand ?rs-before sum ?rs-after))
  =>
  (printout t "Goal " FILL-RS " formulated" crlf)
  (assert (goal (id (sym-cat FILL-RS- (gensym*)))
                (class FILL-RS) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        mps ?mps
                        wp ?wp
                        rs-before ?rs-before
                        rs-after ?rs-after
                )
                (required-resources ?mps ?wp (sym-cat ?mps -FILL))
  ))
)
