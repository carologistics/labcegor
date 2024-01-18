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
	?g <- (goal (id ?goal-id) (class ?class) (mode SELECTED) (parent ?parent)
	            (params target-pos ?zone robot ?robot))

	(wm-fact (key domain fact at args? r ?robot x ?curr-loc))
	=>
	(plan-assert-sequential (sym-cat DEMO-GOAL-PLAN- (gensym*)) ?goal-id ?robot
		(plan-assert-action move  ?curr-loc ?zone ?robot)
		;(plan-assert-action wp-put ?robot ?wp ?mps INPUT (get-wp-complexity ?wp))
	)
	(modify ?g (mode EXPANDED))
)


(defrule goal-expander-FILL-CAP
  ?g <- (goal (id ?goal-id) (class FILL-CAP) (mode SELECTED) (params ))
  =>
  ; get cap from CS shelf side, move, and put to CS input side
)



(defrule goal-expander-CLEAR-MPS ; payment
  ?g <- (goal (id ?goal-id) (class CLEAR-MPS))
  =>
  ; robot picks up the wp from CS output side, move to RS, and put in slide(input) RS

)



;(defrule goal-expander-BSOUT
;  ?g <- (goal (id ?goal-id) (class BSOUT))
;
;  =>
;  ; robot picks up the wp from BS output side
;
;)



(defrule goal-expander-GET-BASE-TO-RS
  ?g <- (goal (id ?goal-id) (class GET-BASE-TO-RS))

  =>
  ; take the base from BS, move to RS, 

)





; 

(defrule goal-expander-FILL-RS
  ?g <- (goal (id ?goal-id) (class FILL-RS))
  =>
  ; robot puts wp into RS input side, 

)




