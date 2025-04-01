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
    (assert (cs_it (id 2) (iteration 1)))
    (assert (pay_it (id 3) (iteration 1)))
)

(defrule waitforfinish_machine ;reset machine Status after it has completet its instructed operation
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order) (pos ?m_pos))
(test (> ?m_task 0)) 
(machine (name ?m_name) (state ?m_state))
(test (or (eq ?m_state READY-AT-OUTPUT) (eq ?m_state PREPARED)))
=>
  (modify ?machine_s (task 0) (pos OUTPUT))
)

(defrule waitforfinish_robo
    ?robo_s <- (robo_status (id ?id) (task ?robo_task) (order ?robo_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des) (des_at_waypoint ?des_wp))
    (test (> ?robo_task 0)) ;busy check to minimize triggering - still because of successful check on RHS  triggert very often
    ?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order))
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
    (if (and (eq ?robo_id ?id) (eq ?task_id ?robo_task) (eq ?success TRUE)) ; detrmine last operation
    then
        (if (not (eq ?des EMPTY));was movment
            then
                (modify ?robo_s (pos ?des) (pos_at_waypoint ?des_wp) (des EMPTY) (des_at_waypoint EMPTY)) ;update current pos
            else ; NO MOVEMENT
                (if (eq ?robo_order 0); was retrive
                    then
                        (if (not (eq ?m_order 0))
                            then (modify ?robo_s (order ?m_order))
                            else (modify ?robo_s (order 40))
                        )
                        (modify ?machine_s (order 0))
                        (modify ?machine_s (pos empty))
                        (if (eq ?id 1) ;as next step was set when delivering next color can be calculated
                            then (switch ?m_next_step
                                (case RING_1 then (modify ?m_order_s (next_color ?order_r1)))
                                (case RING_2 then (modify ?m_order_s (next_color ?order_r2)))
                                (case RING_3 then (modify ?m_order_s (next_color ?order_r3)))
                                (case CAP then (modify ?m_order_s (next_color ?order_cap)))
                            )
                        )
                    else ;was deliver        
                        (modify ?machine_s (order ?robo_order) (task 42) )
                        (modify ?robo_s (order 0))

                        (if (eq ?id 1)
                            then (switch ?pos  ;Update next step when delivering
                            ;(case M-BS then )) - in request_task as never delivered to BS
                            (case M-RS1 then (if (eq (sub-string 2 2 ?complexity) (sub-string 6 6 ?next_step)) then (modify ?order_s (next_step CAP)) else (if (or (eq ?complexity C2) (eq ?next_step RING_1)) then (modify ?order_s (next_step RING_2)) else (modify ?order_s (next_step RING_3))))) ;TOtest
                            (case M-RS2 then (if (eq (sub-string 2 2 ?complexity) (sub-string 6 6 ?next_step)) then (modify ?order_s (next_step CAP)) else (if (or (eq ?complexity C2) (eq ?next_step RING_1)) then (modify ?order_s (next_step RING_2)) else (modify ?order_s (next_step RING_3))))) ;TOtest
                            (case M-CS1 then (modify ?order_s (next_step DELIVER)))
                            (case M-CS2 then (modify ?order_s (next_step DELIVER)))
                            (case M-DS then (modify ?order_s (next_step NONE)))
                            )
                            (modify ?order_s (state ?pos))
                        )
                )      
        )
        (modify ?robo_s (task 0)); reset robo in anycase
        (assert (request_task (id ?id) (last_task ?robo_task) (robo_order ?robo_order) (machine_order ?m_order))) ;ask for new task but pass last task number (to not double use one) as well as; last orders for robo and machine
        )
    )

(defrule ringstation_update ;payment/ringmounting
?update <- (update_rs (id ?RS_id) (payment ?pay)); trigger
?rs1 <- (machine_status (name M-RS1) (slide_shelf ?pay_rs1));always exsists
?rs2 <- (machine_status (name M-RS2) (slide_shelf ?pay_rs2));always exsists
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

(defrule procces_new_order ;when a new order is published
?new_o <- (newOrder (id ?id))
(order (id ?id)(complexity ?complexity)(delivery-begin ?begin)(delivery-end ?end) (base-color ?base) (ring-colors $?ring-colors) (cap-color ?cap))
(not (processed_order (id ?p_id&: (eq ?p_id ?id)))) ; and it's not alread processed
=>
(retract ?new_o)
(assert (processed_order (id ?id)))
;---removed to preven blocking DS when dilivery window is not reached jet
;(if(eq ?id 1);give order 1 a higher prio than order 2 
;then
;    (assert (order_status (id ?id) (state RC) (next_step BASE) (complexity ?complexity) (start_d_time ?begin) (last_d_time ?end) (prio (+ ?end 1)))); possibly overspecified some values currently not needed afterwards
;else
;    (assert (order_status (id ?id) (state RC) (next_step BASE) (complexity ?complexity) (start_d_time ?begin) (last_d_time ?end) (prio ?end)))
;)
(assert (order_status (id ?id) (state RC) (next_step BASE) (complexity ?complexity) (start_d_time ?begin) (last_d_time ?end) (prio (- 100 ?id)))); possibly overspecified, work orders in order of ids for now
(assert (order_colors (id ?id) (base ?base) (cap ?cap)))
(if (not (eq ?complexity C0)) ; if rings ar pressent same them in the corresponding color fact 
 then 
 (assert (perprocess_ring_colors (id ?id) (rings $?ring-colors) (it 1)))
)
)

(defrule free-bs ;wait for BS reset - free BS with time delay
?b-BS <- (block-bs (block_time ?bt))
(time ?ros-time-float)
(test (> (- ?ros-time-float ?bt) 5))
=>
(retract ?b-BS)
(assert(station-free (name M-BS)))
)


(deffunction oneof (?v $?values) ;taken from https://stackoverflow.com/questions/64005026/the-switch-function-in-clips
   (if (member$ ?v ?values)
      then ?v
      else (not ?v)))

(defrule request_task_main
?rt <- (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)) ;robo requesting a task
?lc <- (last_checked (id ?robo_id) (c_time ?check_time));backof-time check
(game-time ?game-time)
(time ?ros-time-float)
(test (> (- ?ros-time-float ?check_time) 1))
?init_it <- (init_it (id ?robo_id) (iteration ?it));initializaion itterations
(test (or (eq ?robo_id 1) (< ?it 8))); init passed or robo 1
?hp_o <- (order_status (id ?hp_oid) (state ?hp_ostate&:(not (eq ?hp_ostate DE))) (next_step ?hp_next) (start_d_time ?hp_start) (last_d_time ?hp_last) (prio ?hp_prio) (complexity ?hp_compex));order with highest prio again overspecified - not simplified to aviod unpredictable
; posssiblity to add a selection prefering orders with open time window low enougth &:(or (> (- ?hp_start ?game-time) 1) (eq ?hp_oid 1)) not working so fallback with dong orders in order
(not (order_status (prio ?prio_1&:(< ?hp_prio ?prio_1)) (state ?hp_ostate1&:(not (eq ?hp_ostate1 DE) )))) ;wich is not delivered jet
(order (id ?hp_oid) (base-color ?hp_base) (ring-colors $?hp_colors) (cap-color ?hp_cap)) ;corresponding order fact - lagecy possible intercangable with order_color
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order) (pos ?m_pos)) ;machine robo is or wants to go
?robo_s <- (robo_status (id ?robo_id) (task ?r_task) (order ?r_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des))
(test (or (eq ?m_name ?pos) (eq ?m_name ?des) (eq ?pos START)))
?r_o <-(order_status (id ?last_robo_order) (state ?r_ostate) (next_step ?r_next) (next_color ?r_next_c)) ;order information on the order the robo holds or 0 (after delivery)
?r_order_colors <- (order_colors (id ?last_robo_order) (base ?r_order_base) (ring_1 ?r_order_r1) (ring_2 ?r_order_r2) (ring_3 ?r_order_r3) (cap ?r_order_cap))
?m_o <-(order_status (id ?last_machine_order)(state ?m_ostate) (next_step ?m_next)(next_color ?m_next_c)) ;order information on the order the machine has lastly procesed or 0 (after retrive)
?m_order_colors <- (order_colors (id ?last_machine_order) (base ?m_order_base) (ring_1 ?m_order_r1) (ring_2 ?m_order_r2) (ring_3 ?m_order_r3) (cap ?m_order_cap))
=>
(retract ?rt)
(if (< ?it 8); init
    then
    (switch ?robo_id
     (case 1 then
        (if (eq ?it 1)
            then
            (bind ?station-free (do-for-fact ((?station station-free)) ;R1 to BS and get Base for first order
                (eq ?station:name M-BS)  
                (assert (instruct (machine M-BS) (operation OUTPUT) (color ?hp_base) (task_id  1) (order_id ?hp_oid)))
                (assert (action (a_type "m") (id 1) (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?init_it (iteration 8)); ste init for R1 to be done
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-BS) (des_at_waypoint OUTPUT) (order ?hp_oid))
                (modify ?hp_o (state BS))
                (if (eq ?hp_compex C0) then (modify ?hp_o (next_step CAP)) else (modify ?hp_o (next_step RING_1)))
                (retract ?station)
            ))
            (if (eq ?station-free FALSE)
                then
                (modify ?lc (c_time ?ros-time-float))
                (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))               
            )         

        )
     )
     (case (oneof ?robo_id 2 3) then ;init R2 and R3 - prepare one CS each and deliver clear base to RS
        (switch ?it
            (case 1 then
            (bind ?station-free (do-for-fact ((?station station-free))
                (eq ?station:name (sym-cat (str-cat "M-CS" (- ?robo_id 1))))                            
                    (assert (action (a_type "m") (id ?robo_id) (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io INPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (des_at_waypoint INPUT))
                    (modify ?init_it (iteration (+ ?it 1)))
                    (retract ?station)
                                )
            )
            ;retry not needed as station free anyway  
            )
            (case 2 then
                (assert (action (id ?robo_id) (a_type "r") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io SHELF) (task_id (+ ?last_robo_task 1)))) 
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?init_it (iteration (+ ?it 1)))
            )
            (case 3 then
                (assert (action (id ?robo_id) (a_type "d") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io INPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?init_it (iteration (+ ?it 1)))
            )
            (case 4 then
                (assert (instruct (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (operation RETRIEVE_CAP) (task_id  1)))
                (modify ?machine_s (task 1))
                (assert (action (id ?robo_id) (a_type "m") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (des_at_waypoint OUTPUT))
                (modify ?init_it (iteration (+ ?it 1)))
            )
            (case 5 then
                (if (and (eq ?m_task 0) (eq ?m_pos OUTPUT)) ;iff machine has processed Cap, else back-off and request new task again
                    then
                        (assert (action (id ?robo_id) (a_type "r") (machine (sym-cat (str-cat "M-CS" (- ?robo_id 1)))) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)))
                        (modify ?init_it (iteration (+ ?it 1)))
                    else
                        (modify ?lc (c_time ?ros-time-float))
                        (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order)))
                )
            )
            (case 6 then
                (bind ?station-free (do-for-fact ((?station station-free))
                    (eq ?station:name (sym-cat (str-cat "M-RS" (- ?robo_id 1))))
                    (assert (action (id ?robo_id) (a_type "m") (machine (sym-cat (str-cat "M-RS" (- ?robo_id 1)))) (io INPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des (sym-cat (str-cat "M-RS" (- ?robo_id 1)))) (des_at_waypoint INPUT))
                    (modify ?init_it (iteration (+ ?it 1)))
                    (assert (station-free (name ?pos)))
                    (retract ?station)
                                )
                )
                (if (eq ?station-free FALSE); needed as could be alreay blocked by R1
                then
                    (modify ?lc (c_time ?ros-time-float))
                    (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                )    
            )
            (case 7 then
                (assert (action (id ?robo_id) (a_type "d") (machine (sym-cat (str-cat "M-RS" (- ?robo_id 1)))) (io SLIDE) (task_id (+ ?last_robo_task 1))))
                (modify ?init_it (iteration (+ ?it 1)))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
            )
        )
     )  
    )

    else
    (switch ?robo_id ;init done now only R1 acts in this function
        (case 1 then
            (if (and (eq ?m_task 0) (eq ?m_pos OUTPUT) (not (eq ?pos M-DS))); machine ready and is not DS
            then
                (if (eq ?r_task 0) ; robo has no order ready and has no order in hands - aka just moved to out
                then
                    (assert (action (id ?robo_id) (a_type "r") (machine ?m_name) (io OUTPUT) (task_id (+ ?last_robo_task 1)))) ;then retrive
                    (modify ?robo_s (task (+ ?last_robo_task 1))(order 0))
                )
            else
                (if (and (eq ?r_order 0) (eq ?m_pos INPUT)) ;robo ready but machitne not ready jet- back off and request again
                then
                    (modify ?lc (c_time ?ros-time-float))
                    (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order)))

                else ;machine not ready (anymore) - robo has retrived
                    (if (and (eq ?hp_ostate RC) (eq ?r_ostate DE));last delivered order to DS and exists order with highest prio.
                        then 
                        (bind ?station-free (do-for-fact ((?station station-free)) ;start this order and proced as before
                            (eq ?station:name M-BS)
                            (retract ?station)  
                            (assert (instruct (machine M-BS) (operation OUTPUT) (color ?hp_base) (task_id 1) (order_id ?hp_oid)))
                            (assert (action (id 1) (a_type "m") (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                            (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-BS) (des_at_waypoint OUTPUT) (order ?hp_oid))
                            (modify ?hp_o (state BS))
                            (if (eq ?hp_compex C0) then (modify ?hp_o (next_step CAP)) else (modify ?hp_o (next_step RING_1)))
                            (assert (station-free (name M-DS)))
                                        )
                        )
                        (if (eq ?station-free FALSE)
                            then
                                (modify ?lc (c_time ?ros-time-float))
                                (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                        )  

                        else
                        (if (and (eq ?pos_wp OUTPUT) (not (eq ?last_machine_order 0))); last action was retrive -determine next location to move to - and may back-off before doing so
                        then
                            (if (or (eq ?m_next RING_1) (eq ?m_next RING_2) (eq ?m_next RING_3)) ; next step is ring
                            then
                                (if (or (eq ?m_next_c RING_ORANGE) (eq ?m_next_c RING_GREEN)) ; decide which RS to move to
                                 then
                                 (bind ?station-free (do-for-fact ((?station station-free))
                                    (eq ?station:name M-RS1)
                                    (assert (action (id ?robo_id) (a_type "m") (machine M-RS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-RS1) (des_at_waypoint INPUT))
                                    (retract ?station)
                                    (if (eq ?pos M-BS)
                                    then
                                        (assert (block-bs (block_time ?ros-time-float)))  
                                    else
                                        (assert (station-free (name ?pos)))
                                    )
                                                    )
                                )
                                else 
                                     (bind ?station-free (do-for-fact ((?station station-free))
                                    (eq ?station:name M-RS2)
                                    (assert (action (id ?robo_id) (a_type "m") (machine M-RS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-RS2) (des_at_waypoint INPUT))
                                    (retract ?station)
                                    (if (eq ?pos M-BS)
                                    then
                                        (assert (block-bs (block_time ?ros-time-float)))  
                                    else
                                        (assert (station-free (name ?pos)))
                                    )
                                                        )
                                    )
                                )
                                (if (eq ?station-free FALSE)
                                    then
                                    (modify ?lc (c_time ?ros-time-float))
                                    (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                                ) 
                            else ;next is cap or deliver
                                (if (eq ?m_next DELIVER)
                                    then
                                        (assert (action (id ?robo_id) (a_type "m") (machine M-DS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                        (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-DS) (des_at_waypoint INPUT))
                                        (assert (station-free (name ?pos)))
                                        (if (eq ?pos M-CS1) ; tell R2 which cap was used to reprepare the CS
                                        then
                                            (assert (prepare-CS1))
                                            (assert (working_CS1))
                                        else
                                            (assert (prepare-CS2))
                                            (assert (working_CS2))
                                        )
                                    else ; next step is Cap
                                        (if (eq ?m_next_c CAP_GREY) ; decide which RS to move to
                                        then
                                            (bind ?station-free (do-for-fact ((?station station-free))
                                                (eq ?station:name M-CS1)
                                                (assert (action (id ?robo_id) (a_type "m") (machine M-CS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                                (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS1) (des_at_waypoint INPUT))
                                                (retract ?station)
                                                (if (eq ?pos M-BS)
                                                    then
                                                        (assert (block-bs (block_time ?ros-time-float)))  
                                                    else
                                                        (assert (station-free (name ?pos)))
                                                 )
                                                                )
                                            )
                                        else 
                                            (bind ?station-free (do-for-fact ((?station station-free))
                                                (eq ?station:name M-CS2)
                                                (assert (action (id ?robo_id) (a_type "m") (machine M-CS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                                (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS2) (des_at_waypoint INPUT))
                                                (retract ?station)
                                                (if (eq ?pos M-BS)
                                                    then
                                                        (assert (block-bs (block_time ?ros-time-float)))  
                                                    else
                                                        (assert (station-free (name ?pos)))
                                                )    
                                                                )
                                            )
                                        )
                                        (if (eq ?station-free FALSE)
                                            then
                                                (modify ?lc (c_time ?ros-time-float))
                                                (assert (request_task (id ?robo_id) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                                        ) 
                                )
                            )
                        else ;last step was movement to machine INPUT or deliver to machine
                            (if (> ?r_order 0) ;last was move to machine in - deliver
                            then
                                (assert (action (id ?robo_id) (a_type "d") (machine ?pos) (io INPUT) (task_id (+ ?last_robo_task 1))))
                                (modify ?robo_s (task (+ ?last_robo_task 1)))
                            else ; just deliverd - instruct, then move to out (if not DS)
                                (if(or (eq ?pos M-RS1) (eq ?pos M-RS2))
                                    then
                                        (modify ?machine_s (pos INPUT))
                                        (assert (instruct (machine ?pos) (operation RING) (color ?r_next_c) (task_id 42) (order_id ?m_order)))
                                    else ;CS or DS
                                        (if(eq ?pos M-DS)
                                        then
                                            (assert (instruct (machine M-DS) (operation DELIVER) (task_id 42) (order_id ?m_order)))
                                            (modify ?r_o (state DE))
                                            (assert (request_task (id ?robo_id) (last_task (+ ?last_robo_task 1)) (robo_order ?last_robo_order) (machine_order ?last_machine_order)));new untestet
                                        else
                                            (assert (instruct (machine ?pos) (operation MOUNT_CAP) (task_id  42) (order_id ?m_order)))
                                        
                                        )
                                ) 
                                (if (not (eq ?pos M-DS))
                                then 
                                    (assert (action (id ?robo_id) (a_type "m") (machine ?pos) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des ?pos) (des_at_waypoint OUTPUT));(order ?m_order)
                                    (if (or (eq ?pos M-RS1) (eq ?pos M-RS2)); RS can be free if moved to out as R2/R3 will only deliver to slide need to prevet Deadlock
                                    then
                                        (assert (station-free (name ?pos)))
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
        (case 2 then ; unreachable - no action for R2 or R3 here after init
        ;noop
        )
        (case 3 then ; unreachable
        ;noop
        )
        )
    )
    )


(defrule request_task_CS1_refill ;R2 exclusive
?rt <- (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order))
?lc <- (last_checked (id 2) (c_time ?check_time));back-off timer
(init_it (id 2) (iteration ?init_it))
(test (eq ?init_it 8)) ;check if init done
(time ?ros-time-float)
(test (> (- ?ros-time-float ?check_time) 1))
?prep <- (prepare-CS1) ; trigger
?robo_s <- (robo_status (id 2) (task ?r_task) (order ?r_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des)) ; current Robo info; prob. more as needed
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order) (pos ?m_pos))
?CS_it <- (cs_it (id 2) (iteration ?it)) ;itteration counter for CS refill
(machine_status (name M-RS1) (slide_shelf ?rs_slide)) ;CS info to update
=>
(retract ?rt)
(switch ?it
            (case 1 then
            (bind ?station-free (do-for-fact ((?station station-free))
                (eq ?station:name M-CS1)                            
                    (assert (action (a_type "m") (id 2) (machine M-CS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS1) (des_at_waypoint INPUT))
                    (modify ?CS_it (iteration (+ ?it 1)))
                    (retract ?station)
                    (if (eq ?pos M-RS1)
                        then
                        (assert (station-free (name M-RS1)))
                    )
                                )
                    )
            )
            (case 2 then
                (assert (action (id 2) (a_type "r") (machine M-CS1) (io SHELF) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?CS_it (iteration (+ ?it 1)))
            )
            (case 3 then
                (assert (action (id 2) (a_type "d") (machine M-CS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?CS_it (iteration (+ ?it 1)))
            )
            (case 4 then
                (assert (instruct (machine M-CS1) (operation RETRIEVE_CAP) (task_id  1)))
                (modify ?machine_s (task 1))
                (assert (action (id 2) (a_type "m") (machine M-CS1) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS1) (des_at_waypoint OUTPUT))
                (modify ?CS_it (iteration (+ ?it 1)))
            )
            (case 5 then
                (if (and (eq ?m_task 0) (eq ?m_pos OUTPUT))
                    then
                        (assert (action (id 2) (a_type "r") (machine M-CS1) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)))
                        (modify ?CS_it (iteration (+ ?it 1)))
                    else
                        (modify ?lc (c_time ?ros-time-float))
                        (assert (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order)))
                )
            )
            (case 6 then ;only if space - Clear base may be 3rd payment
                (if (< ?rs_slide 3)
                then
                    (bind ?station-free (do-for-fact ((?station station-free))
                        (eq ?station:name M-RS1)
                        (assert (action (id 2) (a_type "m") (machine M-RS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-RS1) (des_at_waypoint INPUT))
                        (modify ?CS_it (iteration (+ ?it 1)))
                        (assert (station-free (name ?pos)))
                        (retract ?station)
                        )
                    )
                    (if (eq ?station-free FALSE)
                        then
                        (modify ?lc (c_time ?ros-time-float))
                        (assert (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                    )
                else
                    (bind ?station-free (do-for-fact ((?station station-free)) ; if no space go to DS to throw away
                        (eq ?station:name M-DS)
                        (assert (action (id 2) (a_type "m") (machine M-DS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-DS) (des_at_waypoint INPUT))
                        (modify ?CS_it (iteration (+ ?it 1)))
                        (assert (station-free (name ?pos)))
                        (retract ?station)
                        )
                    )
                    (if (eq ?station-free FALSE)
                        then
                        (modify ?lc (c_time ?ros-time-float))
                        (assert (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                    )
                )
            )
            (case 7 then
                (if (eq ?pos M-RS1)
                then
                    (assert (action (id 2) (a_type "d") (machine M-RS1) (io SLIDE) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)))
                    (modify ?CS_it (iteration (+ ?it 1)))
                else
                    (assert (action (id 2) (a_type "d") (machine M-DS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)))
                    (modify ?CS_it (iteration (+ ?it 1)))
                )
            )
            (case 8 then
                (if (eq ?pos M-DS)
                then
                    (assert (instruct (machine M-DS) (operation DELIVER) (task_id 42) (order_id 0))) ;instsruckt DS if needed                                    
                )
                (retract ?prep)
                (modify ?CS_it (iteration 1))
                (assert (action (id 2) (a_type "m") (machine M-DS) (io OUTPUT) (task_id (+ ?last_robo_task 1)))) ; drive to parking position to not sant in the way for R1
                (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-DS) (des_at_waypoint OUTPUT))
                (assert (station-free (name ?pos)))           
 )
)
)

(defrule request_task_CS2_refill;analogous
?rt <- (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order))
?lc <- (last_checked (id 2) (c_time ?check_time))
(time ?ros-time-float)
(test (> (- ?ros-time-float ?check_time) 1))
?prep <- (prepare-CS2)
(init_it (id 2) (iteration ?init_it))
(test (eq ?init_it 8))
?robo_s <- (robo_status (id 2) (task ?r_task) (order ?r_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des))
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order) (pos ?m_pos))
?CS_it <- (cs_it (id 2) (iteration ?it))
(machine_status (name M-RS2) (slide_shelf ?rs_slide))
=>
(retract ?rt)
(switch ?it
            (case 1 then
                (bind ?station-free (do-for-fact ((?station station-free))
                    (eq ?station:name M-CS2)                            
                        (assert (action (a_type "m") (id 2) (machine M-CS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS2) (des_at_waypoint INPUT))
                        (modify ?CS_it (iteration (+ ?it 1)))
                        (retract ?station)
                        (if (eq ?pos M-RS1)
                            then
                                (assert (station-free (name M-RS1)))
                        )
                                    )
                ) 
            )
            (case 2 then
                (assert (action (id 2) (a_type "r") (machine M-CS2) (io SHELF) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?CS_it (iteration (+ ?it 1)))
            )
            (case 3 then
                (assert (action (id 2) (a_type "d") (machine M-CS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
                (modify ?CS_it (iteration (+ ?it 1)))
            )
            (case 4 then
                (assert (instruct (machine M-CS2) (operation RETRIEVE_CAP) (task_id  1)))
                (modify ?machine_s (task 1))
                (assert (action (id 2) (a_type "m") (machine M-CS2) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-CS2) (des_at_waypoint OUTPUT))
                (modify ?CS_it (iteration (+ ?it 1)))
            )
            (case 5 then
                (if (and (eq ?m_task 0) (eq ?m_pos OUTPUT))
                    then
                        (assert (action (id 2) (a_type "r") (machine M-CS2) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)))
                        (modify ?CS_it (iteration (+ ?it 1)))
                    else
                        (modify ?lc (c_time ?ros-time-float))
                        
                        (assert (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order)))
                )
            )
            (case 6 then ;only if space
                (if (< ?rs_slide 3)
                then
                    (bind ?station-free (do-for-fact ((?station station-free))
                        (eq ?station:name M-RS2)
                        (assert (action (id 2) (a_type "m") (machine M-RS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-RS2) (des_at_waypoint INPUT))
                        (modify ?CS_it (iteration (+ ?it 1)))
                        (assert (station-free (name ?pos)))
                        (retract ?station)
                        )
                    )
                    (if (eq ?station-free FALSE)
                        then
                        (modify ?lc (c_time ?ros-time-float))
                        (assert (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                    )
                else
                    (bind ?station-free (do-for-fact ((?station station-free))
                        (eq ?station:name M-DS)
                        (assert (action (id 2) (a_type "m") (machine M-DS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-DS) (des_at_waypoint INPUT))
                        (modify ?CS_it (iteration (+ ?it 1)))
                        (assert (station-free (name ?pos)))
                        (retract ?station)
                        )
                    )
                    (if (eq ?station-free FALSE)
                        then
                        (modify ?lc (c_time ?ros-time-float))
                        (assert (request_task (id 2) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                    )
                )

            )
            (case 7 then
                (if (eq ?pos M-RS2)
                then
                    (assert (action (id 2) (a_type "d") (machine M-RS2) (io SLIDE) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)))
                    (modify ?CS_it (iteration (+ ?it 1)))

                else
                    (assert (action (id 2) (a_type "d") (machine M-DS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)))
                    (modify ?CS_it (iteration (+ ?it 1)))
                )
            )
            (case 8 then
                (if (eq ?pos M-DS)
                then
                    (assert (instruct (machine M-DS) (operation DELIVER) (task_id 42) (order_id 0)))                                    
                )
                (retract ?prep)
                (modify ?CS_it (iteration 1))
                (assert (action (id 2) (a_type "m") (machine M-DS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-DS) (des_at_waypoint OUTPUT))
                (assert (station-free (name ?pos)))           
 )
)
)

(defrule request_task_payment ; Robo3 exclusive - to payment with black bases
?rt <- (request_task (id 3) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order))
?lc <- (last_checked (id 3) (c_time ?check_time)) ; back-off timer
(time ?ros-time-float)
(test (> (- ?ros-time-float ?check_time) 1))
(init_it (id 3) (iteration ?init_it))
(test (eq ?init_it 8)) ; init done?
?robo_s <- (robo_status (id 3) (task ?r_task) (order ?r_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des))
?machine_s <- (machine_status (name ?m_name) (task ?m_task) (order ?m_order) (pos ?m_pos))
?pay_it <- (pay_it (id 3) (iteration ?it));itteration for one payment
(machine_status (name M-RS1) (slide_shelf ?rs1_slide))
(machine_status (name M-RS2) (slide_shelf ?rs2_slide))
=>
(retract ?rt)
(switch ?it
            (case 1 then ;'order' base and drive to BS out
            (bind ?station-free (do-for-fact ((?station station-free))
                (eq ?station:name M-BS)
                    (retract ?station)
                    (assert (instruct (machine M-BS) (operation OUTPUT) (color BASE_BLACK) (task_id  1) (order_id 40)))
                    (assert (action (a_type "m") (id 3) (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)) (des M-BS) (des_at_waypoint OUTPUT))
                    (modify ?pay_it (iteration (+ ?it 1)))
                    (if 
                    (eq ?pos M-RS2)
                    then
                        (assert (station-free (name M-RS2)))
                    )
                    (printout red ?station-free crlf)
                    )
            )
            (printout red ?station-free crlf)
                (if (eq ?station-free FALSE)
                    then
                    (modify ?lc (c_time ?ros-time-float))
                    (assert (request_task (id 3) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                )    
            )
            (case 2 then
                (if (and (eq ?m_task 0) (eq ?m_pos OUTPUT)) ;pick up base when machine ready
                    then
                        (assert (action (id 3) (a_type "r") (machine M-BS) (io OUTPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1))(order 0))
                        (modify ?pay_it (iteration (+ ?it 1)))            
                    else
                    (modify ?lc (c_time ?ros-time-float))
                    (assert (request_task (id 3) (last_task ?last_robo_task) (robo_order ?last_robo_order)))
                )

            )
            (case 3 then ; move to parking
                    (assert (action (a_type "m") (id 3) (machine M-BS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                    (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-BS) (des_at_waypoint INPUT))
                    (modify ?pay_it (iteration (+ ?it 1)))
                    (assert (block-bs (block_time ?ros-time-float)))            
            )
            (case 4 then ; fill slide if <2 ( leave one space for potential clear bases R2)
                (if (< ?rs1_slide 2)
                    then
                    (bind ?station-free (do-for-fact ((?station station-free))
                        (eq ?station:name M-RS1)
                        (assert (action (id 3) (a_type "m") (machine M-RS1) (io INPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-RS1) (des_at_waypoint INPUT))
                        (modify ?pay_it (iteration (+ ?it 1)))
                        (retract ?station)
                        )
                    )   
                    else
                    (if (< ?rs2_slide 2)
                    then
                    (bind ?station-free (do-for-fact ((?station station-free))
                        (eq ?station:name M-RS2)
                        (assert (action (id 3) (a_type "m") (machine M-RS2) (io INPUT) (task_id (+ ?last_robo_task 1))))
                        (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-RS2) (des_at_waypoint INPUT))
                        (modify ?pay_it (iteration (+ ?it 1)))
                        (retract ?station)
                        )
                    )   
                    else
                        (modify ?lc (c_time ?ros-time-float))
                        (assert (request_task (id 3) (last_task ?last_robo_task) (robo_order ?last_robo_order)))
                    )

                )
                (if (eq ?station-free FALSE)
                    then
                    (modify ?lc (c_time ?ros-time-float))
                    (assert (request_task (id 3) (last_task ?last_robo_task) (robo_order ?last_robo_order) (machine_order ?last_machine_order)))
                ) 
                )

            (case 5 then ; deliver
                (assert (action (id 3) (a_type "d") (machine ?pos) (io SLIDE) (task_id (+ ?last_robo_task 1))))
                (modify ?pay_it (iteration (+ ?it 1)))
                (modify ?robo_s (task (+ ?last_robo_task 1)))
            )
            (case 6 then ;move away "park" at M-BS input - no check need as this does not block anything else
                (assert (action (id 3) (a_type "m") (machine M-BS) (io INPUT) (task_id (+ ?last_robo_task 1))))
                (modify ?robo_s (task (+ ?last_robo_task 1)) (order 42) (des M-BS) (des_at_waypoint INPUT))
                (modify ?pay_it (iteration (+ ?it 1)))
                (assert (station-free (name ?pos))); free current RS
                (modify ?pay_it (iteration 1)) ;reset pay_itterations
            )
)
)

(defrule complete_init
    (init_it (id 1) (iteration 8))
    (init_it (id 2) (iteration 8))
    (init_it (id 3) (iteration 8))
    ?o_state <- (order_status (id 42) (state ?order_s))
    (test (not (eq ?order_s DE)))
=>
    (modify ?o_state (state DE))
)