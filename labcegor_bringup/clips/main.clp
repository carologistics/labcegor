(defrule update-instruct
  ?instruct <- (instruct (state SEND) (machine ?machine))
  (machine (name ?machine) (state PROCESSING))
=>
  (printout green "Update instruct " ?instruct)
  (modify ?instruct (state STARTED))
)

(defrule finished-instruct
  ?instruct <- (instruct (state STARTED) (machine ?machine))
  (machine (name ?machine) (state ?s&:(or (eq ?s READY-AT-OUTPUT) (eq ?s IDLE))))
=>
  (printout green "Finished instruct " ?instruct)
  (modify ?instruct (state FINISHED))
)

(defrule clear-after-instruct
  ?finished_instruct <- (instruct (state FINISHED) (machine ?machine))
=>
  (printout blue "Cleaning up after Instruct")
  (do-for-all-facts ((?move move_base)) 
   (member$ ?finished_instruct ?move:depend_on) 
    (modify ?move (depend_on (delete-member$ ?move:depend_on ?finished_instruct)))
  )
  (do-for-all-facts ((?instruct instruct)) 
   (member$ ?finished_instruct ?instruct:depend_on) 
    (modify ?instruct (depend_on (delete-member$ ?instruct:depend_on ?finished_instruct)))
  )

  (if (str-index DS ?machine)
    then
    (bind ?order_id (fact-slot-value ?finished_instruct order_id))
    (do-for-fact ((?order order)) (eq ?order:id ?order_id)
      (modify ?order (finished TRUE))
    )
  )
)

(defrule finished-move-base
  ?move_base <- (move_base (state FINISHED))
=>
  (printout blue "Cleaning up after Task")

  (do-for-all-facts ((?instruct instruct)) 
    (member$ ?move_base ?instruct:depend_on) 
    (modify ?instruct (depend_on (delete-member$ ?instruct:depend_on ?move_base)))
  )
  (do-for-all-facts ((?move move_base))
   (member$ ?move_base ?move:depend_on) 
   (modify ?move (depend_on (delete-member$ ?move:depend_on ?move_base)))
  )
)


(defrule finished-task
    (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id 8000) (msg-type 502) (ptr ?ptr))
=>
  (if (not (pb-has-field ?ptr "successful")) then
    (return))
  (bind ?successful (pb-field-value ?ptr "successful"))
  (bind ?robot-id (pb-field-value ?ptr "robot_id"))
  (bind ?task-id (pb-field-value ?ptr "task_id"))

  (if (not ?successful) then
    (printout red "WARNING FAILED" crlf)
    (return))

  (bind ?id (integer (/ ?task-id 10)))
  (bind ?state_num (mod ?task-id 10))

  (do-for-fact ((?move_base move_base)) (eq ?move_base:task_id ?id) 
    (switch ?move_base:state
      (case MOVING_FROM then (if (eq ?state_num 1) then 
          (modify ?move_base (state MOVED_FROM))
          (printout green "FINISHED MOVING FROM: " ?task-id crlf)
        )
      )
      (case GRIPPING then (if (= ?state_num 2) then
          (modify ?move_base (state GRIPPED))
          (printout green "FINISHED GRIPPING" ?task-id crlf)
        )
      )
      (case MOVING_TARGET then (if (eq ?state_num 3) then
          (modify ?move_base (state MOVED_TARGET))
          (printout green "FINISHED MOVING TARGET: " ?task-id crlf)
        )
      )
      (case PUTTING then (if (eq ?state_num 4) then
          (modify ?move_base (state FINISHED))
          (printout green "FINISHED FULLY: " ?task-id crlf)
        )
      )
    )
  )
)

(defrule start
  (not (started))
=>
  (unwatch facts protobuf-msg protobuf-peer game-time ring-spec)
  (unwatch rules protobuf-cleanup-message refbox-recv-RingInfo refbox-recv-RobotInfo refbox-recv-GameState refbox-recv-refbox-OrderInfo refbox-recv-MachineInfo finished-task)
  (assert (started))
)
