

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


; move to BS, take a base from BS, move to RS, put wp to RS.
; move to RS output and take wp from RS output.
(defrule goal-creation-get-base-to-rs-first-run
  ?trigger_goal <- (goal (id ?goal-id) (class tribs-rs-c2firstrun) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
  (wm-fact (key domain fact at args? r ?robot x ?loc)) 
  
  (order (id ?order-id) (base-color ?wp))

  ;RS ;rs machine is determined by ring-color in order, and color in ring-assignment 
  ; ring-assignment (machine ?rs) (colors XXX XXX)
  ; ring-assignment (machine ?rs) (colors XXX XXX)

  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color)) 
  )
  ?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ?mps-rs <- (machine (name ?rs) (type RS) (state IDLE))
  =>
  (bind ?bs-side INPUT)
  (bind ?rs-side INPUT)
  (assert (goal (id (sym-cat bs-rs-c2firstrun- (gensym*)))
                (class bs-run-c2firstrun)
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
  (modify ?mps-bs (state PROCESSING))
  (modify ?mps-rs (state PROCESSING))
)


(defrule goal-creation-rs-loop-run
  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop-c2run) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
  ?premise_goal <- (goal (id ?premise_goal_id) (class bs-run-c2firstrun) (outcome COMPLETED) (params robot ?robot bs ?bs bs-side ?bs-side rs ?pre_rs rs-side ?pre_rs-side wp ?wp ring ?pre_ring))
  
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )
  
  ?used_rs <- (machine (name ?rs) (type RS) (state IDLE))
  =>
  (bind ?wp_now (sym-cat ?wp (sym-cat - ?pre_ring)))
  (assert (goal (id (sym-cat rs-loop-c2run- (gensym*)))
                (class rs-loop-c2run)
                (parent ?goal-id) (sub-type SIMPLE)
                              (params robot ?robot
				      pre_rs ?pre_rs
				      pre_rs_side OUTPUT
    				      rs ?rs
                                      rs-side INPUT
                                      wp ?wp_now
				      ring ?ring-color)))
  (retract ?trigger_goal)
  (modify ?used_rs (state PROCESSING))
)



(defrule goal-creation-rs-cs-ds-run
    ; move from rs to cs input, place, and move to cs output, pick, move to ds.
    ?trigger_goal <- (goal (id ?goal-id) (class trirs-cs-c2run) (mode FORMULATED) (params order-id ?order-id))
    (order (id ?order-id) (cap-color ?cap))
    ?premise_goal <- (goal (class rs-loop-c2run)
         		   (params robot ?robot
                		   pre_rs ?pre_rs
            			   pre_rs_side ?pre-rs-side
                     		   rs ?rs
                		   rs-side ?rs-side
                     		   wp ?wp
                   		   ring ?ring-color) 
	  			(outcome COMPLETED))

    ?cs-mps <- (machine (name ?cs) (type CS) (state IDLE)) ; randomly choose one CS to go
    ?ds-mps <- (machine (name ?ds) (type DS) (state IDLE))
    =>
    (bind ?cs-side INPUT)
    (assert (goal (id (sym-cat rs-csds-c2run- (gensym*)))
                (class rs-csds-c2run) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        rs ?rs
			rs-side OUTPUT
			cs ?cs
			cs-side ?cs-side
			wp ?wp
			cap ?cap
			ds ?ds
			ds-side INPUT
                )))
    (modify ?cs-mps (state PROCESSING))
    (modify ?ds-mps (state PROCESSING))
)
