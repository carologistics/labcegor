
(deftemplate goal-meta
	(slot goal-id (type SYMBOL))
	(slot assigned-to (type SYMBOL)
	                  (allowed-values nil robot1 robot2 robot3 central)
	                  (default nil))
	(slot restricted-to (type SYMBOL)
	                    (allowed-values nil robot1 robot2 robot3 central)
	                    (default nil))
	(slot order-id (type SYMBOL))
	(slot ring-nr (type SYMBOL)
	              (allowed-values nil ONE TWO THREE)
	              (default nil))
	(slot root-for-order (type SYMBOL))
	(slot run-all-ordering (default 1) (type INTEGER))
	(slot category (type SYMBOL)
	               (allowed-values nil PRODUCTION MAINTENANCE PRODUCTION-INSTRUCT MAINTENANCE-INSTRUCT OTHER OTHER-INSTRUCT UNKNOWN)
	               (default nil))
	(slot retries (default 0) (type INTEGER))
)

(defglobal
	?*GOAL-MAX-TRIES* = 2
)

(defrule random_select
  ?temp <- (wm-fact (key all robot) (values $?robot-list))
  =>
  (bind ?list-len (length $?robot-list))
  (bind ?robot (nth$ (random 1 ?list-len) $?robot-list))
  (assert (wm-fact (key robot) (values ?robot))) ;
  (retract ?temp)

)


(defrule goal-reasoner-create
        (not (tmp_haltor)) ; for debug
        (wm-fact (id "/refbox/phase") (value PRODUCTION))
	(domain-loaded)
	(not (goal))
	(domain-facts-loaded)
	(wm-fact (key domain fact mps-location args? loc ?next-machine-location))
	;(wm-fact (key domain fact at args? r ?robot x ?loc))
	?tmp <- (wm-fact (key robot) (values ?robot))
	(not (wm-fact (key domain fact visited args? loc ?next-machine-location)))
	(not (wm-fact (key robot assign) (value ?robot)))
	(not (key domain fact at args? r ?other-robot ?loc ?next-machine-location)) ; if target position is free
	; (not (wm-fact (key domain fact robot-at-loc args? r ?other-robot loc ?next-machine-location))) ; if no other robot in this position
	; ?rl <- (wm-fact (key robot-at-loc args? r ?robot loc ?loc))
	=>
	(assert (goal (id DEMO-GOAL-SIMPLE) (class DEMO-GOAL-SIMPLE) (params target-pos ?next-machine-location robot ?robot)))
	(assert (wm-fact (key domain fact visited args? loc ?next-machine-location)))
	(retract ?tmp)	
)


; #  Goal Selection
(defrule goal-reasoner-select
  ?g <- (goal (id ?goal-id) (mode FORMULATED) (class bs-run-firstrun) (params robot ?robot 
									      bs ?bs
									      bs-side ?bs-side
									      rs ?rs
									      rs-side ?rs-side
									      wp ?wp
    									      ring ?ring))
  =>
  (modify ?g (mode SELECTED))
)



; We can choose one or more goals for expansion, e.g., calling
; a planner to determine the required steps.
;(defrule goal-reasoner-select
;	?g <- (goal (id ?goal-id) (mode FORMULATED) (params target-pos ?target robot ?robot))
;	(not (goal (id DEMO-GOAL) (mode ~FORMULATED)))
;	; (not (goal (id DEMO-GOAL-SIMPLE) (mode ~FORMULATED)))
;	=>
;	(modify ?g (mode SELECTED))
;	(assert (goal-meta (goal-id ?goal-id)))
;    (assert (wm-fact (key robot assign) (value ?robot)))
;    ;(assert (wm-fact (key domain fact robot-at-loc args? r ?robot loc ?target)))
;)

; #  Commit to goal (we "intend" it)
; A goal might actually be expanded into multiple plans, e.g., by
; different planners. This step would allow to commit one out of these
; plans.
;(defrule goal-reasoner-expand
;	?g <- (goal (mode SELECTED))
;	=>
;	(modify ?g (mode EXPANDED))
;)

; (defrule goal-reasoner-expand
; 	?g <- (goal (id VISITALL1) (mode SELECTED))
;         =>
;         (pddl-request-plan VISITALL1 "visited LOC1")
; )

(defrule goal-reasoner-commit
	?g <- (goal (mode EXPANDED))
	=>
	(modify ?g (mode COMMITTED))
)

; #  Dispatch goal (action selection and execution now kick in)
; Trigger execution of a plan. We may commit to multiple plans
; (for different goals), e.g., one per robot, or for multiple
; orders. It is then up to action selection and execution to determine
; what to do when.
(defrule goal-reasoner-dispatch
	; ?g <- (goal (mode COMMITTED) (params target-pos ?zone robot ?robot))
	?g <- (goal (mode COMMITTED) (class bs-run-firstrun))
        ;?rb <- (wm-fact (key robot-is-busy) (value ?robot))
	=>
	(modify ?g (mode DISPATCHED))
        ;(retract ?rb)
        ; (retract (robot-is-busy (value ?robot)))
)


;(defrule goal-reasoner-execution
;	?g <- (goal (mode DISPATCHED) (params target-pos pos-3-3 robots [robot1 robot2 robot3]))
;	=>
;	; execution, how ?
;	(modify ?g (mode FINISHED) (outcome COMPLETED))
;)
	

; #  Goal Monitoring
(defrule goal-reasoner-completed
	?g <- (goal (id ?goal-id) (mode FINISHED) (outcome COMPLETED) (class bs-run-firstrun))
	; ?g <- (goal (id ?goal-id) (mode FINISHED) (outcome COMPLETED) (params target-pos ?target robot ?robot))
	?gm <- (goal-meta (goal-id ?goal-id))
        ?ra <- (wm-fact (key robot assign) (value ?robot))
        =>
	(printout t "Goal '" ?goal-id "' has been completed, cleaning up" crlf)
	(delayed-do-for-all-facts ((?p plan)) (eq ?p:goal-id ?goal-id)
		(delayed-do-for-all-facts ((?a plan-action)) (eq ?a:plan-id ?p:id)
			(retract ?a)
		)
		(retract ?p)
	)
	(retract ?g ?gm ?ra)
    (assert (wm-fact (key all robot) (values robot1 robot2 robot3)))
)

(defrule goal-reasoner-failed
	?g <- (goal (id ?goal-id) (mode FINISHED) (outcome FAILED))
	?gm <- (goal-meta (goal-id ?goal-id) (retries ?num-tries))
	=>
	(printout error "Goal '" ?goal-id "' has failed, cleaning up" crlf)
	(delayed-do-for-all-facts ((?p plan)) (eq ?p:goal-id ?goal-id)
		(delayed-do-for-all-facts ((?a plan-action)) (eq ?a:plan-id ?p:id)
			(retract ?a)
		)
		(retract ?p)
	)
	(bind ?num-tries (+ ?num-tries 1))
	(if (< ?num-tries ?*GOAL-MAX-TRIES*)
	then
		(printout t "Triggering re-expansion" crlf)
		(modify ?g (mode SELECTED))
		(modify ?gm (retries ?num-tries))
	else
		(printout t "Goal failed " ?num-tries " times, aborting" crlf)
		(retract ?g ?gm)
	)
)
