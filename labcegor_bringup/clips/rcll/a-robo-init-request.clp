(defrule init_all
(init_moves)
=>
    (assert (order_status (id 42)))
    (assert (init_it (id 1) (iteration 1)))
    (assert (init_it (id 2) (iteration 1)))
    (assert (init_it (id 3) (iteration 1)))
    (assert (request_task (id 3) (last_task 3000)))
    (assert (request_task (id 2) (last_task 2000)))
    (assert (request_task (id 1) (last_task 1000)))
)

(defrule waitforfinish_robo
    ;?d <- (do (id ?id) (task ?t-id))
    ;?b <- (robo_busy (id ?id))
    ?robo_s <- (robo_status (id ?id) (task ?robo_task) (order ?robo_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des) (des_at_waypoint ?des_wp))
    (test (< ?robo_task 0)) ;; busy check
    ?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order))
    ?order_s <- (order_status (id ?robo_order) (state ?order_state))
    (protobuf-msg (type "llsf_msgs.AgentTask") (msg-type ?msg-type) (client-type PEER) (ptr ?msg))
=>
    (bind ?robo_id (pb-field-value ?msg "robot_id"))
    (bind ?task_id (pb-field-value ?msg "task_id"))
    (bind ?success (pb-field-value ?msg "successful"))
    (if (and (eq ?robo_id ?id) (eq ?success TRUE)) ;(eq ?task_id ?t-id)
    then
        ;(retract ?d)
        ;(retract ?b)
        ;(assert (done (done_t_id ?t-id)))
        (if (not (eq ?des ""));; aka was movment
            then
                (modify ?robo_s (pos ?des) (pos_at_waypoint ?des_wp) (des EMPTY) (des_at_waypoint EMPTY)) ;pos = des; pos_wp =des_wp, des, des_wp = ""
            else ; NO MOVEMENT
                (if (eq ?robo_order 0);; aka was retrive
                    then
                        (modify ?robo_s (order ?m_order))
                        (modify ?machine_s (order 0))
                        ;update order status
                
                    else ; was deliver        
                        (modify ?machine_s (order ?robo_order))
                        (modify ?robo_s (order 0))
                        (modify ?order_s (state ?pos))

                )     
        )
        (assert (request_task (id ?id) (last_task ?robo_task) (robo_order ?robo_order)(machine_order ?m_order)))

        ;(assert (done (done_t_id ?task))) still needed?
        ;(printout green "TASK DONE"  crlf)
        ;else
        ;    (printout green ?robo_id ?task_id ?success  crlf)
        ;    (printout green ?id ?t-id  crlf)
        )
    )


(defrule ringstation_update
(update_rs (id ?RS_id) (payment ?pay))
?rs1 <- (machine_status (name M-RS1) (slide_shelf ?pay_rs1))
?rs2 <- (machine_status (name M-RS2) (slide_shelf ?pay_rs2))
=>
    (if (eq ?RS_id 1)
        then
            (modify ?rs1 (slide_shelf (+ ?pay_rs1 ?pay)))
        else
            (modify ?rs2 (slide_shelf (+ ?pay_rs2 ?pay)))

    )
)

(defrule request_task
(request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order)) ;(machine_order ?last_machine_order)
?init_it <- (init_it (id ?robo_id) (iteration ?it))
(test (<= ?it 7))
;?hp_o <- (order_status (id ?hp_oid)(state ?hp_ostate) (next_step ?hp_next) (start_d_time ?hp_start) (last_d_time ?hp_last) (prio ?hp_prio));order with highest prio
?hid_o <- (order_status (id ?hid_oid) (state ?hid_ostate) (next_step ?hid_next) (start_d_time ?hid_start) (last_d_time ?hid_last) (prio ?hid_prio));order with highest id
(not (order_status (id ?id_1&:(< ?hid_oid ?id_1))))
;?r_o <-(order_status (id ?last_robo_order)(state ?r_ostate) (next_step ?r_next) (start_d_time ?r_start) (last_d_time ?r_last) (prio ?r_prio))
;?m_o <-(order_status (id ?last_machine_order)(state ?m_ostate) (next_step ?m_next) (start_d_time ?m_start) (last_d_time ?m_last) (prio ?m_prio))
(machine_status (name M-CS1) (task ?m_task) (pos ?m_pos))
=>
(if (eq ?hid_oid 42)
    then
    (switch ?robo_id
     (case 1 then
        if (eq ?it 1)
            then
                (assert (action (a_type "m") (id 1) (machine M-BS) (io input) (task_id (+ ?last_robo_task 1))))
                (modify ?init_it (iteration 7))
     )
     (case 2 then
        (assert (action (a_type "m") (id 2) (machine M-CS2) (io input) (task_id (+ ?last_robo_task 1))))
        ;(instruct )
     )
     (case 3 then
        (switch ?it
            (case 1
                (assert (action (a_type "m") (id 3) (machine M-CS1) (io input) (task_id (+ ?last_robo_task 1))))
            )
            (case 2
                (assert (action (id 3) (a_type "r") (machine M-CS1) (io left) (task_id (+ ?last_robo_task 1)))) ;action unify

            )
            (case 3
                (assert (action (id 3) (a_type "d") (machine M-CS1) (io input) (task_id (+ ?last_robo_task 1))))
            )
            (case 4
                (assert (instruct (machine M-CS1) (operation RETRIEVE_CAP) (task_id  1)));needs finish of robo - easy do together with next m
                (assert (action (id 3) (a_type "m") (machine M-CS1) (io output) (task_id (+ ?last_robo_task 1))))
            )
            (case 5
                (if (and (eq ?m_task 0) (eq ?m_pos output))
                    then
                        (assert (action (id 3) (a_type "r") (machine M-CS1) (io output) (task_id (+ ?last_robo_task 1))));needs finish of machine - if machine status task 0 pos out for the machine the robo is sanding
                    else
                        (modify ?init_it (iteration (- ?it 1)))
                )
            )
            (case 6
                (assert (action (id 3) (a_type "m") (machine M-RS1) (io input) (task_id (+ ?last_robo_task 1))))
            )
            (case 7
                (assert (action (id 3) (a_type "d") (machine M-RS1) (io slide) (task_id (+ ?last_robo_task 1))))
            )
        
        )
        
        
     )
     (modify ?init-it (iteration (+ ?it 1)))
    ) 

)
    ;(if ) order 42 not done do init else...
    ;init
    ;assigning new tasks to robos
    ;handeling priority
    ;staring (restricted) machine instruction when robo deliver
)


(defrule procces_new_order
(new order)
    ;(order )
=>
    
)