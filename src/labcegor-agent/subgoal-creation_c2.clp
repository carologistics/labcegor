; made by Yuan,Chengzhi, last modified @20240310

; move to BS, take a base from BS and move to RS wait side.
(defrule subgoal-creation-bs-first-run-c2
  ?trigger_goal <- (goal (id ?goal-id) 
			 (class tri-bs-c2firstrun) 
			 (mode FORMULATED) 
			 (params order-id ?order-id ring-color ?ring-color))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot mps-with-side START)) 
  (order (id ?order-id) (base-color ?wp) (ring-colors ?rc1 ?rc2) (cap-color ?cap))
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color)) 
  )
  ?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ?mps-rs <- (machine (name ?rs) (type RS) (state IDLE))
  (not (goal (class bs-run-c2firstrun)))

  ; to avoid deadlock, but reduce efficiency. deadlock: both two robot are not in the middle of expansion, and wait at RS wait side. 
  (finish_payment (order-id ?order-id) (ring ?rc1))
  (finish_payment (order-id ?order-id) (ring ?rc2))
  
  
  (machine (name ?bs) (type BS) (state IDLE))
  (machine (name ?rs) (type RS) (state IDLE))
  
  (not (mps-occupied (mps ?bs)))
  (not (mps-occupied (mps ?rs)))
  (not (finish-order (order-id ?order-id)))

  (not (order-is-expanding (order-id ?order-id)))

  =>
  (bind ?bs-side OUTPUT)
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
				     order-id ?order-id
                             )
                            (required-resources ?wp)
  ))
  (retract ?trigger_goal ?robot-at-start)

  (assert (mps-occupied (mps ?bs))
          (mps-occupied (mps ?rs))
  )
  (assert (order-is-expanding (order-id ?order-id)))
)

(defrule subgoal-lifecycle-bs-first-run
  (goal (class bs-run-c2firstrun) (params robot ?robot
                                     current-loc START
                                     bs ?bs
                                     bs-side ?bs-side
                                     rs ?rs
                                     wp ?wp
                                     ring ?ring-color
				     order-id ?order-id) (outcome COMPLETED))

  ?mps-occ-bs <- (mps-occupied (mps ?bs))
  =>
  (retract ?mps-occ-bs)
)


(defrule subgoal-creation-rs-first-run-c2  
  ; move from rs wait side to input side, place wp on input side, prepare rs, move to output, pick wp at output side. 
  ?premise_goal <- (goal (class bs-run-c2firstrun) (params robot ?robot
                                                           current-loc ?curr-loc
                                                           bs ?bs
                                                           bs-side ?bs-side
                                                           rs ?rs
                                                           wp ?wp
                                                           ring ?ring
							   order-id ?order-id) (outcome COMPLETED))
  
  ?finish_payment <- (finish_payment (order-id ?order-id) (ring ?ring) (index 1))
  ?ring-payment-status <- (ring_payment (order-id ?order-id) (ring ?ring) (index 1))
  (not (goal (class rs-run-c2firstrun)))
  (mps-occupied (mps ?rs))
  =>
  (assert (goal (id (sym-cat rs-run-c2firstrun- (gensym*)))
		(class rs-run-c2firstrun)
		(params robot ?robot rs ?rs wp ?wp ring ?ring order-id ?order-id)))
  (retract ?premise_goal ?finish_payment ?ring-payment-status)
)


(defrule subgoal-lifecycle-rs-first-run-c2
  (goal (class rs-run-c2firstrun) (params robot ?robot rs ?rs wp ?wp ring ?ring order-id ?order-id) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?rs))
  =>
  (retract ?mps-occ)
)



(defrule goal-creation-rs-loop-run-c2
  ?premise_goal <- (goal (id ?premise_goal_id) (class rs-run-c2firstrun)
						(params robot ?robot
							rs ?pre_rs
							wp ?wp
							ring ?pre_ring
							order-id ?order-id) (outcome COMPLETED))
  ?finish_payment <- (finish_payment (order-id ?order-id) (ring ?ring-color) (index 2))
  ?ring-payment-status <- (ring_payment (order-id ?order-id) (ring ?ring-color) (index 2))
  
  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop-c2run) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
   
  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
  )
  
  (order (id ?order-id) (cap-color ?cap))
  (wp-cap-color (cc ?cc) (cap-color ?cap))
  (domain-fact (name wp-on-shelf) (param-values ?cc ?cs))
  (machine (name ?cs) (type CS) (state IDLE))
  
  ?used_rs <- (machine (name ?rs) (type RS) (state IDLE))
  (not (goal (class rs-loop-c2run)))
  
  (not (mps-occupied (mps ?rs)))
  (not (mps-occupied (mps ?cs))) 
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
				      ring ?ring-color
				      order-id ?order-id cs ?cs cc ?cc)))
  (retract ?trigger_goal ?premise_goal ?finish_payment ?ring-payment-status)
  (assert (mps-occupied (mps ?rs)))
  (assert (mps-occupied (mps ?cs)))
)


(defrule subgoal-lifecycle-rs-loop-run-c2
  (goal (class rs-loop-c2run) (params robot ?robot pre_rs ?pre_rs pre_rs_side ?pre_rs_side rs ?rs rs-side ?rs-side wp ?wp ring ?ring order-id ?order-id cs ?cs cc ?cc) (outcome COMPLETED))
  ?mps-occ-rs <- (mps-occupied (mps ?rs))
  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  =>
  (retract ?mps-occ-rs ?mps-occ-cs)
)



(defrule goal-creation-rs-cs-ds-run-c2
    ; move from rs to cs input, place, and move to cs output, pick, move to ds.
    ?premise_goal <- (goal (class rs-loop-c2run)
         		   (params robot ?robot
                		   pre_rs ?pre_rs
            			   pre_rs_side ?pre-rs-side
                     		   rs ?rs
                		   rs-side ?rs-side
                     		   wp ?wp
                   		   ring ?ring-color
				   order-id ?order-id cs ?cs cc ?cc) 
	  			(outcome COMPLETED))

    ?trigger_goal <- (goal (id ?goal-id) (class trirs-cs-c2run) (mode FORMULATED) (params order-id ?order-id))
    (order (id ?order-id) (cap-color ?cap))
    
    ?cs-mps <- (machine (name ?cs) (type CS) (state IDLE))
    ?ds-mps <- (machine (name ?ds) (type DS) (state IDLE))
    
    (cs-prepared (cs ?cs) (order-id ?order-id))
    
    (not (mps-occupied (mps ?cs)))
    (not (mps-occupied (mps ?ds)))
    (not (goal (class rs-csds-c2run))) 
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
    (assert (mps-occupied (mps ?cs))
	    (mps-occupied (mps ?ds)))
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
  ?current-order <- (order (id ?id) (quantity-requested ?req) (quantity-delivered ?done&:(> ?done 0)))
  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  ?mps-occ-ds <- (mps-occupied (mps ?ds))
  
  ?cs-shield <- (cs-prepared (cs ?cs) (order-id ?order-id))

  ?current-order-expanding <- (order-is-expanding (order-id ?order-id))  
  =>
  (if (<= ?req ?done)
      then
        (assert (finish-order (order-id ?id)))
        (printout t "finish one c2 expansion for order id " ?order-id crlf)
      else
        (printout t "" crlf)
  )
  
  (retract ?mps-occ-cs ?mps-occ-ds ?premise_goal ?cs-shield)
  (retract ?current-order-expanding)
)
