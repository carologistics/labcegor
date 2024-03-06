; attention_only_fire one
(deffunction plan-assert-action (?name $?param-values)
" Assert an action with a unique id."
	(bind ?id-sym (gensym*))
	(bind ?id-str (sub-string 4 (length$ ?id-sym) (str-cat ?id-sym)))
	(assert (plan-action (id (string-to-field ?id-str)) (action-name ?name) (param-values $?param-values) (robot "robot1")))
)

(deffunction plan-assert-sequential (?plan-name ?goal-id ?robot $?action-tuples)
	(bind ?plan-id (sym-cat ?plan-name (gensym*)))
	(assert (plan (id ?plan-id) (goal-id ?goal-id)))
	(bind ?actions (create$))
	; action tuples might contain FALSE in some cases, filter them out
	(foreach ?pa $?action-tuples
		(if ?pa then
			(bind ?actions (append$ ?actions ?pa))
		)
	)
	(foreach ?pa $?actions
		(modify ?pa (id ?pa-index) (plan-id ?plan-id) (goal-id ?goal-id))
	)
)
 
(defrule goal-expander-demo-goal
	?g <- (goal (id ?goal-id) (class move_action) (mode SELECTED) (parent ?parent)
	            (params target-pos ?zone robot ?robot))

	(wm-fact (key domain fact at args? r ?robot x ?curr-loc))
	=>
	(plan-assert-sequential (sym-cat DEMO-GOAL-PLAN- (gensym*)) ?goal-id ?robot
		(plan-assert-action move  ?curr-loc ?zone ?robot)
		;(plan-assert-action wp-put ?robot ?wp ?mps INPUT (get-wp-complexity ?wp))
	)
	(modify ?g (mode EXPANDED))
)


(defrule goal-expander-first-bs-run ; move to BS, take a base from BS and move to RS wait side.
  ?g <- (goal (id ?goal-id) (mode SELECTED) (class bs-run-c3firstrun|bs-run-c2firstrun|bs-run-c1firstrun) 
					    (params robot ?robot
        					    current-loc ?curr-loc
                      				    bs ?bs
                      				    bs-side ?bs-side
                      				    rs ?rs
                      				    wp ?wp
                  				    ring ?ring
						    order-id ?order-id))

  ?used_bs <- (machine (name ?bs) (type BS))
  ?used_rs <- (machine (name ?rs) (type RS))
  =>
  (bind ?from_side None)
  (bind ?rs-wait-side WAIT)
   
  (plan-assert-sequential (sym-cat PLAN-first-bs-rs-run- (gensym*)) ?goal-id ?robot
		(plan-assert-action move ?curr-loc ?from_side ?bs ?bs-side ?robot)
		(plan-assert-action prepare_bs ?bs ?bs-side ?wp)
                (plan-assert-action pick_at_output ?robot (sym-cat ?bs (sym-cat - ?bs-side)) ?bs ?wp)
		(plan-assert-action move ?bs ?bs-side ?rs ?rs-wait-side ?robot)
  )
  (modify ?g (mode EXPANDED))
)


(defrule goal-expander-payment ; from current location to payment mps with side, pick additional base and to rs input
  ?g <- (goal (id ?goal-id) (mode SELECTED) (class payment-first|payment) (params robot ?robot
							                 	  current-loc ?curr-loc  ; start/rs
										  current-side ?curr-side  ; none/slide-side
								    	  	  payment-mps ?mps
								    	  	  payment-side ?mps-side
								    	  	  rs ?rs
								    	  	  ring ?ring
									          order-id ?order-id) (outcome ~COMPLETED))
  ?payment-mps <- (machine (name ?mps) (type CS))
  =>
  (bind ?wp-payment additional_base)
  (bind ?rs-side slide-side)

  (plan-assert-sequential (sym-cat PLAN-payment- (gensym*)) ?goal-id ?robot
			(plan-assert-action move ?curr-loc ?curr-side ?mps ?mps-side ?robot)
			(plan-assert-action prepare_cs ?mps)
			(plan-assert-action pick_at_slide ?robot (sym-cat ?mps (sym-cat - ?mps-side)) ?wp-payment)
			(plan-assert-action move ?mps ?mps-side ?rs ?rs-side ?robot)
			(plan-assert-action place_at_slide ?robot ?wp-payment ?rs)
  )
  (modify ?g (mode EXPANDED))
  (modify ?payment-mps (state IDLE))
)





(defrule goal-expander-first-rs-run   ; move from rs wait side to input side, place wp on input side, prepare rs, move to output, pick wp at output side.
  ?g <- (goal (id ?goal-id) (mode SELECTED) (class rs-run-c3firstrun|rs-run-c2firstrun|rs-run-c1firstrun) (params robot ?robot
									      rs ?rs
									      wp ?wp
									      ring ?ring
									      order-id ?order-id))
  =>
  (bind ?rs-wait-side WAIT)
  (bind ?rs-input-side INPUT)
  (bind ?rs-output-side OUTPUT)
  
  (bind ?wp-added (sym-cat ?wp (sym-cat - ?ring)))
  (plan-assert-sequential (sym-cat PLAN-first-rs-run- (gensym*)) ?goal-id ?robot
			(plan-assert-action move ?rs ?rs-wait-side ?rs ?rs-input-side ?robot)
			(plan-assert-action place ?robot ?wp ?rs)
			(plan-assert-action prepare_rs ?rs ?ring)
			(plan-assert-action move ?rs ?rs-input-side ?rs ?rs-output-side ?robot)
			(plan-assert-action pick_at_output ?robot (sym-cat ?rs (sym-cat - ?rs-output-side)) ?rs ?wp-added)
  )
  (modify ?g (mode EXPANDED))
)


(defrule goal-expander-rs-loop-run
  ?g <- (goal (id ?goal-id) (class rs-loop-c3run-second|rs-loop-c3run-final|rs-loop-c2run) (mode SELECTED) (params robot ?robot
				  					pre_rs ?pre-rs
									pre_rs_side ?pre-rs-side
									rs ?rs
									rs-side ?rs-side
									wp ?wp_now
									ring ?ring
									order-id ?order-id))
  ?used_rs <- (machine (name ?rs) (type RS))
  =>
  (bind ?rs-output-side OUTPUT)
  (bind ?wp-added (sym-cat ?wp_now (sym-cat - ?ring)))
  (plan-assert-sequential (sym-cat PLAN-rs-loop-run- (gensym*)) ?goal-id ?robot
    				(plan-assert-action move ?pre-rs ?pre-rs-side ?rs ?rs-side ?robot)
				(plan-assert-action place ?robot ?wp_now ?rs) ; problem in domain action place
				(plan-assert-action prepare_rs ?rs ?ring)
				(plan-assert-action move ?rs ?rs-side ?rs ?rs-output-side ?robot)
				(plan-assert-action pick_at_output ?robot (sym-cat ?rs (sym-cat - ?rs-output-side)) ?rs ?wp-added)
  )
  (modify ?g (mode EXPANDED))
  ; (modify ?used_rs (state IDLE))
)


(defrule goal-expander-rs-cs-ds-run
  ?g <- (goal (id ?goal-id) (class rs-csds-c3run|rs-csds-c2run|rs-csds-c1run) (mode SELECTED) (params robot ?robot
					  		  	        rs ?rs
								        rs-side ?rs-side
								        cs ?cs
								        cs-side ?cs-side
								        wp ?wp
								        cap ?cap
								        ds ?ds
							 	        ds-side ?ds-side
									order-id ?order-id))

  
  ?used_cs <- (machine (name ?cs) (type CS)) ; 
  ?used_ds <- (machine (name ?ds) (type DS))
  =>
  ; move from rs to cs input, place, and move to cs output, pick, move to ds and place
  (bind ?wp-added (sym-cat ?wp (sym-cat - ?cap)))
  (bind ?cs-output-side OUTPUT)
  
  (plan-assert-sequential (sym-cat PLAN-rs-csds-run- (gensym*)) ?goal-id ?robot
  	    	  (plan-assert-action move ?rs ?rs-side ?cs ?cs-side ?robot)
		  (plan-assert-action place ?robot ?wp ?cs)
		  (plan-assert-action prepare_cs ?cs)
		  (plan-assert-action move ?cs ?cs-side ?cs ?cs-output-side ?robot)
		  (plan-assert-action pick_at_output ?robot (sym-cat ?cs (sym-cat - ?cs-output-side)) ?cs ?wp-added)
		  (plan-assert-action move ?cs ?cs-output-side ?ds ?ds-side ?robot)
		  (plan-assert-action place ?robot ?wp-added ?ds)
		  (plan-assert-action move ?ds ?ds-side START None ?robot)
  )
  ; (assert (wm-fact (key domain fact at args? r ?robot x START)))
  
  (modify ?g (mode EXPANDED))
  ; (modify ?used_cs (state IDLE))
  ; (modify ?used_ds (state IDLE))
)

(defrule goal-expander-bs-cs-run-c0
 ?g <- (goal (id ?goal-id) (mode SELECTED) (class bs-run-c2firstrun-c0) 
					    (params robot ?robot
			        		    current-loc ?curr-loc
                      				    bs ?bs
                      				    bs-side ?bs-side
        					    cs ?cs
                      				    wp ?wp
        				 	    cap ?cap
						    order-id ?order-id))
  
  ?used_bs <- (machine (name ?bs) (type BS))
  ?used_cs <- (machine (name ?cs) (type CS))
  =>
  (bind ?wp-add (sym-cat ?wp ?cap)) 
  (plan-assert-sequential (sym-cat PLAN-first-bs-rs-run- (gensym*)) ?goal-id ?robot
		(plan-assert-action move ?curr-loc None ?bs ?bs-side ?robot)
		(plan-assert-action prepare_bs ?bs ?bs-side ?wp)
    		(plan-assert-action pick_at_output ?robot (sym-cat ?bs (sym-cat - ?bs-side)) ?bs ?wp)
		(plan-assert-action move ?bs ?bs-side ?cs INPUT ?robot)
		(plan-assert-action place ?robot ?wp-add ?cs)
  )
  (modify ?g (mode EXPANDED))
  ;(modify ?used_bs (state IDLE))
)




(defrule goal-expander-cs-ds-run-c0
 ?g <- (goal (id ?goal-id) (mode SELECTED) (class C0-cs-ds-run) 
					    (params robot ?robot
				                    cs ?cs
            	        	        	    ds ?ds
                	        	    	    wp ?wp
						    order-id ?order-id))

  
  (wp_on_output (mps ?cs) (wp ?wp-base-cap))
  ; ?mps-ds <- (machine (name ?ds) (type DS) (state ~IDLE))
  
  =>
   
  (bind ?curr-loc (sym-cat ?cs INPUT))
  (bind ?cs-output (sym-cat ?cs OUTPUT))
  (bind ?ds-side (sym-cat ?ds INPUT))
  
  (plan-assert-sequential (sym-cat PLAN-first-bs-rs-run- (gensym*)) ?goal-id ?robot
		(plan-assert-action move ?cs INPUT ?cs OUTPUT ?robot)
		(plan-assert-action prepare_cs ?cs)
	        (plan-assert-action pick_at_output ?robot (sym-cat ?cs (sym-cat - OUTPUT)) ?cs ?wp-base-cap)
		(plan-assert-action move ?cs OUTPUT ?ds INPUT ?robot)
		(plan-assert-action place ?robot ?wp-base-cap ?ds)
		(plan-assert-action move ?ds ?ds-side START None ?robot)
  )
  ; (modify ?mps-ds (state IDLE))
  ; (assert (wm-fact (key domain fact at args? r ?robot x START)))
  (modify ?g (mode EXPANDED))
)
