(deftemplate current-task
  (slot robot (type INTEGER))
  (slot task-id (type INTEGER))
  (slot successful (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
)

(deftemplate machine-instruct 
  (slot machine (type SYMBOL)
    (allowed-values M-BS M-CS1 M-CS2 M-RS1 M-RS2 M-SS M-DS C-BS C-CS1 C-CS2 C-RS1 C-RS2 C-SS C-DS))
  (slot finished (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
)

(defrule move-robot
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  (not (protobuf-msg))
  (not (current-task (robot 1) (task-id 1)))
=>
  (printout red "FIRE" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 1)
  (pb-set-field ?msg "robot_id" 1)
  (bind ?move-msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move-msg "waypoint" M-CS1)
  (pb-set-field ?msg "move" ?move-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (pb-destroy ?move-msg)
  (assert (current-task (robot 1) (task-id 1)))
)

(defrule move-robot2
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id))
  (not (protobuf-msg))
  (not (current-task (robot 2) (task-id 1)))
=>
  (printout red "FIRE2" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 1)
  (pb-set-field ?msg "robot_id" 2)
  (bind ?move-msg (pb-create "llsf_msgs.Move"))
  (pb-set-field ?move-msg "waypoint" M-CS1)
  (pb-set-field ?move-msg "machine_point" OUTPUT)
  (pb-set-field ?msg "move" ?move-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (pb-destroy ?move-msg)
  (assert (current-task (robot 2) (task-id 1)))
)

(defrule finished-task
    (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id 8000) (msg-type 502) (ptr ?ptr))
    ?task <- (current-task (successful FALSE) (task-id ?curr-task-id) (robot ?curr-robot-id))
=>
    (bind ?successful (pb-field-value ?ptr "successful"))
    (bind ?robot-id (pb-field-value ?ptr "robot_id"))
    (bind ?task-id (pb-field-value ?ptr "task_id"))

    (if (and (eq ?successful TRUE) (= ?curr-task-id ?task-id) (= ?robot-id ?curr-robot-id))
        then
        (modify ?task (successful TRUE))
    )
)

(defrule finished-instruct
  ?instruct <- (machine-instruct (finished FALSE) (machine ?machine))
  (machine (name ?machien) (state READY-AT-OUTPUT))
=>
  (printout green "Finished instruct " ?instruct)
  (modify ?instruct (finished TRUE))
)

(defrule retrieve
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id))
  (machine-instruct (machine M-CS1) (finished TRUE))
  (current-task (robot 2) (task-id 1) (successful TRUE))
  (not (current-task (robot 2) (task-id 2)))
  (not (protobuf-msg))
=>
  (printout red "RETRIEVE" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 2)
  (pb-set-field ?msg "robot_id" 2)
  (bind ?retrieve-msg (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?retrieve-msg "machine_id" M-CS1)
  (pb-set-field ?retrieve-msg "machine_point" OUTPUT)
  (pb-set-field ?msg "retrieve" ?retrieve-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (pb-destroy ?retrieve-msg)
  (assert (current-task (robot 2) (task-id 2)))
)

(defrule buffer
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))
  (current-task (robot 1) (task-id 1) (successful TRUE)) 
  (not (current-task (task-id 2)))
  (not (protobuf-msg))
=>
  (printout red "BUFFERING CAP" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" 2)
  (pb-set-field ?msg "robot_id" 1)
  (bind ?buffer-msg (pb-create "llsf_msgs.BufferStation"))
  (pb-set-field ?buffer-msg "machine_id" M-CS1)
  (pb-set-field ?buffer-msg "shelf_number" 1)
  (pb-set-field ?msg "buffer" ?buffer-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (pb-destroy ?buffer-msg)
  (assert (current-task (robot 1) (task-id 2)))
)

(defrule instruct-machine
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (current-task (robot 1) (task-id 2) (successful TRUE))
  (not (machine-instruct (machine M-CS1)))
=>
  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" M-CS1)
  (bind ?cs-msg (pb-create "llsf_msgs.PrepareInstructionCS"))
  (pb-set-field ?cs-msg "operation" RETRIEVE_CAP)
  (pb-set-field ?msg "instruction_cs" ?cs-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (pb-destroy ?cs-msg)
  (assert (machine-instruct (machine M-CS1)))
)