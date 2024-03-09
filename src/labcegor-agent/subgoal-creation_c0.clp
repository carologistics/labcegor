(deftemplate wp_on_output
  (slot mps (type SYMBOL))
  (slot wp  (type SYMBOL))
)


(defrule subgoal-creation-bs-first-runc0  ; move to cs shelf side bs output side, prepare bs, pick base from output, move to cs input side, place base to cs.
  ?trigger_goal <- (goal (id ?goal-id) 
		         (class tri-bs-c0firstrun) 
			 (params order-id ?order-id))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot mps-with-side START)) 
  (order (id ?order-id) (base-color ?wp) (cap-color ?cap))
  (machine (name ?bs) (type BS) (state IDLE))
  
  (wp-cap-color (cc ?cc) (cap-color ?cap))
  (domain-fact (name wp-on-shelf) (param-values ?cc ?cs))
  (machine (name ?cs) (type CS) (state IDLE))
  ;?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ;?mps-cs <- (machine (name ?cs) (type CS) (state IDLE))
  (not (goal (class bs-run-c2firstrun-c0)))
  
  (not (mps-occupied (mps ?bs)))
  (not (mps-occupied (mps ?cs)))

  (not (cs-prepared (cs ?cs)))

  (not (finish-order (order-id ?order-id)))
  
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
				    cc ?cc
                                    wp ?wp
                                    cap ?cap
				    order-id ?order-id)
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
		cc ?cc
                wp ?wp
                cap ?cap
		order-id ?order-id) (outcome COMPLETED))
  ?mps-occ <- (mps-occupied (mps ?bs))
  =>
  (retract ?mps-occ)
)

(defrule subgoal-creation-cs-dsc0
  ?premise_goal <- (goal (class bs-run-c2firstrun-c0)
                            (params robot ?robot
	                        current-loc START
                   	        bs ?bs
				bs-side ?bs-side
                        	cs ?cs
				cc ?cc
                              	wp ?wp
                              	cap ?cap
				order-id ?order-id)
			    (outcome COMPLETED)
                   )
  ?trigger_goal <- (goal (id ?goal-id) 
			 (class tri-cs-c0run)
			 (params order-id ?order-id))

  ;?mps-cs <- (machine (name ?cs) (type CS) (state ~IDLE))
  ;?mps-ds <- (machine (name ?ds) (type DS) (state IDLE))
  (machine (name ?ds) (type DS) (state IDLE))
  (not (goal (class C0-cs-ds-run)))
  (mps-occupied (mps ?cs))
  (not (mps-occupied (mps ?ds))) 
  =>

  (bind ?cs-side OUTPUT)
  (bind ?ds-side INPUT)
  (bind ?wp-base-cap (sym-cat ?wp (sym-cat - ?cap)))

  (assert (goal (id (sym-cat C0-cd-ds-run- (gensym*)))
                (class C0-cs-ds-run)
                (parent ?goal-id) (sub-type SIMPLE)
                            (params robot ?robot
				cs ?cs
                                ds ?ds
                                wp ?wp-base-cap
				order-id ?order-id
				cap-color ?cap)
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
  ?premise_goal <- (goal (class C0-cs-ds-run) (params robot ?robot cs ?cs ds ?ds wp ?wp order-id ?id cap-color ?cap) (outcome COMPLETED))
  ?current-order <- (order (id ?id) (quantity-requested ?req) (quantity-delivered ?done&:(> ?done 0)))
  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  ?mps-occ-ds <- (mps-occupied (mps ?ds))
  
  ?cs-shield <- (cs-prepared (cs ?cs) (order-id ?order-id))
  
  =>
  ; (modify ?current-order (quantity-requested (- ?req 1)) (quantity-delivered (+ ?done 1)))
  ; (assert (wm-fact (key domain fact at args? r ?robot x START)))
  
  ; (bind ?delivered-wp (+ ?done 1))
  (if (eq ?req ?done)
      then
        (assert (finish-order (order-id ?id)))
	(printout t "finish one c0 expansion for order id " ?id crlf)
      else
        (printout t "" crlf)
  )
  
  (retract ?premise_goal ?mps-occ-cs ?mps-occ-ds ?cs-shield)
)

