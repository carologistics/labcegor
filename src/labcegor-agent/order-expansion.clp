; made by Yuan,Chengzhi @20240121

;donot delete!!!!!!!
(defrule order_expansion_c1
  ?order_c1 <- (order (id ?id) (complexity C1) (base-color ?base-color) (quantity-requested ?quantity-requested) (ring-colors ?ring-color1))
  (ring-spec (color ?ring-color1) (cost ?cost))
  (machine (name C-BS) (state IDLE))
  =>
  (if (eq ?quantity-requested 0)
    then
      (printout t "all delivered" crlf)
      (retract ?order_c1)
    else
      (assert 
          (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color1))
	  (goal (id (sym-cat tri-bs-c1firstrun- (gensym*))) (class tri-bs-c1firstrun) (params order-id ?id ring-color ?ring-color1)) ; bs-rs
	  (goal (id (sym-cat rs-cs-c1run- (gensym*))) (class trirs-cs-c1run) (params order-id ?id)) ; rs - cs
	)
      ; (bind ?new-quantity-requested (- ?quantity-requested 1))
      ; (modify ?order_c1 (quantity-requested ?new-quantity-requested))
  )
)


(defrule order_expansion_c2
  ?order_c2 <- (order (id ?id) (complexity C2) (base-color ?base-color) 
			(quantity-requested ?quantity-requested) (ring-colors ?ring-color1 ?ring-color2))
  ; order info c2 and ring cost
  (ring-spec (color ?ring-color1) (cost ?cost-1))
  (ring-spec (color ?ring-color2) (cost ?cost-2))
  
  =>
   (if (eq ?quantity-requested 0)
       then ; finish delivery
         (printout t "all delivered" crlf)
         (retract ?order_c2)
       else 
         ; expand this order
         (assert (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color1)))
         (assert (goal (id (sym-cat tri-bs-c2firstrun- (gensym*))) (class tri-bs-c2firstrun) (params order-id ?id ring-color ?ring-color1)))
         
         ; 2nd run rs-loop ; debug goes here @1.26
         (assert (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color2)))
         (assert (goal (id (sym-cat rs-loop-c2run- (gensym*))) (class trirs-loop-c2run) (params order-id ?id ring-color ?ring-color2)))

         ; go to rs-cs-ds
         (assert (goal (id (sym-cat rs-cs-c2run- (gensym*))) (class trirs-cs-c2run) (params order-id ?id)))         
         
         ; (bind ?new-quantity-requested (- ?quantity-requested 1)) 
         ; (modify ?order_c2 (quantity-requested ?new-quantity-requested))
   )
)








(defrule goal-create-c0
  ?order_c0 <- (order (id ?id) (complexity C0) (base-color ?base-color) 
			(quantity-requested ?quantity-requested) )
  =>
   (if (eq ?quantity-requested 0)
       then ; finish delivery
         (printout t "all delivered" crlf)
         (retract ?order_c0)
       else 
         ; expand this order
         (assert (goal (id (sym-cat tri-bs-c0firstrun- (gensym*))) (class tri-bs-c0firstrun) (params order-id ?id))) ; 
         

         ; go to cs-ds
         (assert (goal (id (sym-cat bs-cs-c0run- (gensym*))) (class trirs-cs-c0run) (params order-id ?id)))          
         
   )
)
