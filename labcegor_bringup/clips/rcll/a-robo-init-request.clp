(defrule init_all
(init_moves)
=>
    (assert (order_status (id 0) (prio 0)))
    (assert (order_status (id 42) (prio 0)))
    (assert (order_status (id 40) (prio 0) (complexity C0)))
    (assert (init_it (id 1) (iteration 1)))
    (assert (init_it (id 2) (iteration 1)))
    (assert (init_it (id 3) (iteration 1)))
    (assert (request_task (id 3) (last_task 3000)))
    (assert (request_task (id 2) (last_task 2000)))
    (assert (request_task (id 1) (last_task 1000) (machine_order 1)))
    (assert (order_colors (id 0)))
    (assert (order_colors (id 42)))
    (assert (order_colors (id 40)))
)

(defrule waitforfinish_machine; does not fire why? if state is variable it fires exactly once, but too early
;wron machine bound conection with line 100
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order) (pos ?m_pos))
(test (> ?m_task 0)) 
(machine (name ?m_name) (state ?m_state))
(test (or (eq ?m_state READY-AT-OUTPUT) (eq ?m_state PREPARED)))
=>
  (modify ?machine_s (task 0) (pos OUTPUT))
)

(defrule waitforfinish_robo
    ;?d <- (do (id ?id) (task ?t-id))
    ;?b <- (robo_busy (id ?id))
    ?robo_s <- (robo_status (id ?id) (task ?robo_task) (order ?robo_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des) (des_at_waypoint ?des_wp))
    (test (> ?robo_task 0)) ;; busy check
    ?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order));TODO ?name müsste pos für binding (update), klappt dann aber bei retrive nicht
    (test (or (eq ?m_name ?des) (eq ?m_name ?pos)))
    ?order_s <- (order_status (id ?order_oid) (state ?order_state) (complexity ?complexity)(next_step ?next_step))
    ?m_order_s <- (order_status (id ?m_order))
    (test (or (eq ?robo_order 0) (eq ?robo_order 40) (eq ?robo_order ?order_oid)))
    (order_status (id ?m_order) (next_step ?m_next_step))
    (order_colors (id ?m_order) (base ?order_base) (ring_1 ?order_r1) (ring_2 ?order_r2) (ring_3 ?order_r3) (cap ?order_cap))
    (protobuf-msg (type "llsf_msgs.AgentTask") (msg-type ?msg-type) (client-type PEER) (ptr ?msg))
=>
    (bind ?robo_id (pb-field-value ?msg "robot_id"))
    (bind ?task_id (pb-field-value ?msg "task_id"))
    (bind ?success (pb-field-value ?msg "successful"))
    (if (and (eq ?robo_id ?id) (eq ?task_id ?robo_task) (eq ?success TRUE)) ;(eq ?task_id ?t-id)
    then
        ;(retract ?d)
        ;(retract ?b)
        ;(assert (done (done_t_id ?t-id)))
        (if (not (eq ?des EMPTY));; aka was movment
            then
                (modify ?robo_s (pos ?des) (pos_at_waypoint ?des_wp) (des EMPTY) (des_at_waypoint EMPTY)) ;pos = des; pos_wp =des_wp, des, des_wp = ""
            else ; NO MOVEMENT
                (if (eq ?robo_order 0);; aka was retrive
                    then
                        (if (not (eq ?m_order 0))
                            then (modify ?robo_s (order ?m_order))
                            else (modify ?robo_s (order 40))
                        )
                        (modify ?machine_s (order 0))
                        (modify ?machine_s (pos empty))
                        (if (eq ?id 1)
                            then (switch ?m_next_step
                                (case RING_1 then (modify ?m_order_s (next_color ?order_r1)))
                                (case RING_2 then (modify ?m_order_s (next_color ?order_r2)))
                                (case RING_3 then (modify ?m_order_s (next_color ?order_r3)))
                                (case CAP then (modify ?m_order_s (next_color ?order_cap)))
                            )
                        )
                        ;update order status
                
                    else ; was deliver        
                        (modify ?machine_s (order ?robo_order) (task 42) );TODO if not DS
                        (modify ?robo_s (order 0))

                        (if (eq ?id 1)
                            then (switch ?pos  ;Update next step
                            ;(case M-BS then ))
                            (case M-RS1 then (if (eq (sub-string 2 2 ?complexity) (sub-string 6 6 ?next_step)) then (modify ?order_s (next_step CAP)) else (switch (sub-string 2 2 ?complexity) (case 1  then (modify ?order_s (next_step RING_2)))
                                                    (case 2  then (modify ?order_s (next_step RING_2)))))) ;TODO
                            (case M-RS2 then (if (eq (sub-string 2 2 ?complexity) (sub-string 6 6 ?next_step)) then (modify ?order_s (next_step CAP)) else (switch (sub-string 2 2 ?complexity) (case 1  then (modify ?order_s (next_step RING_2)))
                                                    (case 2  then (modify ?order_s (next_step RING_2)))))) ;TODO
                            (case M-CS1 then (modify ?order_s (next_step DELIVER)))
                            (case M-CS2 then (modify ?order_s (next_step DELIVER)))
                            (case M-DS then (modify ?order_s (next_step NONE)))
                            )
                            (modify ?order_s (state ?pos))
                        )

                )     
        )
        (modify ?robo_s (task 0))
        (assert (request_task (id ?id) (last_task ?robo_task) (robo_order ?robo_order)(machine_order ?m_order)))

        ;(assert (done (done_t_id ?task))) still needed?
        ;(printout green "TASK DONE"  crlf)
        ;else
        ;    (printout green ?robo_id ?task_id ?success  crlf)
        ;    (printout green ?id ?t-id  crlf)
        )
    )



(defrule ringstation_update
?update <- (update_rs (id ?RS_id) (payment ?pay))
?rs1 <- (machine_status (name M-RS1) (slide_shelf ?pay_rs1))
?rs2 <- (machine_status (name M-RS2) (slide_shelf ?pay_rs2))
=>
    (retract ?update)
    (if (eq ?RS_id 1)
        then
            (modify ?rs1 (slide_shelf (+ ?pay_rs1 ?pay)))
        else
            (modify ?rs2 (slide_shelf (+ ?pay_rs2 ?pay)))
    )
    
)

(defrule perprocess_ring_colors
?prp_r_c <- (perprocess_ring_colors (id ?id) (rings ?ring1 $?rings_rest) (it ?it))
?order_c <- (order_colors (id ?id))
=>
(switch ?it
    (case 1 then
        (modify ?order_c (ring_1 ?ring1))
        (assert (perprocess_ring_colors (id ?id) (rings $?rings_rest) (it (+ ?it 1))))
    )
    (case 2 then
        (modify ?order_c (ring_2 ?ring1))
        (assert (perprocess_ring_colors (id ?id) (rings $?rings_rest) (it (+ ?it 1))))
    )
    (case 3 then
        (modify ?order_c (ring_3 ?ring1))
    )
)
)

(defrule procces_new_order
?new_o <- (newOrder (id ?id))
(order (id ?id)(complexity ?complexity)(delivery-begin ?begin)(delivery-end ?end) (base-color ?base) (ring-colors $?ring-colors) (cap-color ?cap))
(test (or (eq ?id 1) (eq ?id 2))); zwishcen Lösung, betrachte nur orders 1 und 2 !!!! UPDATE WHEN THAT IS RUNING
(not (processed_order (id ?p_id&: (eq ?p_id ?id)))); (prio ?prio_1&:(< ?hp_prio ?prio_1))
=>
(retract ?new_o)
(assert (processed_order (id ?id)))
(assert (order_status (id ?id) (state RC) (next_step BASE) (complexity ?complexity) (start_d_time ?begin) (last_d_time ?end) (prio (- 100 ?id))))
(assert (order_colors (id ?id) (base ?base) (cap ?cap)))
(if (not (eq ?complexity C0))
 then 
 (assert (perprocess_ring_colors (id ?id) (rings $?ring-colors) (it 1)))
)
)


(deffunction oneof (?v $?values) ;taken from https://stackoverflow.com/questions/64005026/the-switch-function-in-clips
   (if (member$ ?v ?values)
      then ?v
      else (not ?v)))

(defrule request_task
?rt <- (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)) ;(machine_order ?last_machine_order)
?lc <- (last_checked (id ?robo_id) (c_time ?check_time))
(time ?ros-time-float)
(test (> (- ?ros-time-float ?check_time) 1))
?init_it <- (init_it (id ?robo_id) (iteration ?it))
?hp_o <- (order_status (id ?hp_oid) (state ?hp_ostate&:(not (eq ?hp_ostate DE))) (next_step ?hp_next) (start_d_time ?hp_start) (last_d_time ?hp_last) (prio ?hp_prio) (complexity ?hp_compex));order with highest prio
(not (order_status (prio ?prio_1&:(< ?hp_prio ?prio_1)) (state ?hp_ostate1&:(not (eq ?hp_ostate1 DE))) )) ;; find order with highest prio
;(test (not (eq ?hp_ostate DE)));wird zu gut beachtet
(order (id ?hp_oid) (base-color ?hp_base) (ring-colors $?hp_colors) (cap-color ?hp_cap))
;?hid_o <- (order_status (id ?hid_oid) (state ?hid_ostate) (prio ?hid_prio) (complexity ?hid_compex));order with highest id
;(not (order_status (id ?id_1&:(< ?hid_oid ?id_1))))
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order) (pos ?m_pos))
?robo_s <- (robo_status (id ?robo_id) (task ?r_task) (order ?r_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des))
(test (or (eq ?m_name ?pos) (eq ?m_name ?des) (eq ?pos START)))
;(test (or (not (and (eq ?m_name ?pos) (eq ?m_pos OUTPUT))) (and (eq ?pos_wp OUTPUT) (eq ?m_name ?pos)))) ;robo not at a output, but if the coresponding machine is ready;;;;error weil worng match.... seach for differet solution
?r_o <-(order_status (id ?last_robo_order) (state ?r_ostate) (next_step ?r_next) (next_color ?r_next_c))
?r_order_colors <- (order_colors (id ?last_robo_order) (base ?r_order_base) (ring_1 ?r_order_r1) (ring_2 ?r_order_r2) (ring_3 ?r_order_r3) (cap ?r_order_cap))
?m_o <-(order_status (id ?last_machine_order)(state ?m_ostate) (next_step ?m_next)(next_color ?m_next_c))
?m_order_colors <- (order_colors (id ?last_machine_order) (base ?m_order_base) (ring_1 ?m_order_r1) (ring_2 ?m_order_r2) (ring_3 ?m_order_r3) (cap ?m_order_cap))
=>
(retract ?rt)
(if (< ?it 8); (eq ?hid_oid 42);init
    then
    (switch ?robo_id
     (case 1 then
        (if (eq ?it 1)
            then
                (assert (instruct (machine M-BS) (operation OUTPUT) (color ?hp_base) (task_id  1) (order_id ?hp_oid)))
                (assert (action (a_type "m") (id 1) (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?init_it (iteration 8))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-BS) (des_at_waypoint OUTPUT) (order ?hp_oid))
                (modify ?hp_o (state BS))
                (if (eq ?hp_compex C0) then (modify ?hp_o (next_step CAP)) else (modify ?hp_o (next_step RING_1)))
                ;(if (not (eq ?m_order_r1 EMPTY)) ;richtig gematchedt? nur weil init?
                ; then (modify ?hp_o (next_step RING_1) (next_color ?m_order_r1))
                ; else
                ; (modify ?hp_o (next_step CAP) (next_color ?m_order_cap))
                ;)
        )
     )
     (case (oneof ?robo_id 2 3) then ;;TODO schöner frage Tarki
        (switch ?it
            (case 1 then
            (bind ?station-free (do-for-fact ((?cs station-free))
                (eq ?cs:name (sym-cat (str-cat "M-CS" (- ?robo_id 1))))                            
                    (assert (action (a_type "m") (id ?robo_id) (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io INPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (des_at_waypoint INPUT))
                    (modify ?init_it (iteration (+ ?it 1)))
                    (retract ?cs)
                                )
                    )
                        ;(if (eq station-free FALSE)
                        ;   then
                        ;   (modify ?lc (c_time ?ros-time-float))
                        ;   (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                        ;)    
                
            )
            (case 2 then
                (assert (action (id ?robo_id) (a_type "r") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io SHELF) (task_id (+ ?last_robo_task 1)))) ;action unify
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?init_it (iteration (+ ?it 1)))
            )
            (case 3 then
                (assert (action (id ?robo_id) (a_type "d") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io INPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?init_it (iteration (+ ?it 1)))
            )
            (case 4 then
                (assert (instruct (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (operation RETRIEVE_CAP) (task_id  1)));needs finish of robo - easy do together with next m
                (modify ?machine_s (task 1))
                (assert (action (id ?robo_id) (a_type "m") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (des_at_waypoint OUTPUT))
                (modify ?init_it (iteration (+ ?it 1)))
            )
            (case 5 then
                (if (and (eq ?m_task 0) (eq ?m_pos OUTPUT))
                    then
                    ;FAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                        (assert (action (id ?robo_id) (a_type "r") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io OUTPUT) (task_id (+ ?last_robo_task 1))));needs finish of machine - if machine status task 0 pos out for the machine the robo is sanding
                        (modify ?robo_s (task (+ ?last_robo_task 1)))
                        (modify ?init_it (iteration (+ ?it 1)))
                    else
                        (modify ?init_it (iteration 5)) ; loop untill if true
                        (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order)))
                )
            )
            (case 6 then
                (assert (action (id ?robo_id) (a_type "m") (machine (sym-cat (str-cat "M-RS" (- ?robo_id 1)))) (io INPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des (sym-cat (str-cat "M-RS" (- ?robo_id 1)))) (des_at_waypoint INPUT))
                (modify ?init_it (iteration (+ ?it 1)))
                (assert (station-free (name ?pos)))

            )
            (case 7 then
                (assert (action (id ?robo_id) (a_type "d") (machine (sym-cat (str-cat "M-RS" (- ?robo_id 1)))) (io SLIDE) (task_id (+ ?last_robo_task 1))))
                (modify ?init_it (iteration (+ ?it 1)))
            )
        )
     )  
        
    )

    else
    (switch ?robo_id
        (case 1 then
            (if (and (eq ?m_task 0) (eq ?m_pos OUTPUT)); machine ready
            then
                (if (eq ?r_task 0) ; robo has no order
                then
                    (assert (action (id ?robo_id) (a_type "r") (machine ?m_name) (io OUTPUT) (task_id (+ ?last_robo_task 1))));needs finish of machine - if machine status task 0 pos out for the machine the robo is sanding
                    (modify ?robo_s (task (+ ?last_robo_task 1))(order 0))
                   
                )
            else
                (if (and (eq ?r_order 0) (eq ?m_pos INPUT)) ;robo ready but machitne not
                then
                    (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order)))

                else ;machine not ready (anymore) - robo has retrived
                    (if (eq ?hp_ostate RC)
                        then 
                            (assert (instruct (machine M-BS) (operation OUTPUT) (color ?hp_base) (task_id  1) (order_id ?hp_oid)))
                            (assert (action (id ?robo_id) (a_type "m") (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                            (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-BS) (des_at_waypoint OUTPUT) (order ?hp_oid))
                            (modify ?hp_o (state BS))
                            (if (eq ?hp_compex C0) then (modify ?hp_o (next_step DELIVER)) else (modify ?hp_o (next_step RING_1)))

                        else
                        (if (and (eq ?pos_wp OUTPUT) (not (eq ?last_machine_order 0))) ;target decition not succesfull TODO maybe wrongly set line 175
                        then
                            (if (or (eq ?m_next RING_1) (eq ?m_next RING_2) (eq ?m_next RING_3))
                            then
                                (if (or (eq ?m_next_c RING_ORANGE) (eq ?m_next_c RING_GREEN))
                                 then
                                    (assert (action (id ?robo_id) (a_type "m") (machine M-RS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-RS1) (des_at_waypoint INPUT))
                                else 
                                    (assert (action (id ?robo_id) (a_type "m") (machine M-RS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-RS2) (des_at_waypoint INPUT))
                                )
                            else ;next is cap or deliver
                                (if (eq ?m_next DELIVER)
                                    then
                                        (assert (action (id ?robo_id) (a_type "m") (machine M-DS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                        (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-DS) (des_at_waypoint INPUT))
                                        (assert (station-free (name ?pos)))
                                    else

                                            
                                                    (if (eq ?m_next_c CAP_GREY)
                                                    then
                                                        (bind ?station-free (do-for-fact ((?cs station-free))
                                                                    (eq ?cs:name M-CS1)
                                                        (assert (action (id ?robo_id) (a_type "m") (machine M-CS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                                        (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS1) (des_at_waypoint INPUT))
                                                        (retract ?cs)

                                                        ))
                                                    else 
                                                        (bind ?station-free (do-for-fact ((?cs station-free))
                                                                    (eq ?cs:name M-CS2)
                                                                        (assert (action (id ?robo_id) (a_type "m") (machine M-CS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                                                        (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS2) (des_at_waypoint INPUT))
                                                                        (retract ?cs)
                                                                        ))
                                        )
                                                            
                                        

                                         (if (eq ?station-free FALSE)
                                            then
                                                (modify ?lc (c_time ?ros-time-float))
                                                (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                                        ) 

                                        
                                )
                                
                            )
                        else ;deliver then drive to out
                            (if (> ?r_order 0)
                            then
                            (assert (action (id ?robo_id) (a_type "d") (machine ?pos) (io INPUT) (task_id (+ ?last_robo_task 1))))
                            (modify ?robo_s (task (+ ?last_robo_task 1)))
                            ;(printout green "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" crlf);Deliver a
                            else
                            (if(or (eq ?pos M-RS1) (eq ?pos M-RS2))
                                then
                                    (assert (instruct (machine ?pos) (operation RING) (color ?r_next_c) (task_id 42) (order_id ?m_order)))
                                else ;CS or DS
                                    (if(eq ?pos M-DS)
                                    then
                                    (assert (instruct (machine M-DS) (operation DELIVER) (task_id 42) (order_id ?m_order)))
                                    (modify ?hp_o (state DE))
                                    (assert (request_task (id ?robo_id) (last_task (+ ?last_robo_task 1)) (robo_order ?last_robo_order) (machine_order ?last_machine_order)));new untestet
                                    else
                                    (assert (instruct (machine ?pos) (operation MOUNT_CAP) (task_id  42) (order_id ?m_order)))
                                    )
  
                            ) 
                            ;;needs finish of robo - easy do together with next m
                            (if (not (eq ?pos M-DS))
                            then 
                            (assert (action (id ?robo_id) (a_type "m") (machine ?pos) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                            (modify ?robo_s (task (+ ?last_robo_task 1)) (des ?pos) (des_at_waypoint OUTPUT));(order ?m_order)
                            ;(printout green "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB" crlf);instruct! (implement payment check in machine instruct DONE) and move to out
                            ;else ;was delivery
                            ;(assert (instruct (machine M-BS) (operation OUTPUT) (color ?hp_base) (task_id  1) (order_id ?hp_oid)))
                            ;(assert (action (id ?robo_id) (a_type "m") (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                            ;(modify ?robo_s (task (+ ?last_robo_task 1)) (des M-BS) (des_at_waypoint OUTPUT))
                            ;(if (eq ?hp_compex C0) then (modify ?hp_o (next_step DELIVER)) else (modify ?hp_o (next_step RING_1)))

                            )
                            )
                        
                    
                        )

                    )
                )

            )
        )
        (case 2 then

            ;if CS1 not prepared and and empty prepare CS1 to RS1 if <3 else to DS
            ;if CS2 not prepared and and empty prepare CS2 to RS2 if <3 else to DS
            ;if RS1 <2 from BS to RS (check if R1 blocks BS)


        )
            ;case 3             ;if RS2 <2 from BS to RS (check if R1 blocks BS)

        )

    ;else ;init done
    ;switch by robot seee notes
    )
    ;assigning new tasks to robos
    ;handeling priority
    ;staring (restricted) machine instruction when robo deliver
    ;in machine_instruct add payment check for RS - sollte to test. sonst 2 regeln
    )


(defrule complete_init
    (init_it (id 1) (iteration 8))
    (init_it (id 2) (iteration 8))
    (init_it (id 3) (iteration 8))
    ?o_state <- (order_status (id 42) (state ?order_s))
    (test (not (eq ?order_s DE)))
=>
    ;(modify ?o_state (state DONE))
    (retract ?o_state)
)

