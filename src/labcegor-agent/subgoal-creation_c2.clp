(deftemplate ring_payment
  (slot ring (type SYMBOL))
  (slot ring_collect (type INTEGER))
)

(deftemplate finish_payment
  (slot ring (type SYMBOL))
)


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
  (modify ?mps-bs (state PROCESSING))
  (modify ?mps-rs (state PROCESSING))
)

(defrule subgoal-creation-trigger-payment-first
  ?trigger-goal <- (goal (id ?goal-id) (class tri-payment) (mode FORMULATED) (params ring ?ring))
  ?ring-spec <- (ring-spec (color ?ring) (cost ?cost))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot x START))
  
  (or (ring-assignment (machine ?rs) (colors ?ring ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring))
  )
  
  ?payment-mps <- (machine (name ?mps) (type CS) (state IDLE))
  =>
  ; (bind ?robot robot1)
  (if (> ?cost 0)
    then 
      (assert (goal (id (sym-cat payment-first- (gensym*)))
         		(class payment-first)
	        	(params robot ?robot
				current-loc START
	  	        	payment-mps ?mps
			        payment-side INPUT
			        rs ?rs
				ring ?ring)))
      
      (modify ?payment-mps (state PROCESSING))
      (bind ?payment-now 1)
      ; (modify ?ring-spec (cost ?new-cost))
      (assert (ring_payment (ring ?ring) (ring_collect ?payment-now)))
      (retract ?trigger-goal)
      (retract ?robot-at-start)
    else
      ; (assert (finish_payment (ring ?ring)))
      (assert (ring_payment (ring ?ring) (ring_collect 0)))
      (assert (finish_payment (ring ?ring)))
      (retract ?trigger-goal)
  )
)


(defrule subgoal-creation-trigger-loop-payment
  ?premise_goal <- (goal (class payment-first) (params robot ?robot 
						current-loc ?curr-loc
					      	payment-mps ?prev-payment-mps
				      		payment-side ?prev-payment-side 
				      		rs ?rs 
				      		ring ?ring) (outcome COMPLETED))
  ?ring-spec <- (ring-spec (color ?ring) (cost ?cost))
  ?rp <- (ring_payment (ring ?ring) (ring_collect ?now_payment))
  ?payment-mps <- (machine (name ?mps) (type CS) (state IDLE))
  =>
  (bind ?current-loc (sym-cat ?rs INPUT))
  (if (> ?cost ?now_payment)
    then
      (assert (goal (id (sym-cat payment-loop- (gensym*)))
		    (class payment)
		    (params robot ?robot
			    current-loc ?current-loc
		            payment-mps ?mps
			    payment-side INPUT
			    rs ?rs
			    ring ?ring)))
      (modify ?payment-mps (state PROCESSING))
      ; (bind ?new-collect 1)
      (modify ?rp (ring_collect (+ ?now_payment 1)))
      (retract ?premise_goal)
    else
      (assert (finish_payment (ring ?ring)))
  )
)


(defrule subgoal-creation-rs-first-run  ; rs wait to rs input, place, rs input to rs output, pick 
  ; (goal (class payment) (params robot ?robot current-loc ?current-loc payment-mps ?mps payment-side ?mps-side rs ?rs ring ?ring) (outcome COMPLETED))
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


(defrule goal-creation-rs-loop-run
  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop-c2run) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
  ?premise_goal <- (goal (id ?premise_goal_id) (class bs-run-c2firstrun) (outcome COMPLETED) (params robot ?robot current-loc ?prev_current_loc bs ?bs bs-side ?bs-side rs ?pre_rs wp ?wp ring ?pre_ring))

  ; (ring-spec (color ?ring-color) (cost 0))
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
			order-id ?order-id
                )))

    (retract ?trigger_goal ?premise_goal)
    (modify ?cs-mps (state PROCESSING))
    (modify ?ds-mps (state PROCESSING))
)
