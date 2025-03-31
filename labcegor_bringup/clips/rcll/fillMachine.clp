

;calculate how many rings of which color are waiting
(defrule calculateFillMachine
  ?ringsToProduce-f <- (ringsToProduce (blue ?b) (green ?g) (yellow ?y) (orange ?o))
  ?ringBlue-f <- (ring-spec (color RING_BLUE) (cost ?cB))
  ?ringGreen-f <- (ring-spec (color RING_GREEN) (cost ?cG))
  ?ringYellow-f <- (ring-spec (color RING_YELLOW) (cost ?cY))
  ?ringOrange-f <- (ring-spec (color RING_ORANGE) (cost ?cO)) 
  ?ring-assignment-f <- (ring-assignment (machine ?machine) (colors ?c1 ?c2))
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1) (ringStation2 ?rs2))

  ?fact-f <- (calculateFillMachineForOrder ?orderID)
  (not (calculateFillMachineForOrderDone ?orderID ?machine))
=>
  (assert (calculateFillMachineForOrderDone ?orderID ?machine))
  (printout green "caluclateFillMachine" crlf)
  (printout red "Rings to produce: Blue" ?b 
                "green"?g
                "yellow" ?y
                "orange" ?o crlf)
  (if (> ?b 0)
    then
    (if(> ?cB 0)
      then
      (if (or (eq ?c1 RING_BLUE) (eq ?c2 RING_BLUE))
         then
            (modify ?ringsToProduce-f (blue (- ?b 1))) 
            (if (eq M-RS1 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation1 (+ ?rs1 ?cB))) ; add costs to fillMachineWithCaps forM-RS1
              
            )
            (if (eq M-RS2 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation2 (+ ?rs2 ?cB))); add costs to fillMachineWithCaps for rs2
            )
             

      )
    )
  )  ;if there are blue rings waiting and they are not for free

  (if (> ?g 0)
    then
    (if(> ?cG 0)
      then
      (if (or (eq ?c1 RING_GREEN) (eq ?c2 RING_GREEN))
         then
            (modify ?ringsToProduce-f (green (- ?g 1))) 
            (if (eq M-RS1 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation1 (+ ?rs1 ?cG))) ; add costs to fillMachineWithCaps forM-RS1
              
            )
            (if (eq M-RS2 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation2 (+ ?rs2 ?cG))); add costs to fillMachineWithCaps for rs2
            )
             

      )
    )
  )  ;if there are green rings waiting and they are not for free  

  (if (> ?y 0)
    then
    (if(> ?cY 0)
      then
      
      (if (or (eq ?c1 RING_YELLOW) (eq ?c2 RING_YELLOW))
         then
            (modify ?ringsToProduce-f (yellow (- ?y 1))) 
            (if (eq M-RS1 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation1 (+ ?rs1 ?cY))) ; add costs to fillMachineWithCaps forM-RS1
              
            )
            (if (eq M-RS2 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation2 (+ ?rs2 ?cY))); add costs to fillMachineWithCaps for rs2
            )
             

      )
    )
  )  ;if there are yellow rings waiting and they are not for free  

  (if (> ?o 0)
    then
    (if(> ?cO 0)
      then
      (if (or (eq ?c1 RING_ORANGE) (eq ?c2 RING_ORANGE))
         then
            (modify ?ringsToProduce-f (orange (- ?o 1))) 
            (if (eq M-RS1 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation1 (+ ?rs1 ?cO))) ; add costs to fillMachineWithCaps forM-RS1
              
            )
            (if (eq M-RS2 ?machine)
               then (modify ?fillMachineWithBases-f (ringStation2 (+ ?rs2 ?cO))); add costs to fillMachineWithCaps for rs2
            )
             

      )
    )
  )  ;if there are orange rings waiting and they are not for free  

 

  (printout red "after calculate fill machine (FALSE): rs1: "?rs1 " rs2: "?rs2 crlf)
 
)


;when BS is not used and bases are needed, send robot2 to BS
(defrule fillMachineWithBases ;instruct robot2 to place bases on certain machines
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1) (ringStation2 ?rs2))
  ?machine-f <- (machine (state IDLE) (name M-BS)) ;if basestation not used
  (not (robot2working))

=>
  (printout blue "asserting" ?rs1 ?rs2 crlf)
  (assert (robot2ToBS))
  (assert (robot2working))

)

;send robot2 to base station
(defrule robot2ToBS
  ?instruction-f <- (robot2ToBS)

  (protobuf-peer (name ROBOT2) (peer-id ?peer-id)) 
  (not (protobuf-msg))
  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 2) (taskID ?tidRobot))) ;Roboter 2 aktuell nicht beschäftigt
  (not (currentTask (station BS))) ;BS frei
  (not (Robot1OnWayToBS))
=> 
  (printout blue "ROBOT2TOBS")
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 2)

  (bind ?msgMove (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?msgMove "waypoint" M-BS)
  (pb-set-field ?msgMove "machine_point" "OUTPUT")
  (pb-set-field ?msg "move" ?msgMove)
  

  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 2) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (retract ?instruction-f)
  (assert (instructBSFill))
  (assert (Robot2OnWayToBS))
  
)

(defrule robotDoneFill
  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type ?c-type) (client-id ?c-id) (ptr ?ptr))

  ?cT-f <- (currentTask (robotID 2) (taskID ?tidRobot))
  ?currentlyPayed-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1) (ringStation2 ?rs2))
=>
  (bind ?robotID (pb-field-value ?ptr "robot_id"))

  (bind ?taskID (pb-field-value ?ptr "task_id"))
  (bind ?res (pb-has-field ?ptr "successful"))
  (if(and (= 2 ?robotID) (and ?res (= ?tidRobot ?taskID)))
    then 
    (retract ?cT-f)
    (printout red "robot2DoneFill" crlf)

    (if(pb-has-field ?ptr "deliver") then (printout white "has field deliver" crlf)
                                          (bind ?deliver (pb-field-value ?ptr "deliver")) 
                                          (bind ?machinePoint (pb-field-value ?deliver "machine_point"))
                                          (if (eq ?machinePoint "SLIDE") then (printout white "machinePoint SLIDE" crlf) 
                                           (bind ?machineID (sym-cat(pb-field-value ?deliver "machine_id")))
                                           (if(str-index "1" ?machineID) then (printout white "machineID 1" crlf) 
                                                                          (modify ?fillMachineWithBases-f(ringStation1 (- ?rs1 1))) 
                                                                          (modify ?currentlyPayed-f(ringStation1 (+ ?rs1Payed 1)))
                                                                          )
                                           (if(str-index "2" ?machineID) then (printout white "machineID 2" crlf)
                                                                          (modify ?fillMachineWithBases-f(ringStation2 (- ?rs2 1))) 
                                                                          (modify ?currentlyPayed-f(ringStation2 (+ ?rs2Payed 1)))
                                                                          ) 
                                           )
                                           
                                           )


    else 
  )

)


;instruct base station
(defrule instructBS2Fill

  ?instructBS-f <- (instructBSFill)
  (protobuf-peer (name refbox-private) (peer-id ?peer-id))
  (machine (state IDLE) (name M-BS)) ;if BS not used
  (not (Robot1OnWayToBS))
=>
  (printout blue "instructBSFill" crlf)
  (bind ?msg (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "machine" M-BS)
  

  (bind ?msgPrepare (pb-create "llsf_msgs.PrepareInstructionBS"))
  (pb-set-field ?msgPrepare "side" "OUTPUT")
  (pb-set-field ?msgPrepare "color" "BASE_SILVER")
  (pb-set-field ?msg "instruction_bs" ?msgPrepare)

  (pb-broadcast ?peer-id ?msg)
 
  (pb-destroy ?msg)
  (assert (waitingFor (machine M-BS) (refillBases TRUE)));refillBases only TRUE when machine was instructed for robot2
  (retract ?instructBS-f)
  (assert (getBase))
)

;wait for machine
(defrule machineDoneFill
  ?waiting-f <- (waitingFor (machine ?machineNameWaiting) (refillBases TRUE))
  ?machine-f <- (machine (name ?machineNameMachine) (state IDLE)) ;Idle?? 
=>

  (if (eq ?machineNameMachine ?machineNameWaiting)
    then
    (retract ?waiting-f))

)

;robot2 gets Base when machine is done and robot is at BS
(defrule getBase
  ?getBase-f <- (getBase)
  (not (waitingFor (machine M-BS)))
  (not (robot2ToBS))

  (protobuf-peer (name ROBOT2) (peer-id ?peer-id)) 
  (not (protobuf-msg))
  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 2) (taskID ?tidRobot)))
  ?robot2OnWay-f <- (Robot2OnWayToBS)
=> 
  (printout blue "getBaseFill" crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 2)


  (bind ?msgRetrieve (pb-create "llsf_msgs.Retrieve"))
  (pb-set-field ?msgRetrieve "machine_id" M-BS) ;welche id?
  (pb-set-field ?msgRetrieve "machine_point" "OUTPUT") ;output??
  (pb-set-field ?msg "retrieve" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 2) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)

  (retract ?getBase-f)
  (assert (goToRS))
  (retract ?robot2OnWay-f)
  
)


;Robot2 goes to the ring station that needs more bases (Nochmal anpassen zu: ringstation, die als nächstes benötigt wird?)
(defrule goToRingStation
  ?goToRS-f <- (goToRS)
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1) (ringStation2 ?rs2))
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id)) 
  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 2) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt

  ?basesNeededAt-f <- (basesNeededAt (ringStation ?ringStation))
  ?currentlyPayed-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))
=>
  (if (or (eq ?ringStation STOP) (and(>= ?rs1Payed 3) (>= ?rs2Payed 3)))
  then
    (assert (robot2ToWaypoint))
  else
  
    (bind ?msg (pb-create "llsf_msgs.AgentTask"))
    (pb-set-field ?msg "team_color" MAGENTA)          
    (pb-set-field ?msg "task_id" ?tid)    
    (pb-set-field ?msg "robot_id" 2)

    (bind ?msgMove (pb-create "llsf_msgs.Move"))
    (printout blue "Robot2 goes to " ?ringStation crlf) 
    (pb-set-field ?msgMove "waypoint" ?ringStation)
    (pb-set-field ?msgMove "machine_point" "INPUT")
    (pb-set-field ?msg "move" ?msgMove)
    

    (assert (taskID (+ ?tid 1)))
    (retract ?tid-f)
    (assert (currentTask (robotID 2) (taskID ?tid)))
    (pb-broadcast ?peer-id ?msg)
    (pb-destroy ?msg)

    (assert (placeBaseInSlide ?ringStation))
    (retract ?goToRS-f)
    (assert (robot2AtWayToSlide))

  )

)

;Robot2 goes to the ring station that needs more bases (Nochmal anpassen zu: ringstation, die als nächstes benötigt wird?)
(defrule goToWaypoint
  ?goToWP-f <- (robot2ToWaypoint)
  (protobuf-peer (name ROBOT2) (peer-id ?peer-id)) 
  ?tid-f <- (taskID ?tid)
  (not (currentTask (robotID 2) (taskID ?tidRobot))) ;Roboter aktuell nicht beschäftigt

=>

    (bind ?msg (pb-create "llsf_msgs.AgentTask"))
    (pb-set-field ?msg "team_color" MAGENTA)          
    (pb-set-field ?msg "task_id" ?tid)    
    (pb-set-field ?msg "robot_id" 2)

    (bind ?msgMove (pb-create "llsf_msgs.Move"))
    (pb-set-field ?msgMove "waypoint" M_Z61)
    (pb-set-field ?msgMove "machine_point" "INPUT")
    (pb-set-field ?msg "move" ?msgMove)
    

    (assert (taskID (+ ?tid 1)))
    (retract ?tid-f)
    (assert (currentTask (robotID 2) (taskID ?tid)))
    (pb-broadcast ?peer-id ?msg)
    (pb-destroy ?msg)

    (retract ?goToWP-f)



)




;robot2 gets Base when machine is done
(defrule placeInSlide
  ?placeBase-f <- (placeBaseInSlide ?rs)
  (not (currentTask (robotID 2) (taskID ?tidRobot))) ;erst wenn roboter2 angekommen ist

  (protobuf-peer (name ROBOT2) (peer-id ?peer-id)) 
  ?tid-f <- (taskID ?tid)
  ?robot2working-f <- (robot2working)
=> 
  (assert (Robot2CurrentlyAtSlide))
  (printout blue "placeBaseInSlide" ?rs crlf)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)          
  (pb-set-field ?msg "task_id" ?tid)    
  (pb-set-field ?msg "robot_id" 2)



  (bind ?msgRetrieve (pb-create "llsf_msgs.Deliver"))
  (pb-set-field ?msgRetrieve "machine_id" ?rs) 
  (pb-set-field ?msgRetrieve "machine_point" "SLIDE") 
  (pb-set-field ?msg "deliver" ?msgRetrieve) 


  (assert (taskID (+ ?tid 1)))
  (retract ?tid-f)
  (assert (currentTask (robotID 2) (taskID ?tid)))
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)


  (retract ?placeBase-f)
  (retract ?robot2working-f)



)

(defrule robotDoneAtSlide
    ?f-f <- (Robot2CurrentlyAtSlide)
    (not (currentTask (robotID 2) (taskID ?tidRobot)))

  =>
    (retract ?f-f)
    (printout blue "robot2 done at Slide" crlf)
)

(defrule robotAtSlide
    ?f-f <- (robot2AtWayToSlide)
    (not (currentTask (robotID 2) (taskID ?tidRobot)))

  =>
    (retract ?f-f)
    (printout blue "robot2 arrived at Slide" crlf)
)
