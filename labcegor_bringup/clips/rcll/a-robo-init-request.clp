(defrule init_all
(init_moves)
=>
    (assert (order_status (id 42)))
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
    (if (and (eq ?robo_id ?id) (eq ?task_id ?t-id) (eq ?success TRUE))
    then
        ;(retract ?d)
        ;(retract ?b)
        ;(assert (done (done_t_id ?t-id)))
        (if (not (eq ?des ""));; aka was movment
            then
                (modify ?robo_s (?pos ?des) (?pos_wp ?des_wp) (?des "") (?des_wp "")) ;pos = des; pos_wp =des_wp, des, des_wp = ""
            else ; NO MOVEMENT
                (if (eq ?robo_order 0);; aka was retrive
                    then
;;                        (modify ?robo_s (?robo_order ?m_order))
;;                        (modify ?machine_s (?machine_order 0))
                        ;update order status
                
                    else ; was deliver        
;;                        (modify ?machine_s (?m_order ?robo_order))
;;                        (modify ?robo_s (?robo_order 0))
;;                        (modify ?order_s (?order_state (?pos)))

                )     
        )
        (assert (request_task (id ?id) (last_task ?robo_task) (robo_order ?robo_order)(m_order ?m_order)))

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
(request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order))
;?hp_o <- (order_state (id ?hp_oid)(order_state ?hp_ostate) (next_step ?hp_next) (start_d_time ?hp_start) (last_d_time ?hp_last) (prio ?hp_prio));order with highest prio
?hid_o <- (order_state (id ?hid_oid) (order_state ?hid_ostate) (next_step ?hid_next) (start_d_time ?hid_start) (last_d_time ?hid_last) (prio ?hid_prio));order with highest id
(not (order_state(id ?id_1)))
(not (and (order_satus (id ?oid&:(> ?hid_oid ?id_1)))
    (not (order_status (id ?hid_oid))))
)
?r_o <-(order_state (id ?last_robo_order)(order_state ?r_ostate) (next_step ?r_next) (start_d_time ?r_start) (last_d_time ?r_last) (prio ?r_prio))
?m_o <-(order_state (id ?last_machine_order)(order_state ?m_ostate) (next_step ?m_next) (start_d_time ?m_start) (last_d_time ?m_last) (prio ?m_prio))
=>    
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