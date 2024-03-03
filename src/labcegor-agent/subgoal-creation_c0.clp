(deftemplate wp_on_output
  (slot mps (type SYMBOL))
  (slot wp  (type SYMBOL))
)


(defrule subgoal-creation-bs-first-runc0  ; move to bs output side, prepare bs, pick base from output, move to cs input side, place base to cs.
  ?trigger_goal <- (goal (id ?goal-id) 
		         (class tri-bs-c0firstrun) 
			 (params order-id ?order-id))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot mps-with-side START)) 
  (order (id ?order-id) (base-color ?wp) (cap-color ?cap))
  (machine (name ?bs) (type BS) (state IDLE))
  (machine (name ?cs) (type CS) (state IDLE))
  ;?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ;?mps-cs <- (machine (name ?cs) (type CS) (state IDLE))
  (not (goal (class bs-run-c2firstrun-c0)))

  (not (mps-occupied (mps ?bs)))
  (not (mps-occupied (mps ?cs)))
  =>
  ;(modify ?mps-bs (state PROCESSING))
  ;(modify ?mps-cs (state PROCESSING)) 
  (bind ?bs-side OUTPUT)
  
  (assert (goal (id (sym-cat C0-bs-cs-run- (gensym*)))
                (class bs-run-c2firstrun-c0)
                (parent ?goal-id) (sub-type SIMPLE)
                            (params robot ?robot
	                            current-loc START
                                    bs ?bs
                                    bs-side ?bs-side		
                       	      	    cs ?cs
                                    wp ?wp
                                    cap ?cap)
                            )
                            (required-resources ?wp)
  )
  (assert (mps-occupied (mps ?bs))
	  (mps-occupied (mps ?cs)))
  
  (retract ?trigger_goal ?robot-at-start)
)

(defrule subgoal-lifecycle-bs-first-runc0
  (goal (class bs-run-c2firstrun-c0)
        (params robot ?robot
                current-loc START
                bs ?bs
                bs-side ?bs-side
                cs ?cs
                wp ?wp
                cap ?cap) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?bs))
  =>
  (retract ?mps-occ)
)

(defrule subgoal-creation-cs-dsc0
  ?trigger_goal <- (goal (id ?goal-id) 
			 (class tri-cs-c0run)
			 (params order-id ?order-id))

  ?premise_goal <- (goal (class bs-run-c2firstrun-c0)
                            (params robot ?robot
	                        current-loc START
                   	        bs ?bs
				bs-side ?bs-side
                        	cs ?cs
                              	wp ?wp
                              	cap ?cap)
			    (outcome COMPLETED)
                   )
  ;?mps-cs <- (machine (name ?cs) (type CS) (state ~IDLE))
  ;?mps-ds <- (machine (name ?ds) (type DS) (state IDLE))
  (machine (name ?ds) (type DS) (state IDLE))
  (not (goal (class C0-cs-ds-run)))
  (mps-occupied (mps ?cs))
  (not (mps-occupied (mps ?ds))) 
  =>

  (bind ?cs-side OUTPUT)
  (bind ?ds-side INPUT)
  (bind ?wp-base-cap (sym-cat ?wp ?cap))

  (assert (goal (id (sym-cat C0-cd-ds-run- (gensym*)))
                (class C0-cs-ds-run)
                (parent ?goal-id) (sub-type SIMPLE)
                            (params robot ?robot
				cs ?cs
                                ds ?ds
                                wp ?wp-base-cap
				order-id ?order-id)
                            )
  )

  ; hard_code
  (assert (wp_on_output (mps ?cs) (wp ?wp-base-cap)))
  
  (assert (mps-occupied (mps ?ds)))

  (retract ?trigger_goal ?premise_goal)
  ;(modify ?mps-ds (state PROCESSING))
  ;(modify ?mps-cs (state IDLE))
)


(defrule update_c0_order
  ?premise_goal <- (goal (class C0-cs-ds-run) (params robot ?robot cs ?cs ds ?ds wp ?wp order-id ?id) (outcome COMPLETED))
  ?current-order <- (order (id ?id) (quantity-requested ?req) (quantity-delivered ?done))

  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  ?mps-occ-ds <- (mps-occupied (mps ?ds))
  =>
  (modify ?current-order (quantity-requested (- ?req 1)) (quantity-delivered (+ ?done 1)))
  ; (assert (wm-fact (key domain fact at args? r ?robot x START)))
  (retract ?premise_goal ?mps-occ-cs ?mps-occ-ds)
)

