
(defrule subgoal-creation-bs-first-run
  ?trigger_goal <- (goal (id ?goal-id) 
			 (class tri-bs-c0firstrun) 
			 (mode FORMULATED) 
			 (params order-id ?order-id))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot x START)) 
  (order (id ?order-id) (base-color ?wp) (cap-color ?cap))
  )
  ?mps-bs <- (machine (name ?bs) (type BS) (state IDLE))
  ?mps-cs <- (machine (name ?cs) (type CS) (state IDLE))
  =>
  (bind ?bs-side INPUT)
  (bind ?rs-side INPUT)
  (assert (goal (id (sym-cat C0-bs-cs-run- (gensym*)))
                (class bs-run-c2firstrun)
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
  ))
  (retract ?trigger_goal ?robot-at-start)
  (modify ?mps-bs (state PROCESSING))
  (modify ?mps-rs (state PROCESSING))
)

(defrule subgoal-creation-cs-ds
  ?trigger_goal <- (goal (id ?goal-id) 
			 (class tri-bs-cs) bs-first-run
			 (mode FORMULATED) 
			 (params order-id ?order-id))

  (goal (class bs-run-c2firstrun) (outcome COMPLETED)
                            (params robot ?robot
				            current-loc START
                            bs ?bs
                            bs-side ?bs-side
							cs ?cs
                            wp ?wp
                            cap ?cap)
                            )


  ?mps-cs <- (machine (name ?cs) (type CS) (state ~IDLE))
  ?mps-ds <- (machine (name ?ds) (type DS) (state IDLE))

  =>

  (bind ?cs-side OUTPUT)
  (bind ?ds-side INPUT)

  (assert (goal (id (sym-cat C0-cd-ds-run- (gensym*)))
                (class C0-cs-ds-run)
                (parent ?goal-id) (sub-type SIMPLE)
                            (params robot ?robot
				                    cs ?cs
                                    ds ?ds
                                    wp ?wp-base-cap)
                            )
  ))
  (retract ?trigger_goal)

  (modify ?mps-ds (state PROCESSING))
  (modify ?mps-cs (state IDLE))
)

