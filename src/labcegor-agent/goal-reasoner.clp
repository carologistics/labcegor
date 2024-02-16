
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

;(defrule random_select
;  ?temp <- (wm-fact (key all robot) (values $?robot-list))
;  =>
;  (bind ?list-len (length $?robot-list))
;  (bind ?robot (nth$ (random 1 ?list-len) $?robot-list))
;  (assert (wm-fact (key robot) (values ?robot))) ;
;  (retract ?temp)
;
;)


(defrule goal-reasoner-create
        (not (tmp_haltor)) ; for debug
        (wm-fact (id "/refbox/phase") (value PRODUCTION))
	(domain-loaded)
	(not (goal))
        (debug)
	(domain-facts-loaded)
	(wm-fact (key domain fact mps-location args? loc ?next-machine-location))
	; (wm-fact (key domain fact at args? r ?robot x ?loc))
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

(defrule goal-reasoner-select-bs-rs-firstrun
  ?g <- (goal (id ?goal-id) 
	      (mode FORMULATED) 
	      (class bs-run-c2firstrun|rs-run-c2firstrun|payment-first|payment|rs-loop-c2run|rs-csds-c2run|bs-run-c2firstrun-c0|C0-cs-ds-run|bs-run-c1firstrun|rs-run-c1firstrun|rs-csds-c1run)
	) 
  =>
  (modify ?g (mode SELECTED))
)


(defrule goal-reasoner-commit
	?g <- (goal (mode EXPANDED))
	=>
	(modify ?g (mode COMMITTED))
)

(defrule goal-reasoner-dispatch
	?g <- (goal (mode COMMITTED))
	=>
	(modify ?g (mode DISPATCHED))
)

; #  Goal Monitoring
(defrule goal-reasoner-completed
	?g <- (goal (id ?goal-id) (mode FINISHED) (outcome COMPLETED))
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
