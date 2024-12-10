(defrule peer-send-msg-robot1
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id))  ; hääää wie komme ich an die peer ID für einen bestimmten Roboter??
  (not (protobuf-msg))
  ?tid-f <- (taskID ?tid)
  ?tsk-f <- (task ?tsk)
  (not (currentTask (robotID 1) (taskID ?tidRobot)))
  (not (robot2))
  =>

  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)



  (switch ?tsk
  (case "moveOutput" then 
      (bind ?msgMove (pb-create "llsf_msgs.Move")) 
      (pb-set-field ?msgMove "waypoint" M-CS1)
      (pb-set-field ?msgMove "machine_point" "output")
      (pb-set-field ?msg "move" ?msgMove)
      (retract ?tsk-f)
      (assert (task "retrieve"))
      (printout red "move" ?peer-id crlf)
      
  )

  (case "retrieve" then
      (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
      (pb-set-field ?msgRetrieve "machine_id" M-CS1) ;welche id?
      (pb-set-field ?msgRetrieve "machine_point" "shelf1") ;output??
      (pb-set-field ?msg "retrieve" ?msgRetrieve)
      (retract ?tsk-f)
      (assert (task "deliver"))
      
  )
  
  (case "moveInput" then 
      (bind ?msgMove (pb-create "llsf_msgs.Move")) 
      (pb-set-field ?msgMove "waypoint" M-CS1)
      (pb-set-field ?msgMove "machine_point" "input")
      (pb-set-field ?msg "move" ?msgMove)
      (retract ?tsk-f)
      (assert (task "retrieve"))
      
  )
 
  (case "deliver" then
      (bind ?msgRetrieve (pb-create "llsf_msgs.Deliver"))
      (pb-set-field ?msgRetrieve "machine_id" M-CS1) ;welche id?
      (pb-set-field ?msgRetrieve "machine_point" "input") ;output??
      (pb-set-field ?msg "deliver" ?msgRetrieve)
      (retract ?tsk-f)
      (assert (task "instructMachine"))
      
  )
  



  (default none)
  )
  
  

  ; increment task idAgentTask
  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (print green ?msg crlf)

)


(defrule peer-send-msg-robot2
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id)) 
  (not (protobuf-msg))
  ?tid-f <- (taskID ?tid)
  ?tsk-f <- (task ?tsk)
  (not (currentTask (robotID 2) (taskID ?tidRobot)))
  ;?d-f <- (task "robot2Output")
  ?r <- (robot2)
  =>

  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 2)

  (printout blue "beweg dich du Miststück" crlf)

  (switch ?tsk
  (case "robot2Output" then 
      (bind ?msgMove (pb-create "llsf_msgs.Move")) 
      (pb-set-field ?msgMove "waypoint" M-CS1)
      (pb-set-field ?msgMove "machine_point" "output")
      (pb-set-field ?msg "move" ?msgMove)
      (retract ?tsk-f)
      (assert (task "pickUp"))
  )
  (case "pickUp" then 
      ;(bind ?msgMove (pb-create "llsf_msgs.ExploreWaypoint")) 
      ;(pb-set-field ?msgMove"machine_id" M-CS1)
      ;(pb-set-field ?msgMove "waypoint" M-CS1)
      ;(pb-set-field ?msgMove "machine_point" "output")
      ;(pb-set-field ?msg "explore_machine" ?msgMove)
      ;(retract ?tsk-f)
      ;(assert (task "move2"))
      (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
      (pb-set-field ?msgRetrieve "machine_id" M-CS1) ;welche id?
      (pb-set-field ?msgRetrieve "machine_point" "output") ;output??
      (pb-set-field ?msg "retrieve" ?msgRetrieve)
      (retract ?tsk-f)
      (assert (task "move2"))
  )
  (case "move2" then 
      (bind ?msgMove (pb-create "llsf_msgs.Move")) 
      (pb-set-field ?msgMove "waypoint" M_Z46)
      (pb-set-field ?msgMove "machine_point" "output")
      (pb-set-field ?msg "move" ?msgMove)
      (retract ?tsk-f)
      (assert (task "done"))
  )
  
  ;warum hebt der zweite Roboter das nicht auf?


  (default none)
  )
  
  

  ; increment task idAgentTask
  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 2) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (print green ?msg crlf)

)


(defrule instructMachine
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  ?tsk-f <- (task "instructMachine")
  (not (currentTask (robotID 1) (taskID ?tidRobot)))
=>
  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" M-CS1)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionCS"))
  (pb-set-field ?msgPrepare "operation" RETRIEVE_CAP)

  (pb-set-field ?msg "instruction_cs" ?msgPrepare)

  (retract ?tsk-f)
  (pb-broadcast ?peer-id ?msg)
  (printout red "instruction" crlf)
  (assert (task "robot2Output"))
  (assert (robot2))
  (pb-destroy ?msg)
)

(defrule printTask
  ?task-f <- (task ?t)
=>
  (printout yellow ?t crlf)  
  
  )


(defrule protobuf-msg-read-AgentTask
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type ?c-type) (client-id ?c-id) (ptr ?ptr))

  ?cT-f <- (currentTask (robotID ?idR) (taskID ?tidRobot))

=>
  (bind ?robotID (pb-field-value ?ptr "robot_id"))

  (bind ?taskID (pb-field-value ?ptr "task_id"))
  (bind ?res (pb-has-field ?ptr "successful"))
  (if(and (= ?idR ?robotID) (and ?res (= ?tidRobot ?taskID)))
    then 
    (retract ?cT-f)
    (printout red "Crepe" crlf)
    else 
    (printout red "Glühwein" crlf)
  )

  (printout yellow ?res ?tidRobot ?idR crlf)
)
 

