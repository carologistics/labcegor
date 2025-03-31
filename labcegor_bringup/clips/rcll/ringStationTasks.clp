(defrule ring1
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone ?nid))
  ?ring-assignment-f <- (ring-assignment (machine ?machine) (colors ?c1 ?c2))
=> 
  (if (or (eq ?nid 4) (eq ?nid 9) (eq ?nid 14))
     then
    ;roboter muss zur nächsten ring station
    else
    ;roboter muss zur cap station
  )
  

)


(defrule robotToRS1-4
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid)) 
  ?order-f <- (order (id ?oid) (ring-colors ?ringColor $?rest))  
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone 4) (orderID ?oid))
  (not(testComplexity (orderID ?oid) (nextStep ?nS))) ;comlexity wurde getestet

  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt
  ?ring-assignment-f <- (ring-assignment (machine ?machine) (colors ?c1 ?c2))
  (test (or (eq ?c1 ?ringColor) (eq ?c2 ?ringColor)));only if machine provides certain ring color
=> 

  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?machine)
  (pb-set-field ?msgMove "machine_point" "INPUT")  ;zum output???
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "robot1ToRS1" crlf)
  (assert (placeRings ?machine ?ringColor))
)

(defrule robotToRS2-9
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid)) 

  ?order-f <- (order (id ?oid) (ring-colors ?first ?ringColor $?rest))  
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone 9) (orderID ?oid))
  (not(testComplexity (orderID ?oid) (nextStep ?nS))) ;comlexity wurde getestet
  (not (getGedönse))

  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt
  ?ring-assignment-f <- (ring-assignment (machine ?machine) (colors ?c1 ?c2))
  (test (or (eq ?c1 ?ringColor) (eq ?c2 ?ringColor)));only if machine provides certain ring color

=> 
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?machine)
  (pb-set-field ?msgMove "machine_point" "INPUT")  ;zum output???
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "robot1ToRS2" crlf)
  (assert (placeRings ?machine ?ringColor))

)

(defrule robotToRS3-14
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid)) 

  ?order-f <- (order (id ?oid) (ring-colors ?first ?second ?ringColor))  
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone 14) (orderID ?oid))
  (not(testComplexity (orderID ?oid) (nextStep ?nS))) ;comlexity wurde getestet

  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt
  ?ring-assignment-f <- (ring-assignment (machine ?machine) (colors ?c1 ?c2)) 
  (test (or (eq ?c1 ?ringColor) (eq ?c2 ?ringColor)));only if machine provides certain ring color

=> 
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?machine)
  (pb-set-field ?msgMove "machine_point" "INPUT")  ;zum output???
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "robot1ToRS3" crlf)
  (assert (placeRings ?machine ?ringColor))
)



(defrule placeGedönse-5,10,15
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid));HIER
  ?place-f <-(placeRings ?machine ?ringColor)
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone ?nttbd) (orderID ?oid))
  (not (waitingFor (machine ?machine) (orderID ?oid)))
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot)))  


=>
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Deliver"))
  (pb-set-field ?msgRetrieve "machine_id" ?machine) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "INPUT") ;output??
  (pb-set-field ?msg "deliver" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "deliverGedönse" crlf) 
  (assert (instructRS ?machine ?oid ?ringColor)) 
  (assert (verpissDich ?machine))
  (assert (machineWaitingForInstruction ?machine))
  (retract ?place-f)
  (modify ?robot-f (isHoldingSomething FALSE))
)


(defrule verpissDich-robot1-7-12-17
  ?verpissDich-f <- (verpissDich ?machine)
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid)) 
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone ?nttbd) (orderID ?oid))
  

  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt
=> 
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?machine)
  (pb-set-field ?msgMove "machine_point" "OUTPUT")  ;zum output???
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "roboter1verpisstSich" crlf)
  (retract ?verpissDich-f)
  (assert (getGedönse ?machine))
  (printout white "Next task ID (verpiss dich):" ?nttbd crlf )
)




(defrule instructRS-6,11,16
  ?instructRS-f <- (instructRS ?machine ?oid ?ringColor)
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid))
  ?machineWaitingForInstruction-f <- (machineWaitingForInstruction ?machine)
 
  ?machine-f <- (machine (name ?machine))

  (not (waitingFor (machine ?machine) (orderID ?oid)))
  (not (currentTask (robotID 1)))
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  

  ?currentlyPayed-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))
  ;only if already enough payment in machine
  ?ringColorCost-f <- (ring-spec (color ?ringColor) (cost ?cost))
  (test (or (and (eq ?machine M-RS1) (>= ?rs1Payed ?cost))
            (and (eq ?machine M-RS2) (>= ?rs2Payed ?cost))
  ))

=>
  (printout green "before instruction payed: M-RS1: " ?rs1Payed " M-RS2: " ?rs2Payed crlf)  

  (if (eq ?machine M-RS1) then
    (modify ?currentlyPayed-f (ringStation1 (- ?rs1Payed ?cost)))
    (printout green "after instruction payed: M-RS1: " (- ?rs1Payed ?cost) " M-RS2: " ?rs2Payed crlf)
    else
    (modify ?currentlyPayed-f (ringStation2 (- ?rs2Payed ?cost)))
    (printout green "after instruction payed: M-RS1: " ?rs1Payed" M-RS2: " (- ?rs2Payed ?cost) crlf)
  )
  
  

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?machine)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionRS"))
  (pb-set-field ?msgPrepare "ring_color" ?ringColor)
  (pb-set-field ?msg "instruction_rs" ?msgPrepare)

  (pb-broadcast ?peer-id ?msg)
 
  (pb-destroy ?msg)
  (assert (waitingFor (machine ?machine) (orderID ?oid)))
  (printout green "instruct" ?machine crlf)  
  (retract ?instructRS-f)
  (retract ?machineWaitingForInstruction-f)
  (assert (nextRetrieve))

)

(defrule robotRetrieveGedönse-8,13,18
  ?getGedönse-f <- (getGedönse ?machine)
  ?nextRetrieve-f <- (nextRetrieve)
  (not (machineWaitingForInstruction ?machine))
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid)) 

  ?order-tasks-f <- (order-tasks (nextTaskToBeDone ?nttbd) (orderID ?oid))
  (not (waitingFor (machine ?machine) (orderID ?oid)))
  ?machine-f <- (machine (name ?machine) (state READY-AT-OUTPUT))

  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot)))
=> 
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?msgRetrieve "machine_id" ?machine) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "OUTPUT") ;output??
  (pb-set-field ?msg "retrieve" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (printout green "retrieveGedönse" ?machine crlf)
  (retract ?getGedönse-f)
  (printout white "Next task ID (retrieve gedönse):" ?nttbd crlf )
  (assert (testComplexity (orderID ?oid) (nextStep (+ 1 ?nttbd))))
  (retract ?nextRetrieve-f)
  (modify ?robot-f (isHoldingSomething TRUE))
)









