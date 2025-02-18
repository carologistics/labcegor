(defrule move-robot-to
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  ?move_base <- (move_base (state PRE) (depend_on) (from ?from) (from_side ?from_side) (task_id ?id))
  ; ES darf keine andere move_base geben die im aktiven verfahren ist also alle anderen dürfen nur FINSIHED und PRE sein
  (not (move_base (state ?s&: (not (or (eq ?s FINISHED) (eq ?s PRE))))))
  (game-state (team-color ?team&: (neq ?team NOT-SET)))
=>
  (printout blue "MOVING ROBOT1 TO " ?from " AT SIDE " ?from_side crlf)

  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" ?team)
  (pb-set-field ?msg "task_id" (+ (* ?id 10) 1))
  (pb-set-field ?msg "robot_id" 1)
  (bind ?move-msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move-msg "waypoint" ?from)
  (pb-set-field ?move-msg "machine_point" ?from_side)
  (pb-set-field ?msg "move" ?move-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (pb-destroy ?move-msg)
  (modify ?move_base (state MOVING_FROM))
)

(defrule grasp-robot
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  ?move_base <- (move_base (state MOVED_FROM) (depend_on) (from ?from) (from_side ?from_side) (task_id ?id))
  (game-state (team-color ?team&: (neq ?team NOT-SET)))
  =>
  (printout blue "GRASPING ROBOT1 AT " ?from " AT SIDE " ?from_side crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" ?team)
  (pb-set-field ?msg "task_id" (+ (* ?id 10) 2))
  (pb-set-field ?msg "robot_id" 1)
  (bind ?retrieve-msg (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?retrieve-msg "machine_id" ?from)
  (pb-set-field ?retrieve-msg "machine_point" ?from_side)
  (pb-set-field ?msg "retrieve" ?retrieve-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (pb-destroy ?retrieve-msg)
  (modify ?move_base (state GRIPPING))
)

(defrule finished-task
    (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id 8000) (msg-type 502) (ptr ?ptr))
=>
  (bind ?successful (pb-field-value ?ptr "successful"))
  (bind ?robot-id (pb-field-value ?ptr "robot_id"))
  (bind ?task-id (pb-field-value ?ptr "task_id"))

  (bind ?id (integer (/ ?task-id 10)))
  (bind ?state_num (mod ?task-id 10))

  (do-for-fact ((?move_base move_base)) (eq ?move_base:task_id ?id) 
    (switch ?move_base:state
      (case MOVING_FROM then (if (eq ?state_num 1) then 
          (modify ?move_base (state MOVED_FROM))
          (printout green "FINISHED MOVING FROM" ?task-id  " asdf asdf " ?state_num crlf)
        )
      )
      (case MOVING_TARGET then (if (eq ?state_num 2) then
          (modify ?move_base (state MOVED_TARGET))
          (printout green "FINISHED MOVING TARGET" crlf)
        )
      )
      (case GRIPPING then (if (= ?state_num 3) then 
          (modify ?move_base (state GRIPPED)))
          (printout green "FINISHED GRASPING" ?task-id  " asdf asdf " ?state_num crlf)
      )
      (case PUTTING then (if (eq ?state_num 4) then
          (modify ?move_base (state FINISHED))
          (printout green "FINISHED FULLY" crlf)
        )
      )
    )
  )
)

; (defrule finished-instruct
;   ?instruct <- (machine-instruct (finished FALSE) (machine ?machine))
;   (machine (name ?machien) (state READY-AT-OUTPUT))
; =>
;   (printout green "Finished instruct " ?instruct)
;   (modify ?instruct (finished TRUE))
; )

; (defrule retrieve
;   (protobuf-peer (name ROBOT2) (peer-id ?peer-id))
;   (machine-instruct (machine M-CS1) (finished TRUE))
;   (current-task (robot 2) (task-id 1) (successful TRUE))
;   (not (current-task (robot 2) (task-id 2)))
;   (not (protobuf-msg))
; =>
;   (printout red "RETRIEVE" crlf)
;   (bind ?msg (pb-create "llsf_msgs.AgentTask"))
;   (pb-set-field ?msg "team_color" MAGENTA)
;   (pb-set-field ?msg "task_id" 2)
;   (pb-set-field ?msg "robot_id" 2)
;   (bind ?retrieve-msg (pb-create "llsf_msgs.Retrieve"))
;   (pb-set-field ?retrieve-msg "machine_id" M-CS1)
;   (pb-set-field ?retrieve-msg "machine_point" OUTPUT)
;   (pb-set-field ?msg "retrieve" ?retrieve-msg)
;   (pb-broadcast ?peer-id ?msg)
;   (pb-destroy ?msg)
;   (pb-destroy ?retrieve-msg)
;   (assert (current-task (robot 2) (task-id 2)))
; )

; (defrule buffer
;   (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
;   (current-task (robot 1) (task-id 1) (successful TRUE)) 
;   (not (current-task (task-id 2)))
;   (not (protobuf-msg))
; =>
;   (printout red "BUFFERING CAP" crlf)
;   (bind ?msg (pb-create "llsf_msgs.AgentTask"))
;   (pb-set-field ?msg "team_color" MAGENTA)
;   (pb-set-field ?msg "task_id" 2)
;   (pb-set-field ?msg "robot_id" 1)
;   (bind ?buffer-msg (pb-create "llsf_msgs.BufferStation"))
;   (pb-set-field ?buffer-msg "machine_id" M-CS1)
;   (pb-set-field ?buffer-msg "shelf_number" 1)
;   (pb-set-field ?msg "buffer" ?buffer-msg)
;   (pb-broadcast ?peer-id ?msg)
;   (pb-destroy ?msg)
;   (pb-destroy ?buffer-msg)
;   (assert (current-task (robot 1) (task-id 2)))
; )

; (defrule instruct-machine
;   (protobuf-peer (name refbox-private) (peer-id ?peer-id))
;   (current-task (robot 1) (task-id 2) (successful TRUE))
;   (not (machine-instruct (machine M-CS1)))
; =>
;   (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
;   (pb-set-field ?msg "team_color" MAGENTA)
;   (pb-set-field ?msg "machine" M-CS1)
;   (bind ?cs-msg (pb-create "llsf_msgs.PrepareInstructionCS"))
;   (pb-set-field ?cs-msg "operation" RETRIEVE_CAP)
;   (pb-set-field ?msg "instruction_cs" ?cs-msg)
;   (pb-broadcast ?peer-id ?msg)
;   (pb-destroy ?msg)
;   (pb-destroy ?cs-msg)
;   (assert (machine-instruct (machine M-CS1)))
; )