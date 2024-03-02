; move to BS, take a base from BS and move to RS wait side.
(defrule subgoal-creation-bs-first-run
  ?trigger_goal <- (goal (id ?goal-id) 
			 (class tri-bs-c2firstrun) 
			 (mode FORMULATED) 
			 (params order-id ?order-id ring-color ?ring-color))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot x START)) 
  (order (id ?order-id) (base-color ?wp))
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color)) 
  )
  ?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ?mps-rs <- (machine (name ?rs) (type RS) (state IDLE))
  (not (goal (class bs-run-c2firstrun)))
  =>
  (bind ?bs-side INPUT)
  (bind ?rs-side INPUT)
  (assert (goal (id (sym-cat bs-run-c2firstrun- (gensym*)))
                (class bs-run-c2firstrun)
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
)

(defrule subgoal-creation-rs-first-run-c2  ; rs wait to rs input, place, rs input to rs output, pick 
  ?premise_goal <- (goal (class bs-run-c2firstrun) (params robot ?robot
                                                           current-loc ?curr-loc
                                                           bs ?bs
                                                           bs-side ?bs-side
                                                           rs ?rs
                                                           wp ?wp
                                                           ring ?ring) (outcome COMPLETED))

  (finish_payment (ring ?ring))
  (not (goal (class rs-run-c2firstrun)))
  =>
  (assert (goal (id (sym-cat rs-run-c2firstrun- (gensym*)))
		(class rs-run-c2firstrun)
		(params robot ?robot rs ?rs wp ?wp ring ?ring)))

)


(defrule goal-creation-rs-loop-run-c2
  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop-c2run) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
  ?premise_goal <- (goal (id ?premise_goal_id) (class rs-run-c2firstrun)
						(params robot ?robot
							rs ?pre_rs
							wp ?wp
							ring ?pre_ring) (outcome COMPLETED))
  (finish_payment (ring ?ring-color))
  
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )
  
  ?used_rs <- (machine (name ?rs) (type RS) (state IDLE))
  (not (goal (class rs-loop-c2run)))
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
  ; (modify ?used_rs (state PROCESSING))
)



(defrule goal-creation-rs-cs-ds-run-c2
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
    (bind ?wp_with_2ring (sym-cat ?wp (sym-cat - ?ring-color)))
    (bind ?cs-side INPUT)
    (assert (goal (id (sym-cat rs-csds-c2run- (gensym*)))
                (class rs-csds-c2run) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        rs ?rs
			rs-side OUTPUT
			cs ?cs
			cs-side ?cs-side
			wp ?wp_with_2ring
			cap ?cap
			ds ?ds
			ds-side INPUT
			order-id ?order-id
                )))

    (retract ?trigger_goal ?premise_goal)
    ; (modify ?cs-mps (state PROCESSING))
    ; (modify ?ds-mps (state PROCESSING))
)


(defrule update_c2_order
  ?premise_goal <- (goal (class rs-csds-c2run) 
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
  =>
  (modify ?current-order (quantity-requested (- ?req 1)) (quantity-delivered (+ ?done 1)))
  ; (assert (wm-fact (key domain fact at args? r ?robot x START)))
  (retract ?premise_goal)
)
