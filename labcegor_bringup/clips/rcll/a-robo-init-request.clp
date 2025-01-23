(defrule init_all
(init_moves)
=>
    (request_task (id 3) (last_task 3000))
    (request_task (id 2) (last_task 2000))
    (request_task (id 1) (last_task 1000))
)

(defrule waitforfinish_robo
    ;?d <- (do (id ?id) (task ?t-id))
    ;?b <- (robo_busy (id ?id))
    (robo_status (id ?id) (task ?task) (order ?robo_order) (pos ?pos) (pos_at_waypoint ?pos_wp) (des ?des) (des_at_waypoint ?des_wp))
    ;machine info wher pos = machine
    (test (> ?task 0))
    (protobuf-msg (type "llsf_msgs.AgentTask") (msg-type ?msg-type)
    (client-type PEER) (ptr ?msg))
=>
    (bind ?robo_id (pb-field-value ?msg "robot_id"))
    (bind ?task_id (pb-field-value ?msg "task_id"))
    (bind ?success (pb-field-value ?msg "successful"))
    (if (and (eq ?robo_id ?id) (eq ?task_id ?t-id) (eq ?success TRUE))
    then
        ;(retract ?d)
        ;(retract ?b)
        (assert (done (done_t_id ?t-id)))
        (if (not (eq ?des ""))
            then
            ;pos = des; pos_wp =des_wp, des, des_wp = ""
            else
            ;no-op
        )
        (if (eq ?robo_order 0)
            ;robo_oder = machine_order
        )
        (assert (request_task (id ?id) (last_task ?task) (order ?order)))
        ;(printout green "TASK DONE"  crlf)
    else
        (printout green ?robo_id ?task_id ?success  crlf)
        (printout green ?id ?t-id  crlf)
    )
)
