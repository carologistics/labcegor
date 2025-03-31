(defrule robotToBS-1
  ?listR1-f <- (taskRobot1 (list 0 $?l))
  (test(> (length$ $?l) 1))
  ?list2R1-f <- (taskRobot1 (list 0 ?oid $?rest))
  ?order-f <- (order (id ?oid) (base-color ?base) (firstPartDone FALSE))  
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone 1))
  ?robot-f <- (robot (name ROBOT1) (currentOrder 0))
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt
  (not (currentTask (station BS))) ;BS frei
  (not (Robot2OnWayToBS))
=> 
  (modify ?robot-f(currentOrder ?oid))
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" M-BS)
  (pb-set-field ?msgMove "machine_point" "OUTPUT")
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (assert (instructBS ?oid))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid) (station BS)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "robot1ToBS for order " ?oid crlf)
  (assert (Robot1OnWayToBS))
)


(defrule instructBS-2
  ?listR1-f <- (taskRobot1 (list 0 $?l))
  (test(> (length$ $?l) 1))
  ?list2R1-f <- (taskRobot1 (list 0 ?oid $?rest))
  ?order-f <- (order (id ?oid) (base-color ?base))  
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone ?nttbd) (orderID ?oid))
  ?instructBS-f <- (instructBS ?oid)

  ?machine-f <- (machine (name M-BS) (state IDLE))

  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (not (waitingFor (machine M-BS) (orderID ?oid)))
  (not (Robot2OnWayToBS))
  
=>
  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" M-BS)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionBS"))
  (pb-set-field ?msgPrepare "side" "OUTPUT")
  (pb-set-field ?msgPrepare "color" ?base)
  (pb-set-field ?msg "instruction_bs" ?msgPrepare)

  (pb-broadcast ?peer-id ?msg)
 
  (pb-destroy ?msg)
  (assert (waitingFor (machine M-BS) (orderID ?oid)))
  (printout green "instructBS2 for order " ?oid crlf)
  (retract ?instructBS-f)
)

(defrule robotRetrieveBase-3
  ?listR1-f <- (taskRobot1 (list 0 $?l))
  (test(> (length$ $?l) 1))
  ?list2R1-f <- (taskRobot1 (list 0 ?oid $?rest))

  ?order-f <- (order (id ?oid) (base-color ?base))  
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone 3) (orderID ?oid))
  (not (waitingFor (machine M-BS) (orderID ?oid)))

  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot)))

  ?robot1OnWay-f <- (Robot1OnWayToBS)
=> 
  (retract ?robot1OnWay-f)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?msgRetrieve "machine_id" M-BS) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "OUTPUT") ;output??
  (pb-set-field ?msg "retrieve" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "retrieveBase Robot1 at BS" crlf)
)





(defrule testComplexity 
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid))
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone 4) (orderID ?oid))
=>
  (assert (testComplexity (orderID ?oid) (nextStep 4)))
  
)





(defrule machineDoneBS
  ?waiting-f <- (waitingFor (machine M-BS) (orderID ?oidWaiting))
  ?machine-f <- (machine (name M-BS) (state IDLE)) ;Idle?? 
  ?order-tasks-f <- (order-tasks (orderID ?oidTask) (nextTaskToBeDone ?nid))
=>
  (if(eq ?oidTask ?oidWaiting)
    then
    (retract ?waiting-f)
    (modify ?order-tasks-f (nextTaskToBeDone 3))
    (printout blue "machine done M-BS"  crlf)
  )
  (printout blue "waitingFor M-BS" crlf)

)






