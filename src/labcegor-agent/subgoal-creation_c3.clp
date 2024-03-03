; move to BS, take a base from BS and move to RS wait side.
(defrule subgoal-creation-bs-first-run-c3
  ?trigger_goal <- (goal (id ?goal-id) 
			 (class tri-bs-c3firstrun) 
			 (mode FORMULATED) 
			 (params order-id ?order-id ring-color ?ring-color))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot mps-with-side START)) 
  (order (id ?order-id) (base-color ?wp))
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color)) 
  )
  ?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ?mps-rs <- (machine (name ?rs) (type RS) (state IDLE))
  (not (goal (class bs-run-c3firstrun)))
  
  (not (mps-occupied (mps ?bs)))
  (not (mps-occupied (mps ?rs)))

  =>
  (bind ?bs-side OUTPUT)
  (bind ?rs-side INPUT)
  (assert (goal (id (sym-cat bs-run-c3firstrun- (gensym*)))
                (class bs-run-c3firstrun)
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
  ; (modify ?mps-bs (state PROCESSING))
  ; (modify ?mps-rs (state PROCESSING))
  (assert (mps-occupied (mps ?bs))
          (mps-occupied (mps ?rs))
  )
)


(defrule subgoal-lifecycle-bs-first-run-c3
  (goal (class bs-run-c3firstrun) (params robot ?robot
                                     current-loc ?current-location
                                     bs ?bs
                                     bs-side ?bs-side
                                     rs ?rs
                                     wp ?wp
                                     ring ?ring-color) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?bs))
  =>
  (retract ?mps-occ)
)


(defrule subgoal-creation-rs-first-run-c3  ; rs wait to rs input, place, prepare rs, move from rs input to rs output, pick 
  ?premise_goal <- (goal (class bs-run-c3firstrun) (params robot ?robot
                                                           current-loc ?curr-loc
                                                           bs ?bs
                                                           bs-side ?bs-side
                                                           rs ?rs
                                                           wp ?wp
                                                           ring ?ring) (outcome COMPLETED))
  (finish_payment (ring ?ring))
  (not (goal (class rs-run-c3firstrun)))
  (mps-occupied (mps ?rs))
  =>
  (assert (goal (id (sym-cat rs-run-c3firstrun- (gensym*)))
		(class rs-run-c3firstrun)
		(params robot ?robot rs ?rs wp ?wp ring ?ring)))
  ; (retract ?premise_goal)
)


(defrule subgoal-lifecycle-rs-first-run-c3
  (goal (class rs-run-c3firstrun) (params robot ?robot rs ?rs wp ?wp ring ?ring) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?rs))
  =>
  (retract ?mps-occ)
)


(defrule goal-creation-rs-loop-run1-c3
  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop1-c3run) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
  ?premise_goal <- (goal (id ?premise_goal_id) (class rs-run-c3firstrun) (outcome COMPLETED) 
			 (params robot ?robot
				 rs ?prev_rs 
				 wp ?prev_wp
				 ring ?prev_ring))

  (finish_payment (ring ?ring-color))
  
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )
  
  ?used_rs <- (machine (name ?rs) (type RS) (state IDLE))
  (not (goal (class rs-loop-c3run-second)))
  (not (mps-occupied (mps ?rs)))
  =>
  (bind ?wp_now (sym-cat ?prev_wp (sym-cat - ?prev_ring)))
  (assert (goal (id (sym-cat rs-loop-c3run- (gensym*)))
                (class rs-loop-c3run-second)
                (parent ?goal-id) (sub-type SIMPLE)
                              (params robot ?robot
				      pre_rs ?prev_rs
				      pre_rs_side OUTPUT
    				      rs ?rs
                                      rs-side INPUT
                                      wp ?wp_now
				      ring ?ring-color)))
  (retract ?trigger_goal)
  ; (retract ?trigger_goal ?premise_goal)
  ; (modify ?used_rs (state PROCESSING))
  (assert (mps-occupied (mps ?rs)))
)

(defrule subgoal-lifecycle-rs-loop-run1-c3
  (goal (class rs-loop-c3run-second) (params robot ?robot pre_rs ?pre_rs pre_rs_side ?pre_rs_side rs ?rs rs-side ?rs-side wp ?wp ring ?ring) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?rs))
  =>
  (retract ?mps-occ)
)


(defrule goal-creation-rs-loop-run2-c3
  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop2-c3run) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
  ?premise_goal <- (goal (id ?premise_goal_id) (class rs-loop-c3run-second) (outcome COMPLETED)
			 (params robot ?robot
				 pre_rs ?first_rs
				 pre_rs_side ?first_rs_side
				 rs ?second_rs
				 rs-side ?second_rs_side
				 wp ?wp
				 ring ?prev_ring))

  (finish_payment (ring ?ring-color))
  
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )

  ?used_rs <- (machine (name ?rs) (type RS) (state IDLE))
  (not (goal (class rs-loop-c3run-final)))
  
  (not (mps-occupied (mps ?rs)))
  
  
  =>
  (bind ?wp_now (sym-cat ?wp (sym-cat - ?prev_ring)))
  (assert (goal (id (sym-cat rs-loop-c3run- (gensym*)))
                (class rs-loop-c3run-final)  ; final here used to indicate the next action sequence
                (parent ?goal-id) (sub-type SIMPLE)
                              (params robot ?robot
                                      pre_rs ?second_rs
                                      pre_rs_side OUTPUT
                                      rs ?rs
                                      rs-side INPUT
                                      wp ?wp_now
                                      ring ?ring-color)))
  (retract ?trigger_goal)
  ; (retract ?trigger_goal ?premise_goal)
  ; (modify ?used_rs (state PROCESSING))
  (assert (mps-occupied (mps ?rs)))
)

(defrule subgoal-lifecycle-rs-loop-run2-c3
  (goal (class rs-loop-c3run-final) (params robot ?robot pre_rs ?pre_rs pre_rs_side ?pre_rs_side rs ?rs rs-side ?rs-side wp ?wp ring ?ring) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?rs))
  =>
  (retract ?mps-occ)
)


(defrule goal-creation-rs-cs-ds-run-c3
    ; move from rs to cs input, place, and move to cs output, pick, move to ds.
    ?trigger_goal <- (goal (id ?goal-id) (class trirs-cs-c3run) (mode FORMULATED) (params order-id ?order-id))
    (order (id ?order-id) (cap-color ?cap))
    ?premise_goal <- (goal (class rs-loop-c3run-final)
         		   (params robot ?robot
                		   pre_rs ?pre_rs
            			   pre_rs_side ?pre-rs-side
                     		   rs ?rs
                		   rs-side ?rs-side
                     		   wp ?wp-old
                   		   ring ?ring-color) 
	  			(outcome COMPLETED))

    ?cs-mps <- (machine (name ?cs) (type CS) (state IDLE)) ; randomly choose one CS to go
    ?ds-mps <- (machine (name ?ds) (type DS) (state IDLE))

    (not (mps-occupied (mps ?cs)))
    (not (mps-occupied (mps ?ds)))
    (not (goal (class rs-csds-c3run)))

    =>
    (bind ?cs-side INPUT)
    (bind ?wp (sym-cat ?wp-old (sym-cat - ?ring-color)))
    (assert (goal (id (sym-cat rs-csds-c3run- (gensym*)))
                (class rs-csds-c3run) (sub-type SIMPLE)
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
			order-id ?order-id
                )))

    (retract ?trigger_goal)
    ; (retract ?trigger_goal ?premise_goal)
    ; (modify ?cs-mps (state PROCESSING))
    ; (modify ?ds-mps (state PROCESSING))
    (assert (mps-occupied (mps ?cs))
            (mps-occupied (mps ?ds)))
)


(defrule update_c3_order
  ?premise_goal <- (goal (class rs-csds-c3run) 
			 (params robot ?robot
				 rs ?rs
				 rs-side ?rs-side
				 cs ?cs
				 cs-side ?cs-side
				 wp ?wp
				 cap ?cap
				 ds ?ds
				 ds-side ?ds-side
				 order-id ?id) (outcome COMPLETED))
  ?current-order <- (order (id ?id) (quantity-requested ?req) (quantity-delivered ?done))
  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  ?mps-occ-ds <- (mps-occupied (mps ?ds))
  =>
  (modify ?current-order (quantity-requested (- ?req 1)) (quantity-delivered (+ ?done 1)))
  ; (assert (wm-fact (key domain fact at args? r ?robot x START)))
  ; (retract ?premise_goal)
  (retract ?mps-occ-cs ?mps-occ-ds)
)
