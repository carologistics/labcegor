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
; TODO: how to continuously move?
 
(defrule goal-expander-demo-goal
	?g <- (goal (id ?goal-id) (class DEMO-GOAL-SIMPLE) (mode SELECTED) (parent ?parent)
	            (params target-pos ?zone robot ?robot))

	(wm-fact (key domain fact at args? r ?robot x ?curr-loc))
	=>
	(plan-assert-sequential (sym-cat DEMO-GOAL-PLAN- (gensym*)) ?goal-id ?robot
		(plan-assert-action move  ?curr-loc ?zone ?robot)
		;(plan-assert-action wp-put ?robot ?wp ?mps INPUT (get-wp-complexity ?wp))
	)
	(modify ?g (mode EXPANDED))
)
