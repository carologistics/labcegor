
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


(deftemplate mps-is-visited
  (slot name (type SYMBOL))
)

(defrule goal-reasoner-create
	(domain-loaded)
	(not (goal))
	(not (goal-already-tried))
	(domain-facts-loaded)
        ?tmp <- (wm-fact (key domain fact mps-location args? loc ?next-machine-location))
        (not (wm-fact (key domain fact visited args? r robot1 loc ?next-machine-location)))
        (not (wm-fact (key domain fact visited args? r robot2 loc ?next-machine-location)))
        (not (wm-fact (key domain fact visited args? r robot3 loc ?next-machine-location)))
	=>
        (retract ?tmp)
        ;(assert (goal (id DEMO-GOAL-SIMPLE) (class DEMO-GOAL-SIMPLE) (params target-pos ?next-machine-location robot robot1)))
        (assert (goal (id DEMO-GOAL-SIMPLE-robot1) (class DEMO-GOAL-SIMPLE-robot1) (params target-pos ?next-machine-location robot robot1)))
        (assert (goal (id DEMO-GOAL-SIMPLE-robot2) (class DEMO-GOAL-SIMPLE-robot2) (params target-pos ?next-machine-location robot robot2)))
        (assert (goal (id DEMO-GOAL-SIMPLE-robot3) (class DEMO-GOAL-SIMPLE-robot3) (params target-pos ?next-machine-location robot robot3)))
        (assert (goal-already-tried))
        (assert (wm-fact (key domain fact visited args? r robot1 loc ?next-machine-location)))
        (assert (wm-fact (key domain fact visited args? r robot2 loc ?next-machine-location)))
        (assert (wm-fact (key domain fact visited args? r robot3 loc ?next-machine-location)))
)


; #  Goal Selection
; We can choose one or more goals for expansion, e.g., calling
; a planner to determine the required steps.
(defrule goal-reasoner-select
	?g <- (goal (id ?goal-id) (mode FORMULATED))
	(not (goal (id DEMO-GOAL) (mode ~FORMULATED)))
	; (not (goal (id DEMO-GOAL-SIMPLE) (mode ~FORMULATED)))
	=>
	(modify ?g (mode SELECTED))
	(assert (goal-meta (goal-id ?goal-id)))
)

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
	?g <- (goal (mode COMMITTED))
	=>
	(modify ?g (mode DISPATCHED))
)


;(defrule goal-reasoner-execution
;	?g <- (goal (mode DISPATCHED) (params target-pos pos-3-3 robots [robot1 robot2 robot3]))
;	=>
;	; execution, how ?
;	(modify ?g (mode FINISHED) (outcome COMPLETED))
;)
	

; #  Goal Monitoring
(defrule goal-reasoner-completed
	?g <- (goal (id ?goal-id) (mode FINISHED) (outcome COMPLETED))

	; ?g <- (goal (id ?goal-id) (mode FINISHED) (params ))

	?gm <- (goal-meta (goal-id ?goal-id))
	=>
	(printout t "Goal '" ?goal-id "' has been completed, cleaning up" crlf)
	(delayed-do-for-all-facts ((?p plan)) (eq ?p:goal-id ?goal-id)
		(delayed-do-for-all-facts ((?a plan-action)) (eq ?a:plan-id ?p:id)
			(retract ?a)
		)
		(retract ?p)
	)
	(retract ?g ?gm)
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
