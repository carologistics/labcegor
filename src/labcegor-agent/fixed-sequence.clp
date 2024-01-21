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


(defrule goal-expander-first-bs-rs-run
  ?g <- (goal (id ?goal-id) (mode SELECTED) (class bs-run-c2firstrun) (params robot ?robot
                                                                              bs ?bs
                                                                              bs-side ?bs-side
                                                                              rs ?rs
                                                                              rs-side ?rs-side
                                                                              wp ?wp
									      ring ?ring))
  (wm-fact (key domain fact at args? r ?robot x ?curr-loc))
  ?used_bs <- (machine (name ?bs) (type BS))
  ?used_rs <- (machine (name ?rs) (type RS))
  =>
  (bind ?zone-bs-side (sym-cat ?bs ?bs-side))
  (bind ?zone-rs-side (sym-cat ?rs INPUT))
  (bind ?zone-rs-side2 (sym-cat ?rs OUTPUT))
  (bind ?wp-added (sym-cat ?wp (sym-cat - ?ring)))
  (plan-assert-sequential (sym-cat PLAN-first-bs-rs-run- (gensym*)) ?goal-id ?robot
		(plan-assert-action move ?curr-loc ?zone-bs-side ?robot)
                (plan-assert-action pick ?robot ?wp)
                (plan-assert-action move ?zone-bs-side ?zone-rs-side ?robot)
                ; (plan-assert-action place ?robot ?wp ?zone-rs-side) ; problem in domain action place
                (plan-assert-action move ?zone-rs-side ?zone-rs-side2 ?robot)
  		(plan-assert-action pick ?robot ?wp-added)
  )
  (modify ?g (mode EXPANDED))
  (modify ?used_bs (state IDLE))
  (modify ?used_rs (state IDLE))
)


(defrule goal-expander-rs-loop-run
  ?g <- (goal (id ?goal-id) (class rs-loop-c2run) (mode SELECTED) (params robot ?robot
									pre_rs ?pre_rs
									pre_rs_side ?pre_rs_side
									rs ?rs
									rs-side ?rs-side
									wp ?wp_now
									ring ?ring))
  ?used_rs <- (machine (name ?rs) (type RS))
  =>
  (bind ?old-rs-pos (sym-cat ?pre_rs ?pre_rs_side))
  (bind ?new-rs-pos (sym-cat ?rs ?rs-side))
  (bind ?wp-added (sym-cat ?wp_now (sym-cat - ?ring)))
  (plan-assert-sequential (sym-cat PLAN-rs-loop-run- (gensym*)) ?goal-id ?robot
    				(plan-assert-action move ?old-rs-pos ?new-rs-pos ?robot)
				; (plan-assert-action place ?robot ?wp-now) ; problem in domain action place
				(plan-assert-action move ?new-rs-pos (sym-cat ?rs OUTPUT) ?robot)
				(plan-assert-action pick ?robot ?wp-added)
  )
  (modify ?g (mode EXPANDED))
  (modify ?used_rs (state IDLE))
)


(defrule goal-expander-rs-cs-ds-run
  ?g <- (goal (id ?goal-id) (class rs-csds-c2run) (mode SELECTED) (params robot ?robot
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
  (bind ?curr-loc (sym-cat ?rs ?rs-side))
  (bind ?loc-cs-side  (sym-cat ?cs ?cs-side))
  (bind ?wp-added (sym-cat ?wp x?cap))
  (bind ?loc-ds-side (sym-cat ?ds ?ds-side))
  
  (plan-assert-sequential (sym-cat PLAN-rs-csds-run- (gensym*)) ?goal-id ?robot
  	    	  (plan-assert-action move ?curr-loc ?loc-cs-side ?robot)
		  ; (plan-assert-action place ?robot ?wp ?loc-cs-side) ; problem with domain action
		  (plan-assert-action move ?loc-cs-side (sym-cat ?cs OUTPUT) ?robot)
		  (plan-assert-action pick ?robot ?wp-added)
		  (plan-assert-action move (sym-cat ?cs OUTPUT) (sym-cat ?ds ?ds-side) ?robot)
		  ; (plan-assert-action place ?robot ?wp-added ?loc-ds-side)  ; problem with domain action
  )
  (modify ?g (mode EXPANDED))
  (modify ?used_cs (state IDLE))
  (modify ?used_ds (state IDLE))
)

(defrule goal-expander-CLEAR-MPS ; payment
  ?g <- (goal (id ?goal-id) (class CLEAR-MPS))
  =>
  ; robot picks up the wp from CS output side, move to RS, and put in slide(input) RS

)

