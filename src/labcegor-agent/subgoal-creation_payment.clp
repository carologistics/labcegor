; made by Yuan,Chengzhi, last modified @20240310

; (deftemplate ring_payment
;   (slot order-id (type INTEGER))
;   (slot ring (type SYMBOL))
;   (slot ring_collect (type INTEGER))
; )

; (deftemplate finish_payment
;   (slot order-id (type INTEGER))
;   (slot ring (type SYMBOL))
; )


(defrule subgoal_payment_0
  ?trigger_goal <- (goal (id ?goal-id) (class tri-payment) (mode FORMULATED) (params order-id ?order-id ring ?ring index ?index))
  ?ring-spec <- (ring-spec (color ?ring) (cost 0))
  (not (finish_payment (order-id ?order-id) (ring ?ring) (index ?index)))
  (not (finish-order (order-id ?order-id)))
  =>
  (assert (finish_payment (order-id ?order-id) (ring ?ring) (index ?index)))
  (assert (ring_payment (order-id ?order-id) (ring ?ring) (index ?index) (ring_collect 0)))
  (printout t "finish collecting ring " ?ring " payment for order id " ?order-id crlf)
  (retract ?trigger_goal)
)


(defrule subgoal-creation-trigger-payment-first
  ?trigger-goal <- (goal (id ?goal-id) (class tri-payment) (mode FORMULATED) (params order-id ?order-id ring ?ring index ?index))
  ?ring-spec <- (ring-spec (color ?ring) (cost ?cost&:(> ?cost 0)))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot mps-with-side START))

  (or (ring-assignment (machine ?rs) (colors ?ring ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring))
  )

  ?payment-mps <- (machine (name ?mps) (type CS) (state IDLE))
  (not (goal (class payment-first)))
  
  (not (finish-order (order-id ?order-id)))

  ; (not (mps-occupied (mps ?mps)))
  (not (finish_payment (order-id ?order-id) (ring ?ring) (index ?index))) 
  =>
  (assert (goal (id (sym-cat payment-first- (gensym*)))
                    (class payment-first)
                    (params robot ?robot
                            current-loc START
                            current-side None  ; none/slide-side
                            payment-mps ?mps
                            payment-side slide-side
                            rs ?rs
                            ring ?ring
			    order-id ?order-id index ?index)))
   
   (assert (ring_payment (order-id ?order-id) (ring ?ring) (index ?index) (ring_collect 0)))
   (retract ?trigger-goal ?robot-at-start)
   ; (assert (mps-occupied (mps ?mps)))
)


;(defrule subgoal-lifecycle-payment
;  (goal (class payment-first|payment) (params robot ?robot
;                                                current-loc ?curr-loc
;                                                current-side ?curr-side
;                                                payment-mps ?prev-payment-mps
;                                                payment-side ?prev-payment-side
;                                                rs ?rs
;                                                ring ?ring
;						order-id ?order-id index ?index) (outcome COMPLETED))
;  ?mps-occ <- (mps-occupied (mps ?prev-payment-mps))
;  =>
;  (retract ?mps-occ)
;)


(defrule subgoal-creation-trigger-loop-payment ; fire if payment >= 1
  ?premise_goal <- (goal (class payment-first|payment) (params robot ?robot
                                                current-loc ?curr-loc
						current-side ?curr-side
                                                payment-mps ?prev-payment-mps
                                                payment-side ?prev-payment-side
                                                rs ?rs
                                                ring ?ring
						order-id ?order-id index ?index) (outcome COMPLETED))
  ?ring-spec <- (ring-spec (color ?ring) (cost ?cost))
  ?rp <- (ring_payment (order-id ?order-id) (ring ?ring) (index ?index) (ring_collect ?now_payment))
  ?payment-mps <- (machine (name ?mps) (type CS) (state IDLE))
  ;(not (mps-occupied (mps ?mps)))

  ; -/+
  (not (finish_payment (order-id ?order-id) (ring ?ring) (index ?index)))
  
  =>
  (bind ?current-side slide-side)
   
  ; update payment +1,
  (bind ?new-payment-collect (+ ?now_payment 1))
  (modify ?rp (ring_collect ?new-payment-collect))
  
  (if (> ?cost ?new-payment-collect)
    then
      (assert (goal (id (sym-cat payment-loop- (gensym*)))
                    (class payment)
                    (params robot ?robot
                            current-loc ?rs
			    current-side ?current-side
                            payment-mps ?mps
                            payment-side slide-side
                            rs ?rs
                            ring ?ring
			    order-id ?order-id index ?index))
		;(mps-occupied (mps ?mps))
	)
    else
      (printout t "finish collecting ring " ?ring " payment for order id " ?order-id crlf)
      (assert (finish_payment (order-id ?order-id) (ring ?ring) (index ?index)))
      (assert (wm-fact (key domain fact at args? r ?robot mps-with-side START)))
  )
  (retract ?premise_goal)
)
