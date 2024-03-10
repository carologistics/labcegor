; made by Yuan,Chengzhi, last modified @20240310
(deftemplate c0-order-expanded
  (slot order-id (type INTEGER))
)

(defrule subgoal-creation-c0run
  ?trigger_goal <- (goal (id ?goal-id) 
		         (class tri-c0run) 
			 (params order-id ?order-id))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot mps-with-side START)) 
  (order (id ?order-id) (base-color ?wp) (cap-color ?cap))
  (machine (name ?bs) (type BS) (state IDLE))
  
  (wp-cap-color (cc ?cc) (cap-color ?cap))
  (domain-fact (name wp-on-shelf) (param-values ?cc ?cs))
  (machine (name ?cs) (type CS) (state IDLE))
  (not (goal (class c0-run)))
  
  (machine (name ?ds) (type DS) (state IDLE))

  (not (mps-occupied (mps ?ds)))
  (not (mps-occupied (mps ?bs)))
  (not (mps-occupied (mps ?cs)))
  (not (cs-prepared (cs ?cs)))

  (not (finish-order (order-id ?order-id)))

  ; to avoid repeat expanding of a same order
  (not (order-is-expanding (order-id ?order-id)))

  =>
  (bind ?bs-side OUTPUT)
  
  (assert (goal (id (sym-cat c0-run- (gensym*)))
                (class c0-run)
                (parent ?goal-id) (sub-type SIMPLE)
                            (params robot ?robot
	                            current-loc START
                                    bs ?bs
                                    bs-side ?bs-side		
                       	      	    cs ?cs
				    cc ?cc
				    ds ?ds
                                    wp ?wp
                                    cap ?cap
				    order-id ?order-id)
                            )
                            (required-resources ?wp)
  )
  (assert (mps-occupied (mps ?bs))
	  (mps-occupied (mps ?cs))
	  (mps-occupied (mps ?ds))
  )
  (assert (order-is-expanding (order-id ?order-id)))
  (retract ?trigger_goal ?robot-at-start)
)


(defrule update_c0_order
  ?premise_goal <- (goal (class c0-run)
			 (params robot ?robot
                                 current-loc START
                                 bs ?bs
                                 bs-side ?bs-side
                                 cs ?cs
                                 cc ?cc
                                 ds ?ds
                                 wp ?wp
                                 cap ?cap
                                 order-id ?order-id) (outcome COMPLETED))
  
  ?current-order <- (order (id ?id) (quantity-requested ?req) (quantity-delivered ?done&:(> ?done 0)))
  ?mps-occ-bs <- (mps-occupied (mps ?bs))
  ?mps-occ-cs <- (mps-occupied (mps ?cs))
  ?mps-occ-ds <- (mps-occupied (mps ?ds))
  
  ?cs-shield <- (cs-prepared (cs ?cs) (order-id ?order-id))

  ?current-expanding-status <- (order-is-expanding (order-id ?order-id)) 
  =>
  (if (eq ?req ?done)
      then
        (assert (finish-order (order-id ?id)))
	(printout t "finish one c0 expansion for order id " ?id crlf)
      else
        (printout t "" crlf)
  )
  (retract ?premise_goal ?mps-occ-bs ?mps-occ-cs ?mps-occ-ds ?cs-shield)
  (retract ?current-expanding-status)
)

