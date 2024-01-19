(defrule order_expansion_c2_getbasemovetors
  ?order_c2 <- (order (id ?id) (complexity C2) (base-color ?base-color) (quantity-requested ?quantity-requested) (ring-colors ?ring-color1 ?ring-color2))
  ; order info c2 and ring cost
  (ring-spec (color ?ring-color1) (cost ?cost-1))
  (ring-spec (color ?ring-color2) (cost ?cost-2))

  ; take base from BS and move to RS: subgoal-get-base-to-rs
  (machine (name C-BS) (state IDLE))



  ; make payment: subgoal-CLEAR-MPS - pending
 

  (not (all-delivered))

  =>
   (if (eq ?quantity-requested 0)
       then ; finish delivery
         (printout t "all delivered" crlf)
         (assert (all-delivered))
       else ; expand this order
         ; placeholder for trigger payment subgoal, pending ...  
         (assert (goal (id (sym-cat bs-rs-firstrun- (gensym*))) (class tribs-rs-firstrun) (params order-id ?id ring-color ?ring-color1))) ; trigger subgoal

         ; 2nd run
         ; placeholder for payment, in 2nd time
         (assert (goal (id (sym-cat rs-loop-run- (gensym*))) (class trirs-loop-run) (params order-id ?id ring-color ?ring-color2)))

         ; go to cs
         
         
 	 ; go to ds
         
   )
)



;(defrule goal-creation-get-base-to-rs-first-run
;  ?trigger_goal <- (goal (id ?goal-id) (class tribs-rs-firstrun) (mode FORMULATED) (params order-id ?order-id ring-color ?ring-color))
;  (wm-fact (id "/refbox/team-color") (value ?team-color&:(neq ?team-color nil)))

;  (wm-fact (key domain fact at args? r ?robot x ?loc))
;  (order (id ?order-id) (base-color ?wp))


;  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
;      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
;  )

;  =>
;  (bind ?bs C-BS) ; must be this name because only one BS
;  (bind ?bs-side INPUT) ; hard code now
;  (bind ?rs-side INPUT) ; hard code now
  
;  (printout t "Goal " bs-rs-firstrun " formulated" crlf)
;  (assert (goal (id (sym-cat bs-rs-firstrun- (gensym*)))
;                (class bs-run-firstrun)
;                (parent ?goal-id) (sub-type SIMPLE)
;                             (params robot ?robot
;                                     bs ?bs
;                                     bs-side ?bs-side
;                                     rs ?rs
;                                     rs-side ?rs-side
;                                     wp ?wp
;                                     )
;                            (required-resources ?wp)
;  ))
;  (retract ?trigger_goal)
;
;)


;(defrule goal-creation-get-base-to-rs-run
;  ?trigger_goal <- (goal (id ?goal-id) (class trirs-loop-run) (params order-id ?order-id ring-color ?ring-color))
;  ?premise_goal <- (goal (id ?premise_goal_id) (class bs-run-firstrun) (outcome COMPLETED) (params robot ?robot bs ?bs bs-side ?bs-side rs ?pre_rs rs-side ?pre_rs-side wp ?wp))
;
;  (or (ring-assignment (machine ?rs) (colors ?ring-color ?tmp))
;      (ring-assignment (machine ?rs) (colors ?tmp ?ring-color))
;  )
;
;  =>
;  (bind ?rs-side INPUT)
;  (assert (goal (id (sym-cat rs-loop-run- (gensym*)))
;                (class rs-loop-run)
;                (parent ?goal-id) (sub-type SIMPLE)
;                              (params robot ?robot
;                                      rs ?rs
;                                      rs-side ?rs-side
;                                      wp ?wp)))
;  (retract ?trigger_goal)
;)


