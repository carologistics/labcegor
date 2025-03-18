(defrule init_all
(init_moves)
=>
    (assert (order_status (id 0) (prio 0)))
    (assert (order_status (id 42) (prio 0)))
    (assert (order_status (id 40) (state NONE) (prio 0) (complexity C0)))
    (assert (init_it (id 1) (iteration 1)))
    (assert (init_it (id 2) (iteration 1)))
    (assert (init_it (id 3) (iteration 1)))
    (assert (request_task (id 3) (last_task 3000)))
    (assert (request_task (id 2) (last_task 2000)))
    (assert (request_task (id 1) (last_task 1000)))
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
    ?order_s <- (order_status (id ?order_oid) (state ?order_state) (complexity ?complexity))
    (test (or (eq ?robo_order 0) (eq ?robo_order 40) (eq ?robo_order ?order_oid)))
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
                        ;update order status
                
                    else ; was deliver        
                        (modify ?machine_s (order ?robo_order))
                        (modify ?robo_s (order 0))
                        (modify ?order_s (state ?pos))
                        (switch ?pos  ;Update next step
                            (case M-BS then (if (eq ?complexity C0) then (modify ?order_s (next_step DELIVER)) else (modify ?order_s (next_step RING_1))))
                            (case M-RS1 then (if (eq ?complexity C1) then (modify ?order_s (next_step DELIVER)) else (modify ?order_s (next_step RING_2))))
                            (case M-RS2 then (if (eq ?complexity C2) then (modify ?order_s (next_step DELIVER)) else (modify ?order_s (next_step RING_3))))
                            (case M-CS1 then (modify ?order_s (next_step DELIVER)))
                            (case M-CS2 then (modify ?order_s (next_step DELIVER)))
                            (case M-DS then (modify ?order_s (next_step NONE)))

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
(order (id ?id)(complexity ?complexity)(delivery-begin ?begin)(delivery-end ?end) (base-color ?base) (ring-colors ?ring-colors) (cap-color ?cap))
(test (or (eq ?id 1) (eq ?id 0))); zwishcen Lösung, betrachte nur orders 1 und 2 !!!! UPDATE WHEN THAT IS RUNING
(not (processed_order (id ?id)))
=>
(retract ?new_o)
(assert (processed_order (id ?id)))
(assert (order_status (id ?id) (state RC) (next_step BASE) (complexity ?complexity) (start_d_time ?begin) (last_d_time ?end) (prio (- 100 ?id))))
(assert (order_colors (id ?id) (base ?base) (cap ?cap)))
(if (not (eq ?complexity C0))
 then 
 (assert (perprocess_ring_colors (id ?id) (rings ?ring-colors) (it 1)))
)
)


(deffunction oneof (?v $?values) ;taken from https://stackoverflow.com/questions/64005026/the-switch-function-in-clips
   (if (member$ ?v ?values)
      then ?v
      else (not ?v)))

(defrule request_task
?rt <- (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order)) ;(machine_order ?last_machine_order)
?init_it <- (init_it (id ?robo_id) (iteration ?it))
;(test (<= ?it 7))
;(not (newOrder)) ;;think of new check
?hp_o <- (order_status (id ?hp_oid)(state ?hp_ostate) (next_step ?hp_next) (start_d_time ?hp_start) (last_d_time ?hp_last) (prio ?hp_prio));order with highest prio
(not (order_status (prio ?prio_1&:(< ?hp_prio ?prio_1)))) ;; find order with highest prio
(order (id ?hp_oid) (base-color ?hp_base) (ring-colors $?hp_colors) (cap-color ?hp_cap))
?hid_o <- (order_status (id ?hid_oid) (state ?hid_ostate) (prio ?hid_prio));order with highest id
(not (order_status (id ?id_1&:(< ?hid_oid ?id_1))))
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (pos ?m_pos))
?robo_s <- (robo_status (id ?robo_id) (task ?r_task) (order ?r_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des))
(test (or (eq ?m_name ?pos) (eq ?m_name ?des) (eq ?pos START)))
;(test (or (not (and (eq ?m_name ?pos) (eq ?m_pos OUTPUT))) (and (eq ?pos_wp OUTPUT) (eq ?m_name ?pos)))) ;robo not at a output, but if the coresponding machine is ready;;;;error weil worng match.... seach for differet solution
?r_o <-(order_status (id ?last_robo_order) (state ?r_ostate) (next_step ?r_next))
?order_colors <- (order_colors (id ?last_robo_order) (base ?order_base) (ring_1 ?order_r1) (ring_2 ?order_r2) (ring_3 ?order_r2) (cap ?order_cap))
;?m_o <-(order_status (id ?last_machine_order)(state ?m_ostate) (next_step ?m_next) (start_d_time ?m_start) (last_d_time ?m_last) (prio ?m_prio))
=>
(retract ?rt)
(if (< ?it 8); (eq ?hid_oid 42);init
    then
    (switch ?robo_id
     (case 1 then
        (if (eq ?it 1)
            then
                (assert (instruct (machine M-BS) (operation OUTPUT) (color ?hp_base) (task_id  1) (oder_id ?hp_oid)));;adapt to order
                (assert (action (a_type "m") (id 1) (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?init_it (iteration 8))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-BS) (des_at_waypoint OUTPUT) (order ?hp_oid))
                (if (not (eq ring_1 empty)) 
                 then (modify ?hp_o (next_step RING_1))
                 else
                 (modify ?hp_o (next_step CAP))
                )
        )
     )
     (case (oneof ?robo_id 2 3) then ;;TODO schöner frage Tarki
        (switch ?it
            (case 1 then
                (assert (action (a_type "m") (id ?robo_id) (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io INPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (des_at_waypoint INPUT))
                (modify ?init_it (iteration (+ ?it 1)))
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
                    (modify ?robo_s (task (+ ?last_robo_task 1)))
                )
            else
                (if (eq ?r_task 0) ;robo ready but machitne not
                then
                    (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order)))

                else ;machine not ready (anymore) - robo has retrived
                    (if (eq ?r_ostate DONE)
                        then 
                        ;grab new order (TODO)
                        else
                        (if (and (eq ?pos OUTPUT) (not (eq ?last_robo_order 0)))
                        then
                            (assert (action (id ?robo_id) (a_type "m") (machine M-DS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                            (modify ?robo_s (task (+ ?last_robo_task 1)))
                        )
                        ;finish current order

                    )
                )

            )
        )
        (case 2 then
            ;noop
        )

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
    (test (not (eq ?order_s DONE)))
=>
    ;(modify ?o_state (state DONE))
    (retract ?o_state)
)

