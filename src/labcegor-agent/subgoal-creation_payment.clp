(deftemplate ring_payment
  (slot ring (type SYMBOL))
  (slot ring_collect (type INTEGER))
)

(deftemplate finish_payment
  (slot ring (type SYMBOL))
)


(defrule subgoal-creation-trigger-payment-first
  ?trigger-goal <- (goal (id ?goal-id) (class tri-payment) (mode FORMULATED) (params ring ?ring))
  ?ring-spec <- (ring-spec (color ?ring) (cost ?cost))
  ?robot-at-start <- (wm-fact (key domain fact at args? r ?robot x START))

  (or (ring-assignment (machine ?rs) (colors ?ring ?tmp))
      (ring-assignment (machine ?rs) (colors ?tmp ?ring))
  )

  ?payment-mps <- (machine (name ?mps) (type CS) (state IDLE))
  =>
  (if (> ?cost 0)
    then
      (assert (goal (id (sym-cat payment-first- (gensym*)))
                        (class payment-first)
                        (params robot ?robot
                                current-loc START
                                payment-mps ?mps
                                payment-side OUTPUT
                                rs ?rs
                                ring ?ring)))

      (assert (ring_payment (ring ?ring) (ring_collect 0)))
      (retract ?trigger-goal ?robot-at-start)
    else
      (assert (ring_payment (ring ?ring) (ring_collect 0)))
      (assert (finish_payment (ring ?ring)))
      (retract ?trigger-goal)
  )
)


(defrule subgoal-creation-trigger-loop-payment ; fire if payment >= 1
  ?premise_goal <- (goal (class payment-first|payment) (params robot ?robot
                                                current-loc ?curr-loc
                                                payment-mps ?prev-payment-mps
                                                payment-side ?prev-payment-side
                                                rs ?rs
                                                ring ?ring) (outcome COMPLETED))
  ?ring-spec <- (ring-spec (color ?ring) (cost ?cost))
  ?rp <- (ring_payment (ring ?ring) (ring_collect ?now_payment))
  ?payment-mps <- (machine (name ?mps) (type CS) (state IDLE))
  =>
  (bind ?current-loc (sym-cat ?rs OUTPUT))

  ; update payment +1,
  (bind ?new-payment-collect (+ ?now_payment 1))
  (modify ?rp (ring_collect ?new-payment-collect))
  

  (if (> ?cost ?new-payment-collect)
    then
      (assert (goal (id (sym-cat payment-loop- (gensym*)))
                    (class payment)
                    (params robot ?robot
                            current-loc ?current-loc
                            payment-mps ?mps
                            payment-side OUTPUT
                            rs ?rs
                            ring ?ring)))
      (retract ?premise_goal)
    else
      (assert (finish_payment (ring ?ring)))
  )
)

