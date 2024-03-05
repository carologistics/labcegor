; made by Yuan,Chengzhi, last modified @20240305

(defrule order_expansion_c0
  ?order_c0 <- (order (id ?id) (complexity C0) (base-color ?base-color) 
			(quantity-requested ?quantity-requested&:(> ?quantity-requested 0)) )
  ; (debug)
  =>
  ; expand this order
  (assert (goal (id (sym-cat tri-bs-c0firstrun- (gensym*))) (class tri-bs-c0firstrun) (params order-id ?id))) ; 
         
  ; go to cs-ds
  (assert (goal (id (sym-cat bs-cs-c0run- (gensym*))) (class tri-cs-c0run) (params order-id ?id)))
)


(defrule order_expansion_c1
  ?order_c1 <- (order (id ?id) (complexity C1) (base-color ?base-color) (quantity-requested ?quantity-requested&:(> ?quantity-requested 0)) (ring-colors ?ring-color1))
  (ring-spec (color ?ring-color1) (cost ?cost))
  (machine (name C-BS) (state IDLE))
  ; (debug)
  =>
  (assert 
     (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color1))
     (goal (id (sym-cat tri-bs-c1firstrun- (gensym*))) (class tri-bs-c1firstrun) (params order-id ?id ring-color ?ring-color1)) ; bs-rs
     (goal (id (sym-cat rs-cs-c1run- (gensym*))) (class trirs-cs-c1run) (params order-id ?id)) ; rs - cs
  )
)


(defrule order_expansion_c2
  ?order_c2 <- (order (id ?id) (complexity C2) (base-color ?base-color) 
			(quantity-requested ?quantity-requested&:(> ?quantity-requested 0)) (ring-colors ?ring-color1 ?ring-color2))
  ; order info c2 and ring cost
  (ring-spec (color ?ring-color1) (cost ?cost-1))
  (ring-spec (color ?ring-color2) (cost ?cost-2))
  ; (debug)
  =>
  ; expand this order
  (assert (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color1)))
  (assert (goal (id (sym-cat tri-bs-c2firstrun- (gensym*))) (class tri-bs-c2firstrun) (params order-id ?id ring-color ?ring-color1)))
         
  ; 2nd run rs-loop
  (assert (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color2)))
  (assert (goal (id (sym-cat rs-loop-c2run- (gensym*))) (class trirs-loop-c2run) (params order-id ?id ring-color ?ring-color2)))

  ; go to rs-cs-ds
  (assert (goal (id (sym-cat rs-cs-c2run- (gensym*))) (class trirs-cs-c2run) (params order-id ?id)))         
         
)




(defrule order_expansion_c3
  ?order_c3 <- (order (id ?id) (complexity C3) (base-color ?base-color) 
			(quantity-requested ?quantity-requested&:(> ?quantity-requested 0)) (ring-colors ?ring-color1 ?ring-color2 ?ring-color3))
  ; order info c3 and ring cost
  (ring-spec (color ?ring-color1) (cost ?cost-1))
  (ring-spec (color ?ring-color2) (cost ?cost-2))
  (ring-spec (color ?ring-color2) (cost ?cost-3))
  ; (debug)
  =>
   (assert (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color1)))
   (assert (goal (id (sym-cat tri-bs-c3firstrun- (gensym*))) (class tri-bs-c3firstrun) (params order-id ?id ring-color ?ring-color1)))
         
   ; 2nd run, rs-loop-1
   (assert (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color2)))
   (assert (goal (id (sym-cat rs-loop1-c3run- (gensym*))) (class trirs-loop1-c3run) (params order-id ?id ring-color ?ring-color2)))

   ; 3rd run, rs-loop-2
   (assert (goal (id (sym-cat tri-payment- (gensym*))) (class tri-payment) (params ring ?ring-color3)))
   (assert (goal (id (sym-cat rs-loop2-c3run- (gensym*))) (class trirs-loop2-c3run) (params order-id ?id ring-color ?ring-color3)))

   ; go to rs-cs-ds
   (assert (goal (id (sym-cat rs-cs-c3run- (gensym*))) (class trirs-cs-c3run) (params order-id ?id)))                  
)


(defrule complete_order_expansion
  ?finished-order <- (order (id ?id) (quantity-requested 0))
  =>
  (printout t "finish expansion for order id " ?id crlf)
  (retract ?finished-order)
)

