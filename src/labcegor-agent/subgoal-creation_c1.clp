(defrule subgoal-creation-bs-first-run-c1 ; move from start to bsoutput, prepare bs and pick base from output side, go to rs wait side.
  ?trigger_goal <- (goal (id ?goal-id)
                         (class tri-bs-c1firstrun)
                         (params order-id ?order-id ring-color ?ring-color))
  
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot mps-with-side START))
  (order (id ?order-id) (base-color ?wp) (cap-color ?cap))
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )
  (not (goal (class bs-run-c1firstrun)))

  (wp-cap-color (cc ?cc) (cap-color ?cap))
  (domain-fact (name wp-on-shelf) (param-values ?cc ?cs))
  (machine (name ?cs) (type CS) (state IDLE))
  (machine (name ?bs) (type BS) (state IDLE))
  (machine (name ?rs) (type RS) (state IDLE))

  (not (mps-occupied (mps ?cs)))
  (not (mps-occupied (mps ?bs)))
  (not (mps-occupied (mps ?rs)))

  (not (cs-prepared (cs ?cs)))
  =>
  (bind ?bs-side OUTPUT)
  (bind ?rs-side INPUT)
  (assert (goal (id (sym-cat bs-run-c1firstrun- (gensym*)))
                (class bs-run-c1firstrun)
                (parent ?goal-id) (sub-type SIMPLE)
                             (params robot ?robot
                                     current-loc START
                                     bs ?bs
                                     bs-side ?bs-side
                                     rs ?rs
				     cs ?cs
				     cc ?cc
                                     wp ?wp
                                     ring ?ring-color
				     order-id ?order-id
                             )
                            (required-resources ?wp)
  ))
  (retract ?trigger_goal ?robot-at-start)
  ;(modify ?mps-bs (state PROCESSING))
  ;(modify ?mps-rs (state PROCESSING))
  (assert (mps-occupied (mps ?bs))
	  (mps-occupied (mps ?rs))
	  (mps-occupied (mps ?cs))
  )

)

(defrule subgoal-lifecycle-bs-first-run-c1
  (goal (class bs-run-c1firstrun) (params robot ?robot current-loc ?curr-loc bs ?bs bs-side ?bs-side rs ?rs cs ?cs cc ?cc wp ?wp ring ?ring order-id ?order-id) (outcome COMPLETED))
  ?mps-occ-bs <- (mps-occupied (mps ?bs))
  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  =>
  (retract ?mps-occ-bs ?mps-occ-cs)
)


(defrule subgoal-creation-rs-first-run-c1  ; rs wait to rs input, place, rs input to rs output, pick
  ?premise_goal <- (goal (class bs-run-c1firstrun) (params robot ?robot
                                                           current-loc ?curr-loc
                                                           bs          ?bs
                                                           bs-side     ?bs-side
                                                           rs          ?rs
							   cs	       ?cs
							   cc	       ?cc
                                                           wp          ?wp
                                                           ring        ?ring
							   order-id    ?order-id) (outcome COMPLETED))
  ?finish_payment <- (finish_payment (order-id ?order-id) (ring ?ring))
  ?ring-payment-status <- (ring_payment (order-id ?order-id) (ring ?ring))
  (not (goal (class rs-run-c1firstrun)))
  (mps-occupied (mps ?rs))
  =>
  (assert (goal (id (sym-cat rs-run-c1firstrun- (gensym*)))
                (class rs-run-c1firstrun)
                (params robot ?robot rs ?rs wp ?wp ring ?ring order-id ?order-id cs ?cs)))
  (retract ?premise_goal ?finish_payment ?ring-payment-status)
)

(defrule subgoal-lifecycle-rs-first-run-c1
  (goal (class rs-run-c1firstrun) (params robot ?robot rs ?rs wp ?wp ring ?ring order-id ?order-id cs ?cs) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?rs))
  =>
  (retract ?mps-occ)
)


(defrule goal-creation-rs-cs-ds-run-c1
    ; move from rs to cs input, place, and move to cs output, pick, move to ds.
   ?premise_goal <- (goal (class rs-run-c1firstrun)
                           (params robot ?robot
                                   rs ?rs
                                   wp ?wp
                                   ring ?ring-color
				   order-id ?order-id
				   cs ?cs)
                                (outcome COMPLETED))
    
    ?trigger_goal <- (goal (id ?goal-id) (class trirs-cs-c1run) (mode FORMULATED) (params order-id ?order-id))
    (order (id ?order-id) (cap-color ?cap))
    
    ?cs-mps <- (machine (name ?cs) (type CS) (state IDLE)) ; randomly choose one CS to go
    ?ds-mps <- (machine (name ?ds) (type DS) (state IDLE))

    (cs-prepared (cs ?cs) (order-id ?order-id))

    (not (mps-occupied (mps ?cs)))
    (not (mps-occupied (mps ?ds)))
    
    =>
    (bind ?cs-side INPUT)
    (bind ?wp-new (sym-cat ?wp (sym-cat - ?ring-color)))
    (assert (goal (id (sym-cat rs-csds-c1run- (gensym*)))
                (class rs-csds-c1run) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        rs ?rs
                        rs-side OUTPUT
                        cs ?cs
                        cs-side ?cs-side
                        wp ?wp-new
                        cap ?cap
                        ds ?ds
                        ds-side INPUT
                        order-id ?order-id
                )))

    (retract ?trigger_goal ?premise_goal)
    ; (modify ?cs-mps (state PROCESSING))
    ; (modify ?ds-mps (state PROCESSING))

    (assert (mps-occupied (mps ?cs))
	    (mps-occupied (mps ?ds))
    )

)


(defrule update_c1_order
  ?premise_goal <- (goal (class rs-csds-c1run) 
                	(params robot ?robot
                        	rs ?rs
                        	rs-side OUTPUT
                        	cs ?cs
                        	cs-side ?cs-side
                        	wp ?wp-new
                        	cap ?cap
                        	ds ?ds
                        	ds-side INPUT
                        	order-id ?order-id)
			(outcome COMPLETED))
  ?current-order <- (order (id ?order-id) (quantity-requested ?req) (quantity-delivered ?done))
  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  ?mps-occ-ds <- (mps-occupied (mps ?ds))

  ?cs-shield <- (cs-prepared (cs ?cs) (order-id ?order-id))

  =>
  (if (eq ?req ?done)
      then
        (assert (finish-order (order-id ?order-id)))
      else
        (printout t "" crlf)
  )

  (retract ?premise_goal ?mps-occ-cs ?mps-occ-ds ?cs-shield)
)

