(deftemplate order_status
  (slot id (type INTEGER))
  (slot state (type SYMBOL) (allowed-values RC BS R1 R2 R3 CO DE))
)
(defrule recive_orders
    (order(id ?id_1))
    (not (order_status (id ?id_1)))
    (not (and (order (id ?oid&:(< ?oid ?id_1)))
              (not (order_status (id ?oid))))
    )
=>
    (assert (order_status (id ?id_1) (state RC)))    
)

(defrule select_next_order
    (order (id ?id_1) (complexity ?complexity_1) (base-color ?base_1) (ring-colors $?ring-colors_1) (cap-color ?cap_1) (quantity-delivered ?qd-us_1))
    (order_status (id ?id_1) (state RC))
    (not (and  (order (id ?oid&:(< ?oid ?id_1)))
               (order_status (id ?oid) (state ?o_state&:(eq ?o_state RC)))
        )
    )
=>   
 (printout red ?id_1 crlf)
 (if (eq ?cap_1 CAP_GREY)
 then
 ;robo3 to CS-1
 ;then CS-2
 else
 ;robo3 to CS-2
 ;then CS-1
)
;sum costs for rings
;robo 1 to base station
;base station instructen on base color
;robo 2 capcarrier pick up and drop of at base station for first payed ring
;robo 3 to out of first ring (and bring cap carrier with you)
;robo 1 to out of 2ed ring (and bring one base with you)
;robo 2 to paymnents

)



(defrule watchmy_stuff
=>
(watch activations recive_orders))