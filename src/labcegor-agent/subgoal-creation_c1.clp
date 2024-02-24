(defrule subgoal-creation-bs-first-run-c1
  ?trigger_goal <- (goal (id ?goal-id)
                         (class tri-bs-c1firstrun)
                         (params order-id ?order-id ring-color ?ring-color))
  
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot x START))
  (order (id ?order-id) (base-color ?wp))
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )
  (not (goal (class bs-run-c1firstrun)))
  ?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ?mps-rs <- (machine (name ?rs) (type RS) (state IDLE))
  =>
  (bind ?bs-side INPUT)
  (bind ?rs-side INPUT)
  (assert (goal (id (sym-cat bs-run-c1firstrun- (gensym*)))
                (class bs-run-c1firstrun)
                (parent ?goal-id) (sub-type SIMPLE)
                             (params robot ?robot
                                     current-loc START
                                     bs ?bs
                                     bs-side ?bs-side
                                     rs ?rs
                                     wp ?wp
                                     ring ?ring-color
                             )
                            (required-resources ?wp)
  ))
  (retract ?trigger_goal ?robot-at-start)
  ;(modify ?mps-bs (state PROCESSING))
  ;(modify ?mps-rs (state PROCESSING))
)


(defrule subgoal-creation-rs-first-run-c1  ; rs wait to rs input, place, rs input to rs output, pick
  ?premise_goal <- (goal (class bs-run-c1firstrun) (params robot ?robot
                                                           current-loc ?curr-loc
                                                           bs          ?bs
                                                           bs-side     ?bs-side
                                                           rs          ?rs
                                                           wp          ?wp
                                                           ring        ?ring) (outcome COMPLETED))
  (finish_payment (ring ?ring))
  (not (goal (class rs-run-c1firstrun)))
  =>
  (assert (goal (id (sym-cat rs-run-c1firstrun- (gensym*)))
                (class rs-run-c1firstrun)
                (params robot ?robot rs ?rs wp ?wp ring ?ring)))
  (retract ?premise_goal)
)


(defrule goal-creation-rs-cs-ds-run-c1
    ; move from rs to cs input, place, and move to cs output, pick, move to ds.
    ?trigger_goal <- (goal (id ?goal-id) (class trirs-cs-c1run) (mode FORMULATED) (params order-id ?order-id))
    (order (id ?order-id) (cap-color ?cap))
    ?premise_goal <- (goal (class rs-run-c1firstrun)
                           (params robot ?robot
                                   rs ?rs
                                   wp ?wp
                                   ring ?ring-color)
                                (outcome COMPLETED))

    ?cs-mps <- (machine (name ?cs) (type CS) (state IDLE)) ; randomly choose one CS to go
    ?ds-mps <- (machine (name ?ds) (type DS) (state IDLE))
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
  =>
  (modify ?current-order (quantity-requested (- ?req 1)) (quantity-delivered (+ ?done 1)))
  (assert (wm-fact (key domain fact at args? r ?robot x START)))
  (retract ?premise_goal)
)

