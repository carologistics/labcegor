(deftemplate order_status
  (slot id (type INTEGER))
  (slot state (type SYMBOL) (allowed-values RC BS R1 R2 R3 CO DE))
)
(deftemplate robo_busy
    (slot id (type INTEGER))
)
(deftemplate machine_busy
    (slot id (type STRING))
)
(deftemplate last_task
    (slot id (type INTEGER))
    (slot l_task_id (type INTEGER))
)
;(deftemplate move
;    (slot id (type INTEGER))
;    (slot waypoint (type STRING))
;    (slot io (type STRING))
;    (slot task_id (type INTEGER))
;)
(deftemplate action
    (slot id (type INTEGER));robo id
    (slot a_type (type STRING)) ;(m)ove,(r)etrive,(p)ut
    (slot machine (type STRING)) ;can be movepoint for move
    (slot io (type STRING)) ;(i)nput,(o)utput, left, center, right
    (slot color (type STRING) (default "") ) ;identifier or ""
    (slot task_id (type INTEGER))
    (slot wait (type INTEGER) (default 0))
)
(deftemplate instruct
    ;(slot a_type (type STRING)) ;(m)ove,(r)etrive,(p)ut
    (slot machine (type STRING)) ;can be movepoint for move
    (slot operation (type STRING)) ;(i)nput,(o)utput, left, center, right
    (slot color (type STRING) (default "") ) ;identifier or ""
    (slot task_id (type INTEGER))
    (slot wait (type INTEGER) (default 0))
)
(deftemplate do
    (slot id (type INTEGER))
    (slot task (type INTEGER))
)
(deftemplate done
    (slot done_t_id (type INTEGER))
)
(deftemplate payments
    (slot station (type INTEGER))
    (slot total_in (type INTEGER))
    (slot total_need (type INTEGER))
    (slot total_blocked (type INTEGER))
    (slot current_in (type INTEGER))

)
(deftemplate update_ringstations_payment
    (multislot rings (type STRING))
)
(deftemplate rings_todo
    (multislot rings (type STRING))
)
(deftemplate pay_rings_rs1
    (slot wait_for (type INTEGER))
)
(deftemplate pay_rings_rs2
    (slot wait_for (type INTEGER))
)
(deffacts hiho
    (last_task (id 1) (l_task_id 1000))
    (last_task (id 2) (l_task_id 2000))
    (last_task (id 3) (l_task_id 3000))
    (last_task (id 4) (l_task_id 4000)) ; any maschine
    (payments (station 1) (total_in 0) (total_need 0) (total_blocked 0) (current_in 0))
    (payments (station 2) (total_in 0) (total_need 0) (total_blocked 0) (current_in 0))
    
)
(deffacts done_zero
(done (done_t_id 0))
)


;(deftemplate nexttasks
;   (slot id (type INTEGER)) ;robo id
;   (multislot tasks)
;)

;(deffacts nexttasts_define
;    (nexttasks (id 1) (tasks))
 ;   (nexttasks (id 2) (tasks))
 ;   (nexttasks (id 3) (tasks))
;)



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
    (order (id ?id_1) (complexity ?complexity_1) (base-color ?base_1) (ring-colors $?ring_colors_1) (cap-color ?cap_1) (quantity-delivered ?qd-us_1))
    (order_status (id ?id_1) (state RC))
    (not (and  (order (id ?oid&:(< ?oid ?id_1)))
               (order_status (id ?oid) (state ?o_state&:(eq ?o_state RC)))
        )
    )
    (last_task (id 3) (l_task_id ?last_1t))
    (last_task (id 3) (l_task_id ?last_2t))
    (last_task (id 3) (l_task_id ?last_3t))
    (last_task (id 4) (l_task_id ?last_mt))
    ;?nt <- (nexttasks (id 3) (tasks $?tasks))
    (not (order_inprocess))
=>   
 (printout red ?id_1 crlf)
 (assert (update_ringstations_payment (rings $?ring_colors_1)))
 (assert (rings_update));; delibertly without nuber for now
 (if (eq ?cap_1 CAP_GREY)
 then
    (assert (action (id 3) (a_type "m") (machine "M-CS1") (io "input") (task_id (+ ?last_3t 1)))) ;action unify
    (assert (action (id 3) (a_type "r") (machine "M-CS1") (io "left") (task_id (+ ?last_3t 2)))) ;action unify
    (assert (action (id 3) (a_type "d") (machine "M-CS1") (io "input") (task_id (+ ?last_3t 3))))
    (assert (instruct (machine "M-CS1") (operation "RETRIEVE_CAP") (task_id (+ ?last_mt 1)) (wait (+ ?last_3t 3))))
    (assert (action (id 3) (a_type "m") (machine "M-CS1") (io "output") (task_id (+ ?last_3t 4))))
    (assert (action (id 3) (a_type "r") (machine "M-CS1") (io "output") (task_id (+ ?last_3t 5)) (wait (+ ?last_mt 1 ))))
    (assert (order_inprocess))

 else
    (assert (action (id 3) (a_type "m") (machine "M-CS2") (io "input") (task_id (+ ?last_3t 1)))) ;action unify
    (assert (action (id 3) (a_type "r") (machine "M-CS2") (io "left") (task_id (+ ?last_3t 2)))) ;action unify
    (assert (action (id 3) (a_type "d") (machine "M-CS2") (io "input") (task_id (+ ?last_3t 3))))
    (assert (instruct (machine "M-CS2") (operation "RETRIEVE_CAP") (task_id (+ ?last_mt 1)) (wait (+ ?last_3t 3))))
    (assert (action (id 3) (a_type "m") (machine "M-CS2") (io "output") (task_id (+ ?last_3t 4))))
    (assert (action (id 3) (a_type "r") (machine "M-CS2") (io "output") (task_id (+ ?last_3t 5)) (wait (+ ?last_mt 1 ))))
    (assert (order_inprocess))
);;simplify
    (assert (action (id 1) (a_type "m") (machine "BS") (io "output") (task_id (+ ?last_1t 1))))
    (assert (instruct (machine "BS") (operation "output") (color ?base_1) (task_id (+ ?last_mt 2)) (wait (+ ?last_1t 1))))
    (assert (action (id 1) (a_type "r") (machine "BS") (io "output") (task_id (+ ?last_1t 2)) (wait (+ ?last_mt 2 ))))
    (printout red $?ring_colors_1 crlf)
    

    (assert (pay_rings_rs1 (wait_for (+ ?last_mt 2))))
    (assert (rings_todo (rings $?ring_colors_1)))

    ;(assert pay_rings_rs1 (wait_for 4990))
    ;(assert next_ring)




;sum costs for rings mit iteration über ring-colors1 je station (blue/yellow, green/orange)
;robo 1 to to in of first ring (if any)

;robo 2 capcarrier pick up and drop of at base station for first payed ring
;robo 3 to out of first ring (and bring cap carrier with you)
;robo 1 to out of 2ed ring (and bring one base with you)
;robo 2 to payments
)

(defrule pay_for_rings_rs1
?init_f <- (pay_rings_rs1 (wait_for ?t_id))
(done (done_t_id ?t_id))
(last_task (id 1)(l_task_id ?last_1t))
(last_task (id 2) (l_task_id ?last_2t))
(last_task (id 3)(l_task_id ?last_3t))
(last_task (id 4) (l_task_id ?last_mt))
?pay <- (payments (station 1) (total_in ?t_in) (total_need ?t_need) (total_blocked ?t_b) (current_in ?c_in) )
=>
    (if (and(> (- ?t_need ?t_in) 0) (<= ?c_in 3))
    then
        (if (eq ?last_1t 1002) 
        then    
            (assert (action (id 3) (a_type "m") (machine "M-RS1") (io "input") (task_id (+ ?last_3t 1))))
            (assert (action (id 3) (a_type "d") (machine "M-RS1") (io "slide") (task_id (+ ?last_3t 2)))) ;;TODO in deliver add update of Payed
            ;(assert (done (task_id (+ ?t_id 1))))
            (retract ?init_f)
            (assert (pay_rings_rs1 (wait_for (+ ?last_mt 1))))
        else
            (if (and(> (- ?t_need ?t_in) 0) (<= ?c_in 3))
            then
                (if (= (- ?t_need ?t_in) 2)
                then             
                    (assert (action (id 2) (a_type "m") (machine "BS") (io "output") (task_id (+ ?last_2t 1))))
                    (assert (instruct (machine "BS") (operation "output") (color "BLACK") (task_id (+ ?last_mt 2)) (wait (+ ?last_2t 1))))
                    (assert (action (id 2) (a_type "r") (machine "BS") (io "output") (task_id (+ ?last_2t 2)) (wait (+ ?last_mt 2 ))))
                    (assert (action (id 2) (a_type "m") (machine "M-RS1") (io "input") (task_id (+ ?last_2t 3))(wait (+ ?last_2t 2))))
                    (assert (action (id 2) (a_type "d") (machine "M-RS1") (io "slide") (task_id (+ ?last_2t 4)) (wait (+ ?last_2t 3))))
                else ;noop
                )
            else
                ;robo3 do 2ed payment
                (assert (action (id 3) (a_type "m") (machine "BS") (io "output") (task_id (+ ?last_3t 1))))
                (assert (instruct (machine "BS") (operation "output") (color "RED") (task_id (+ ?last_mt 3)) (wait (+ ?last_3t 1))))
                (assert (action (id 3) (a_type "r") (machine "BS") (io "output") (task_id (+ ?last_3t 2)) (wait (+ ?last_mt 3 ))))
                (assert (action (id 3) (a_type "m") (machine "M-RS1") (io "input") (task_id (+ ?last_3t 3))(wait (+ ?last_3t 2))))
                (assert (action (id 3) (a_type "d") (machine "M-RS1") (io "slide") (task_id (+ ?last_3t 4)) (wait (+ ?last_3t 3))))
                (assert (pay_rings_rs2 (wait_for  (+ ?last_3t 3)))
            )
            )
    
        )
    else
        (assert (pay_rings_rs2 (wait_for (+ ?last_3t 2))))
    )
   
)

(defrule pay_for_rings_rs2
?init_f <- (pay_rings_rs2 (wait_for ?t_id))
(done (done_t_id ?t_id))
(last_task (id 1)(l_task_id ?last_1t))
(last_task (id 2) (l_task_id ?last_2t))
(last_task (id 3)(l_task_id ?last_3t))
(last_task (id 4) (l_task_id ?last_mt))
?pay <- (payments (station 2) (total_in ?t_in) (total_need ?t_need) (total_blocked ?t_b) (current_in ?c_in) )
=>
    (if (and(> (- ?t_need ?t_in) 0) (<= ?c_in 3))
    then
        (if (eq ?last_1t 1002) 
        then    
            (assert (action (id 3) (a_type "m") (machine "M-RS2") (io "input") (task_id (+ ?last_3t 1))))
            (assert (action (id 3) (a_type "d") (machine "M-RS2") (io "slide") (task_id (+ ?last_3t 2)))) ;;TODO in deliver add update of Payed
            ;(assert (done (task_id (+ ?t_id 1))))
            (retract ?init_f)
            (assert (pay_rings_rs2 (wait_for (+ ?last_mt 1))))
        else
            (if (and(> (- ?t_need ?t_in) 0) (<= ?c_in 3))
            then
                (if (= (- ?t_need ?t_in) 2)
                then             
                    (assert (action (id 2) (a_type "m") (machine "BS") (io "output") (task_id (+ ?last_2t 1))))
                    (assert (instruct (machine "BS") (operation "output") (color "BLACK") (task_id (+ ?last_mt 2)) (wait (+ ?last_2t 1))))
                    (assert (action (id 2) (a_type "r") (machine "BS") (io "output") (task_id (+ ?last_2t 2)) (wait (+ ?last_mt 2 ))))
                    (assert (action (id 2) (a_type "m") (machine "M-RS2") (io "input") (task_id (+ ?last_2t 3))(wait (+ ?last_2t 2))))
                    (assert (action (id 2) (a_type "d") (machine "M-RS2") (io "slide") (task_id (+ ?last_2t 4)) (wait (+ ?last_2t 3))))
                else ;noop
                )
            else
                ;robo3 do 2ed payment
                (assert (action (id 3) (a_type "m") (machine "BS") (io "output") (task_id (+ ?last_3t 1))))
                (assert (instruct (machine "BS") (operation "output") (color "BLACK") (task_id (+ ?last_mt 3)) (wait (+ ?last_3t 1))))
                (assert (action (id 3) (a_type "r") (machine "BS") (io "output") (task_id (+ ?last_3t 2)) (wait (+ ?last_mt 3 ))))
                (assert (action (id 3) (a_type "m") (machine "M-RS2") (io "input") (task_id (+ ?last_3t 3))(wait (+ ?last_3t 2))))
                (assert (action (id 3) (a_type "d") (machine "M-RS2") (io "slide") (task_id (+ ?last_3t 4)) (wait (+ ?last_3t 3))))
                (assert (pick_rings))
            )
            )
    
        )
    else
        (assert (pick_rings))
    )

(defrule pickup_rings
(pick-rings)
(last_task (id 1)(l_task_id ?last_1t))
(last_task (id 4)(l_task_id ?last_mt))
(done (done_t_id ?t_id))
(rings_todo (rings ?ring1 $?rings_rest))
=>
    (switch ?ring1
    (case (or RING_YELLOW RING_BLUE) then 
        (assert (action (id 1) (a_type "m") (machine "M-RS2") (io "input") (task_id (+ ?last_1t 1))))
        (assert (action (id 1) (a_type "d") (machine "M-RS2") (io "input") (task_id (+ ?last_1t 2) (wait (+ ?last_1t 1)))))
        (assert (instruct (machine "M-RS2") (operation "XYZ") (task_id (+ ?last_mt 1)) (wait (+ ?last_1t 2))))
        (assert (action (id 1) (a_type "m") (machine "M-RS2") (io "output") (task_id (+ ?last_1t 3)(wait (+ ?last_mt 1)))))
        (assert (action (id 1) (a_type "r") (machine "M-RS2") (io "output") (task_id (+ ?last_1t 4)(wait (+ ?last_1t 3)))))
        (assert (rings_todo $?rings_rest))
    )
    (case (or RING_ORANGE RING_GREEN) then 
        (assert (action (id 1) (a_type "m") (machine "M-RS1") (io "input") (task_id (+ ?last_1t 1))))
        (assert (action (id 1) (a_type "d") (machine "M-RS1") (io "input") (task_id (+ ?last_1t 2) (wait (+ ?last_1t 1)))))
        (assert (instruct (machine "M-RS1") (operation "XYZ") (task_id (+ ?last_mt 1)) (wait (+ ?last_1t 2))))
        (assert (action (id 1) (a_type "m") (machine "M-RS1") (io "output") (task_id (+ ?last_1t 3)(wait (+ ?last_mt 1)))))
        (assert (action (id 1) (a_type "r") (machine "M-RS1") (io "output") (task_id (+ ?last_1t 4)(wait (+ ?last_1t 3)))))
    )
    (default 
        (assert (action (id 1) (a_type "m") (machine "M-CS") (io "input") (task_id (+ ?last_1t 1))))
        (assert (action (id 1) (a_type "d") (machine "M-CS") (io "input") (task_id (+ ?last_1t 2) (wait (+ ?last_1t 1)))))
        (assert (instruct (machine "M-CS") (operation "XYZ") (task_id (+ ?last_mt 1)) (wait (+ ?last_1t 2))))
        (assert (action (id 1) (a_type "m") (machine "M-CS") (io "output") (task_id (+ ?last_1t 3)(wait (+ ?last_mt 1)))))
        (assert (action (id 1) (a_type "r") (machine "M-CS") (io "output") (task_id (+ ?last_1t 4) (wait (+ ?last_1t 3)))))
        (assert (action (id 1) (a_type "m") (machine "M-DS") (io "input") (task_id (+ ?last_1t 5) (wait (+ ?last_1t 4)))))
        (assert (action (id 1) (a_type "d") (machine "M-DS") (io "input") (task_id (+ ?last_1t 6) (wait (+ ?last_1t 5)))))
        (assert (instruct (machine "M-DS") (operation "XYZ") (task_id (+ ?last_mt 2)) (wait (+ ?last_1t 6))))
    )
    )
)

(defrule ringstation_new_payments_need
?update <- (update_ringstations_payment (rings ?ring1 $?rest_rings))
?p1 <- (payments (station 1) (total_need ?tn1))
?p2 <- (payments (station 2) (total_need ?tn2))
(ring-spec (color RING_BLUE) (cost ?cost_b))
(ring-spec (color RING_YELLOW) (cost ?cost_y))
(ring-spec (color RING_GREEN) (cost ?cost_g))
(ring-spec (color RING_ORANGE) (cost ?cost_o))
(rings_update)

=>
(if (eq ?ring1 "")
then
    (printout green "no more payment update" crlf)
    (assert (done (done_t_id 4000)))

else
    (switch ?ring1
    (case RING_YELLOW then (modify ?p2 (total_need (+ ?tn2 ?cost_y))))
    (case RING_BLUE then (modify ?p2 (total_need (+ ?tn2 ?cost_b))))
    (case RING_ORANGE then (modify ?p1 (total_need (+ ?tn1 ?cost_o))))
    (case RING_GREEN then (modify ?p1 (total_need (+ ?tn1 ?cost_g)))) 
    (default (printout red "no more payment update - LOOP" crlf))
    )
    (printout red "payments updated - LOOP" crlf)
    (printout green ?tn1 crlf)
    (printout green ?tn2 crlf)
    (modify ?update (rings $?rest_rings))
    (assert (done (done_t_id 4000)))
)
)


(defrule nexttask
    (not (robo_busy (id ?id)))
    (not (do (id ?id) (task ?t-id)))
    ?a <- (action (id ?id) (task_id ?t-id))
    (not  (action (id ?id)(task_id ?t-id2&:(< ?t-id2 ?t-id))))
    ;action mit kleinster t-id
    =>
    (assert (do (id ?id) (task ?t-id)))
    ;(retract ?a)
)

(defrule waitforfinish
    ?d <- (do (id ?id) (task ?t-id))
    ?b <- (robo_busy (id ?id))
    (protobuf-msg (type "llsf_msgs.AgentTask") (msg-type ?msg-type)
    (client-type PEER) (ptr ?msg))
=>
    (bind ?robo_id (pb-field-value ?msg "robot_id"))
    (bind ?task_id (pb-field-value ?msg "task_id"))
    (bind ?success (pb-field-value ?msg "successful"))
    (if (and (eq ?robo_id ?id) (eq ?task_id ?t-id) (eq ?success TRUE))
    then
        (retract ?d)
        (retract ?b)
        (assert (done (done_t_id ?t-id)))
        (printout green "TASK DONE"  crlf)
    else
        (printout green ?robo_id ?task_id ?success  crlf)
        (printout green ?id ?t-id  crlf)
    )
)
;todo check tasks for finish (s. t4 listen to comunication)


(defrule watchmy_stuff
=>
(watch activations recive_orders))

;----WIP-----


(defrule robo_move
  ?ac <- (action (a_type "m") (id ?id) (machine ?wp) (io ?io) (task_id ?t-id) (wait ?w))
  (done (done_t_id ?w))
  (protobuf-peer (name ?name) (peer-id ?peer-id))
  (test (eq ?name (sym-cat (str-cat "ROBOT" ?id))))
  ?lt <-(last_task (id ?id) (l_task_id ?last_t))
  ;(not (robo_busy (id ?id)))
  ?do <- (do (id ?id) (task ?t-id))
  =>
  (assert (robo_busy (id ?id)))
  ;(retract ?do)
  (retract ?ac)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?t-id)
  (modify ?lt (l_task_id ?t-id)); UPdate fact (maybe in check funktion)
  (pb-set-field ?msg "robot_id" ?id)
  (bind ?move-msg (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?move-msg "waypoint" ?wp)
  (pb-set-field ?move-msg "machine_point" ?io)
  (pb-set-field ?msg "move" ?move-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)

(defrule robo_retrive
  ?ac <- (action (a_type "r") (id ?id) (machine ?wp) (io ?io) (task_id ?t-id)(wait ?w))
  (done (done_t_id ?w))
  (protobuf-peer (name ?name) (peer-id ?peer-id))
  (test (eq ?name (sym-cat (str-cat "ROBOT" ?id))))
  ?lt <-(last_task (id ?id) (l_task_id ?last_t))
  ;(not (robo_busy (id ?id)))
  ?do <- (do (id ?id) (task ?t-id))
  =>
  (retract ?ac)
  (assert (robo_busy (id ?id)))
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?t-id)
  (modify ?lt (l_task_id ?t-id)); UPdate fact (maybe in check funktion)
  (pb-set-field ?msg "robot_id" ?id)
  (bind ?retrieve-msg (pb-create "llsf_msgs.Retrieve")) 
  (pb-set-field ?retrieve-msg "machine_id" ?wp)
  (pb-set-field ?retrieve-msg "machine_point" ?io)
  (pb-set-field ?msg "retrieve" ?retrieve-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)


(defrule robo_deliver
  ?ac <- (action (a_type "d") (id ?id) (machine ?wp) (io ?io) (task_id ?t-id)(wait ?w))
  (done (done_t_id ?w))
  (protobuf-peer (name ?name) (peer-id ?peer-id))
  (test (eq ?name (sym-cat (str-cat "ROBOT" ?id))))
  ?pay_rs1 <- (payments (station 1) (total_in ?t_in1) (current_in ?c_in1))
  ?pay_rs2 <- (payments (station 2) (total_in ?t_in2) (current_in ?c_in2))
  ?lt <-(last_task (id ?id) (l_task_id ?last_t))
  ;(not (robo_busy (id ?id)))
  ?do <- (do (id ?id) (task ?t-id))
  =>
  (retract ?ac)
  (assert (robo_busy (id ?id)))
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?t-id)
  (modify ?lt (l_task_id ?t-id)); UPdate fact (maybe in check funktion)
  (pb-set-field ?msg "robot_id" ?id)
  (bind ?deliver-msg (pb-create "llsf_msgs.Deliver")) 
  (pb-set-field ?deliver-msg "machine_id" ?wp)
  (pb-set-field ?deliver-msg"machine_point" ?io)
  (if (eq ?io "slide")
    then
        (if (eq ?wp "M-RS1")
        then
            (modify ?pay_rs1 (total_in (+ ?t_in1 1)) (current_in (+ ?c_in1 1)))
        )
    else
    (if (eq ?wp "M-RS2")
    then
     (modify ?pay_rs2 (total_in (+ ?t_in2 1)) (current_in (+ ?c_in2 1)))
    )
  )
  (pb-set-field ?msg "deliver" ?deliver-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)

(defrule cs_retrive
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  ?inst <- (instruct (machine ?m) (operation ?op) (task_id ?t-id) (wait ?w))
  (done (done_t_id ?w))
  (not (machine_busy (id ?m)))
  ?lt <-(last_task (id 4) (l_task_id ?last_t))
  =>
  (assert (machine_busy (id ?m)))
  (modify ?lt (l_task_id ?t-id))
  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?m)
  (if (or (eq ?m "M-CS1") (eq ?m "M-CS2"))
  then
  (bind ?prep-msg (pb-create "llsf_msgs.PrepareInstructionCS")) 
  (pb-set-field ?prep-msg "operation" ?op)
  (pb-set-field ?msg "instruction_cs" ?prep-msg)
  )
  
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)