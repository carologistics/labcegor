(defrule robotToCS-19
  ?toCapStation-f <- (toCapStation ?oid)
  ?order-f <- (order (id ?oid) (cap-color ?capColor))  
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone ?nttbd) (orderID ?oid));nttbd 19?
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid))
 
  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt
  (not (placeOnCapStation ?capColor ?capStation))

  ?capPrepared-f <- (capPrepared (cs ?capStation))

  (test (or (and (eq ?capColor CAP_BLACK) (eq ?capStation M-CS2)) 
            (and (eq ?capColor CAP_GREY) (eq ?capStation M-CS1))
            ))
  
  

=> 
  (if (eq ?capColor CAP_BLACK) then (bind ?capStation M-CS2) else (bind ?capStation M-CS1))
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?capStation)
  (pb-set-field ?msgMove "machine_point" "INPUT")
  (pb-set-field ?msg "move" ?msgMove)
  


  (assert (currentTask (robotID 1) (taskID ?tid) (station ?capStation)))
  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))  
  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)

  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)


  (printout green "robotToCS" crlf)
  (assert (placeOnCapStation ?capColor ?capStation))
  
)

(defrule placeGedönseCapStation-20
  ?robot-f <- (robot (name ROBOT1) (currentOrder ?oid))

  ?order-tasks-f <- (order-tasks (nextTaskToBeDone ?nttbd) (orderID ?oid))

  (protobuf-peer (name ROBOT1) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 1) (taskID ?tidRobot)))  
  ?placeOnCapStation-f <- (placeOnCapStation ?capColor ?capStation)
  ?order-f <- (order (id ?oid))

  ?list2R1-f <- (taskRobot1 (list 0 ?oid $?rest))
  
=>
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 1)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Deliver"))
  (pb-set-field ?msgRetrieve "machine_id" ?capStation) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "INPUT") ;output??
  (pb-set-field ?msg "deliver" ?msgRetrieve) 

  (modify ?order-tasks-f (taskIDInProcess ?tid) (currentRobot 1))
  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 1) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)


  (printout green "deliverGedönseToCapStation" crlf) 
  (assert (instructCS ?oid ?capStation)) 
  (assert (machineWaitingForInstruction ?capStation))
  (retract ?placeOnCapStation-f)
  (modify ?robot-f (isHoldingSomething FALSE) (currentOrder 0))
  (modify ?order-f (firstPartDone TRUE))
  (modify ?list2R1-f (list 0 $?rest))
  (printout white "rest of order list" $?rest crlf)
  
 
)


(defrule robot3ToCSOutputInput

    
  ?list-f <- (taskRobot3 (list 0 $?l))
  (test(> (length$ $?l) 1))
  ?list2-f <- (taskRobot3 (list 0 ?oid $?rest))
  ?order-f <- (order (id ?oid) (cap-color ?cap))


  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3))) ;Roboter aktuell nicht beschäftigt
  (not (CapBuffered ?oid))
  (protobuf-peer (name refbox-private) (peer-id ?peer-id-ref))
  (not (robot3toOutputAgain ?capStation))
=>
  (if (eq ?cap CAP_BLACK) then (bind ?capStation M-CS2) else (bind ?capStation M-CS1))
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?capStation)
  (pb-set-field ?msgMove "machine_point" "INPUT")
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid) (station ?capStation)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (printout green "robot3ToCSOutput" crlf)
  (assert (retrieveFromShelf ?capStation))
  (assert (CapBuffered ?oid))


)

(defrule agentDoneRobot3

  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type ?c-type) (client-id ?c-id) (ptr ?ptr))

  ?cT-f <- (currentTask (robotID 3) (taskID ?tidRobot))
  ?currentlyPayed-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1) (ringStation2 ?rs2))
=>
  (bind ?robotID (pb-field-value ?ptr "robot_id"))

  (bind ?taskID (pb-field-value ?ptr "task_id"))
  (bind ?res (pb-has-field ?ptr "successful"))
  (if(and (= 3 ?robotID) (and ?res (= ?tidRobot ?taskID)))
    then 
    (retract ?cT-f)
    (printout blue "robot 3  done" crlf)
        (if(pb-has-field ?ptr "deliver") then (bind ?deliver (pb-field-value ?ptr "deliver")) 
                                          (bind ?machinePoint (pb-field-value ?deliver "machine_point"))
                                          (if (eq ?machinePoint "SLIDE") then 
                                           (bind ?machineID (sym-cat(pb-field-value ?deliver "machine_id")))
                                           (if(str-index "1" ?machineID) then 
                                                                          (modify ?fillMachineWithBases-f(ringStation1 (- ?rs1 1))) 
                                                                          (modify ?currentlyPayed-f(ringStation1 (+ ?rs1Payed 1)))
                                                                          )
                                           (if(str-index "2" ?machineID) then 
                                                                          (modify ?fillMachineWithBases-f(ringStation2 (- ?rs2 1))) 
                                                                          (modify ?currentlyPayed-f(ringStation2 (+ ?rs2Payed 1)))
                                                                          ) 
                                           )
                                           
                                           )

  )

)

(defrule robot3RetrieveFromShelf
  ?retrieve-f <- (retrieveFromShelf ?capStation)

  ?robot1-f <- (robot (name ROBOT1)(currentOrder ?oid));get ID of order that robot 1 is currently working on
  ?order-f <- (order (id ?oid) (cap-color ?cap))  
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3))) ;Roboter aktuell nicht beschäftigt
  (not (waitingFor (machine ?capStation) (orderID ?oid)))

  

=> 
  
  (printout white "retrieve cap" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?msgRetrieve "machine_id" ?capStation) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "SHELF") ;shelf or shelf1 or left???
  (pb-set-field ?msg "retrieve" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (printout green "robot3 retrieving from shelf at " ?capStation crlf)
  (retract ?retrieve-f)
  ;(assert (Robot3ToInputCS ?capStation))
  (assert (placeCap ?capStation))

  

)

(defrule robot3ToCSInput


  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3))) ;Roboter aktuell nicht beschäftigt
  ?toCS-f <- (Robot3ToInputCS ?capStation)
=>

  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?capStation)
  (pb-set-field ?msgMove "machine_point" "INPUT")
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid) (station ?capStation)))
  (assert (taskID (+ ?tid 1)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (printout green "robot3ToCSInput" crlf)


  (retract ?toCS-f)
  (assert (placeCap ?capStation))
)


(defrule robot3PlaceCapAtInput


  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3))) ;Roboter aktuell nicht beschäftigt
  ?placeCap-f <- (placeCap ?capStation)
=>

  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)

  (bind ?msgMove (pb-create "llsf_msgs.Deliver")) 
  (pb-set-field ?msgMove "machine_id" ?capStation)
  (pb-set-field ?msgMove "machine_point" "INPUT")
  (pb-set-field ?msg "deliver" ?msgMove)

  
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid) (station ?capStation)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (printout green "robot3 delivering Cap" crlf)


  (retract ?placeCap-f)
  (assert (prepareRetrieveCap ?capStation))
  (assert (robot3toOutputAgain ?capStation))
  
)

(defrule robot3ToOutputAgain 

  ?back-f <- (robot3toOutputAgain ?capStation)
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3)))

=>
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" ?capStation)
  (pb-set-field ?msgMove "machine_point" "OUTPUT")
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid) (station ?capStation)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (printout green "robot3ToCSOutputAgain" crlf)
  (retract ?back-f)
  (assert (robot3BackAtCS))
 
)






(defrule retrieveCap
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  ?prepare-f <- (prepareRetrieveCap ?capStation)
  (not (currentTask (robotID 3)))

 
=>
  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?capStation)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionCS"))
  (pb-set-field ?msgPrepare "operation" RETRIEVE_CAP)

  (pb-set-field ?msg "instruction_cs" ?msgPrepare)

 
  (pb-broadcast ?peer-id ?msg)
  (printout red "prepare retrieve cap" crlf)


  (retract ?prepare-f)  

  (pb-destroy ?msg)
  (assert (capPrepared (cs ?capStation)))
  (assert (waitingFor (machine ?capStation)))

)

(defrule getBaseFromCS
  ?prepared-f <- (capPrepared (cs ?capStation))
  (not (waitingFor (machine ?capStation)))
  (machine (name ?capStation) (state READY-AT-OUTPUT))


  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3))) ;Roboter aktuell nicht beschäftigt

    

=>
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?msgRetrieve "machine_id" ?capStation) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "OUTPUT") ;shelf or shelf1 or left???
  (pb-set-field ?msg "retrieve" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (assert (baseLoswerden ?capStation))

)

(defrule capStationDone
  ?waiting-f <- (waitingFor (machine ?machineNameWaiting) )
  ?machine-f <- (machine (name ?machineNameWaiting) (state READY-AT-OUTPUT)) ;Idle?? 
  (test (or (eq ?machineNameWaiting M-CS1) (eq ?machineNameWaiting M-CS2)))
=>

  (retract ?waiting-f)
  (printout red "ready at output" crlf)

)




;Robot3 goes to the ring station that needs more bases (Nochmal anpassen zu: ringstation, die als nächstes benötigt wird?)
(defrule baseLoswerdenToRingstation
  ?baseLoswerden-f <- (baseLoswerden ?capStation)
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1) (ringStation2 ?rs2))
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 
  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt

  ?currentlyPayed-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))
  ?basesNeededAt-f <- (basesNeededAt (ringStation ?ringStation))
=>
  (if (eq ?ringStation M-RS1) then (bind ?payed ?rs1Payed) else (bind ?payed ?rs2Payed)) ;so ring station zuweisen?
  (if (or (eq ?ringStation STOP) (>= ?payed 2))
    then
      (assert (orderToDeliveryStation))
      (printout green "asserting orderToDS in baseLoswerdenToRingstation" crlf)
      (assert (disposeBase (capStation ?capStation)))
      (retract ?baseLoswerden-f)
    else
      
      (bind ?msg (pb-create "llsf_msgs.AgentTask"))
      (pb-set-field ?msg "team_color" MAGENTA)          
      (pb-set-field ?msg "task_id" ?tid)    
      (pb-set-field ?msg "robot_id" 3)

      (bind ?msgMove (pb-create "llsf_msgs.Move"))
      (printout blue "Robot2 goes to " ?ringStation crlf) 
      (pb-set-field ?msgMove "waypoint" ?ringStation)
      (pb-set-field ?msgMove "machine_point" "INPUT")
      (pb-set-field ?msg "move" ?msgMove)
      

      (assert (taskID (+ ?tid 1)))
      (retract ?tid-f)
      (assert (currentTask (robotID 3) (taskID ?tid)))
      (pb-broadcast ?peer-id ?msg)
      (pb-destroy ?msg)

      (retract ?baseLoswerden-f)
      (assert (robot3BaseInSlide ?ringStation ?capStation))
  )
)


;robot3 
(defrule placeInSlideRobot3
  ?placeBase-f <- (robot3BaseInSlide ?rs ?capStation)
  (not (currentTask (robotID 3) (taskID ?tidRobot))) ;erst wenn roboter2 angekommen ist

  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 
  ?tid-f <- (taskID ?tid)

=> 
  (assert (Robot3CurrentlyAtSlide))
  (printout blue "placeBaseInSlide" ?rs crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)



  (bind ?msgRetrieve (pb-create "llsf_msgs.Deliver"))
  (pb-set-field ?msgRetrieve "machine_id" ?rs) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "SLIDE") ;output??
  (pb-set-field ?msg "deliver" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)


  (retract ?placeBase-f)



(assert (robot3toOutputAgain ?capStation))

)

(defrule robot3DoneAtSlide
    ?f-f <- (Robot3CurrentlyAtSlide)
    (not (currentTask (robotID 3) (taskID ?tidRobot)))

  =>
    (retract ?f-f)
    (printout blue "robot3 done at Slide" crlf)
)


(defrule mountCap
  ?capPrepared-f <- (capPrepared (cs ?capStation))
  ?instruct-f <- (instructCS ?oid ?capStation)
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (not (currentTask (robotID 3)))

=>

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" ?capStation)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionCS"))
  (pb-set-field ?msgPrepare "operation" MOUNT_CAP)

  (pb-set-field ?msg "instruction_cs" ?msgPrepare)

 
  (pb-broadcast ?peer-id ?msg)
  (printout red "mount cap" crlf)


  (retract ?capPrepared-f)  
  (retract ?instruct-f)

  (pb-destroy ?msg)



  (printout green "instruct MOUNT CAP" crlf)
  (assert (getOrderFromCS ?capStation))
)

(defrule getOrderFromCS
  ?getOrder-f <- (getOrderFromCS ?capStation)
  (not (waitingFor (machine ?capStation)))
  (machine (name ?capStation) (state READY-AT-OUTPUT))
  ?isBack-f <- (robot3BackAtCS)


  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3))) ;Roboter aktuell nicht beschäftigt
  
    

=>
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?msgRetrieve "machine_id" ?capStation) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "OUTPUT") ;shelf or shelf1 or left???
  (pb-set-field ?msg "retrieve" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (assert (orderToDeliveryStation))
  (retract ?getOrder-f)
  (retract ?isBack-f)
  (printout green "asserting orderToDS in getOrderFromCS" crlf)

)

(defrule robot3MoveToDS
  ?baseLoswerden-f <- (orderToDeliveryStation)
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 
  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt


  =>
  
  
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)

  (bind ?msgMove (pb-create "llsf_msgs.Move"))
  (printout blue "Robot3 goes to delivery station"  crlf) 
  (pb-set-field ?msgMove "waypoint" M-DS)
  (pb-set-field ?msgMove "machine_point" "INPUT")
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  
  (retract ?baseLoswerden-f)
  (assert (deliverOrderAtDS))

)


(defrule robot3PlaceOrderAtDS


  ;?robot3-f <- (robot (name ROBOT3))
  (protobuf-peer (name ROBOT3) (peer-id ?peer-id)) 

  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 3))) ;Roboter aktuell nicht beschäftigt
  ?placeOrder-f <- (deliverOrderAtDS)
 
=>

  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 3)

  (bind ?msgMove (pb-create "llsf_msgs.Deliver")) 
  (pb-set-field ?msgMove "machine_id" M-DS)
  (pb-set-field ?msgMove "machine_point" "INPUT")
  (pb-set-field ?msg "deliver" ?msgMove)

  
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 3) (taskID ?tid) (station M-DS)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (printout green "robot3 delivering Order at DS" crlf)


  (retract ?placeOrder-f)
  (assert (orderPlacedAtDS))
  
)

(defrule instructDS
  ?orderPlaced-f <- (orderPlacedAtDS)
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (not (currentTask (robotID 3)))
  ?list-f <- (taskRobot3 (list 0 ?oid $?rest))
  (not (disposeBase (capStation ?capStation)))
=>
  

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" M-DS)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionDS"))
  (pb-set-field ?msgPrepare "order_id" ?oid)

  (pb-set-field ?msg "instruction_ds" ?msgPrepare)

 
  (pb-broadcast ?peer-id ?msg)


  (retract ?orderPlaced-f)  

  (pb-destroy ?msg)

  (modify ?list-f (list 0 $?rest))
  (printout green "deliver Product " crlf)
 
)

(defrule instructDSDisposeBase
  ?orderPlaced-f <- (orderPlacedAtDS)
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (not (currentTask (robotID 3)))
  ?list-f <- (taskRobot3 (list 0 ?oid $?rest))
  ?dispose-f <- (disposeBase (capStation ?capStation))

=>
  
  ;falls nur base entsorgt werden soll, dann gib 0 als task id an

  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" M-DS)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionDS"))
  (pb-set-field ?msgPrepare "order_id" 0)

  (pb-set-field ?msg "instruction_ds" ?msgPrepare)

 
  (pb-broadcast ?peer-id ?msg)


  (retract ?orderPlaced-f)  
  (retract ?dispose-f)

  (pb-destroy ?msg)
  (assert (robot3toOutputAgain ?capStation))

 
)