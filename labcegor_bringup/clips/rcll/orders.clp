(defrule startOrder
  ?order-f <- (order (id ?oid) (base-color ?base) (complexity ?c) (ring-colors $?ringColors) (ringsAddedToList FALSE) (firstPartDone FALSE))
  (not (order-tasks (orderID ?oid)))
  ?ringsToProduce-f <- (ringsToProduce (blue ?b) (green ?g) (yellow ?y) (orange ?o))
  ?list-f <- (taskRobot3 (list $?l3))
  ?listR1-f <- (taskRobot1 (list $?l1))
  
=> 

  (switch ?c
  (case C0 then 
    (assert (order-tasks (orderID ?oid)
                        (complexity ?c)
                        (product-to-ring-1 TRUE) 
                        (place-product-1 TRUE)
                        (instruct-ring-1 TRUE)
                        (robot-to-output-1 TRUE)
                        (get-product-1 TRUE)    
                        (product-to-ring-2 TRUE) 
                        (place-product-2 TRUE)
                        (instruct-ring-2 TRUE)
                        (robot-to-output-2 TRUE)
                        (get-product-2 TRUE)    
                        (product-to-ring-3 TRUE) 
                        (place-product-3 TRUE)
                        (instruct-ring-3 TRUE)
                        (robot-to-output-3 TRUE)
                        (get-product-3 TRUE))
    )   
    (printout red "case 0" crlf)
  )
  (case C1 then 
    (assert (order-tasks (orderID ?oid)
                        (complexity ?c)
                        (product-to-ring-2 TRUE) 
                        (place-product-2 TRUE)
                        (instruct-ring-2 TRUE)
                        (robot-to-output-2 TRUE)
                        (get-product-2 TRUE)    
                        (product-to-ring-3 TRUE) 
                        (place-product-3 TRUE)
                        (instruct-ring-3 TRUE)
                        (robot-to-output-3 TRUE)
                        (get-product-3 TRUE))
    )    
    (printout red "case1" crlf)
    (bind ?firstItem (nth$ 1 ?ringColors))
    (if (eq ?firstItem RING_BLUE) then (modify ?ringsToProduce-f (blue (+ ?b 1))))  
    (if (eq ?firstItem RING_GREEN) then (modify ?ringsToProduce-f (green (+ ?g 1))))  
    (if (eq ?firstItem RING_YELLOW) then (modify ?ringsToProduce-f (yellow (+ ?y 1))))
    (if (eq ?firstItem RING_ORANGE) then (modify ?ringsToProduce-f (orange (+ ?o 1))))  
  )
  (case C2 then 
    (assert (order-tasks (orderID ?oid)
                        (complexity ?c)
                        (product-to-ring-3 TRUE) 
                        (place-product-3 TRUE)
                        (instruct-ring-3 TRUE)
                        (robot-to-output-3 TRUE)
                        (get-product-3 TRUE))
    ) 
    (printout red "case2" crlf)
    (bind ?firstItem (nth$ 1 ?ringColors))
    (bind ?secondItem (nth$ 2 ?ringColors))
    (if (eq ?firstItem RING_BLUE) then (modify ?ringsToProduce-f (blue (+ ?b 1))))  
    (if (eq ?firstItem RING_GREEN) then (modify ?ringsToProduce-f (green (+ ?g 1))))  
    (if (eq ?firstItem RING_YELLOW) then (modify ?ringsToProduce-f (yellow (+ ?y 1))))  
    (if (eq ?firstItem RING_ORANGE) then (modify ?ringsToProduce-f (orange (+ ?o 1)))) 
    (if (eq ?secondItem RING_BLUE) then (modify ?ringsToProduce-f (blue (+ ?b 1))))  
    (if (eq ?secondItem RING_GREEN) then (modify ?ringsToProduce-f (green (+ ?g 1))))  
    (if (eq ?secondItem RING_YELLOW) then (modify ?ringsToProduce-f (yellow (+ ?y 1))))  
    (if (eq ?secondItem RING_ORANGE) then (modify ?ringsToProduce-f (orange (+ ?o 1))))     
  )
  (case C3 then 
    (assert (order-tasks (orderID ?oid) (complexity ?c))) 
    (printout red "case3" crlf)
    (bind ?firstItem (nth$ 1 ?ringColors))
    (bind ?secondItem (nth$ 2 ?ringColors))
    (bind ?thirdItem (nth$ 3 ?ringColors))
    (if (eq ?firstItem RING_BLUE) then (modify ?ringsToProduce-f (blue (+ ?b 1))))  
    (if (eq ?firstItem RING_GREEN) then (modify ?ringsToProduce-f (green (+ ?g 1))))  
    (if (eq ?firstItem RING_YELLOW) then (modify ?ringsToProduce-f (yellow (+ ?y 1))))  
    (if (eq ?firstItem RING_ORANGE) then (modify ?ringsToProduce-f (orange (+ ?o 1)))) 
    (if (eq ?secondItem RING_BLUE) then (modify ?ringsToProduce-f (blue (+ ?b 1))))  
    (if (eq ?secondItem RING_GREEN) then (modify ?ringsToProduce-f (green (+ ?g 1))))  
    (if (eq ?secondItem RING_YELLOW) then (modify ?ringsToProduce-f (yellow (+ ?y 1))))  
    (if (eq ?secondItem RING_ORANGE) then (modify ?ringsToProduce-f (orange (+ ?o 1))))   
    (if (eq ?thirdItem RING_BLUE) then (modify ?ringsToProduce-f (blue (+ ?b 1)))) 
    (if (eq ?thirdItem RING_GREEN) then (modify ?ringsToProduce-f (green (+ ?g 1))))  
    (if (eq ?thirdItem RING_YELLOW) then (modify ?ringsToProduce-f (yellow (+ ?y 1))))  
    (if (eq ?thirdItem RING_ORANGE) then (modify ?ringsToProduce-f (orange (+ ?o 1))))       
  )
  (default (printout red "default" crlf))
  )    
  (assert (calculateFillMachineForOrder ?oid))
  (modify ?order-f (ringsAddedToList TRUE))  
  (printout red ?c crlf)
  (modify ?list-f (list $?l3 ?oid))
  (modify ?listR1-f (list $?l1 ?oid))
)


(defrule insertToList
  ?addOrder-f <- (add ?oid)
  ?order-f <- (order (id ?oid) (delivery-end ?deliveryEnd))
  ?list-f <- (taskRobot3 (list 0 $?l3))
  ?listR1-f <- (taskRobot1 (list 0 $?l1))
  (test (> (length$ $?l1) 0))
  ?firstElement1-f <- (taskRobot1 (list 0 ?first1 $?rest1))
  ?orderFirstElement-f <- (order (id ?first1) (delivery-end ?endElementList))
=>



  (printout white "List: " $?l1 crlf)
  (retract ?addOrder-f)
)




(defrule skipSteps ;skip steps if order complexty is reached
  ?test-f <- (testComplexity (orderID ?idTest) (nextStep ?nS))
  ?order-task-f <- (order-tasks (orderID ?idTest) (complexity ?c) (nextTaskToBeDone ?nid))
=> 
  (printout white "testComplexity-next step:"?nS "complexity: "?c crlf)
 
    (if (eq ?nS 4) then
      (if (eq ?c C0) then 
      (modify ?order-task-f (nextTaskToBeDone 19))
      (printout red "skipComplexity4" crlf)
      (assert (toCapStation ?idTest)))
    )
    (if (eq ?nS 9) then
      (if (eq ?c C1) then 
      (modify ?order-task-f (nextTaskToBeDone 19))
      (printout red "skipComplexity9" crlf)
      (assert (toCapStation ?idTest)))
    )

    (if (eq ?nS 14) then
      (if (eq ?c C2) then 
      (modify ?order-task-f (nextTaskToBeDone 19))
      (printout red "skipComplexity14" crlf)
      (assert (toCapStation ?idTest)))
    )

    (if(eq ?nS 19) then (assert (toCapStation ?idTest)))
  
  ;)
  (printout blue "test complexity done"crlf)
  (retract ?test-f)
)




(defrule testComplexity 
  ?order-tasks-f <- (order-tasks (nextTaskToBeDone 4) (orderID ?oid))
=>
  (assert (testComplexity (orderID ?oid) (nextStep 4)))
)



(defrule machineDone
  ?waiting-f <- (waitingFor (machine ?machineNameWaiting) (orderID ?oidWaiting))
  ?machine-f <- (machine (name ?machineNameWaiting) (state IDLE)) ;Idle?? 
  ?order-tasks-f <- (order-tasks (orderID ?oidWaiting) (nextTaskToBeDone ?nid))
  (test (not (eq ?machineNameWaiting M-BS)))
=>

    (retract ?waiting-f)
    (modify ?order-tasks-f (nextTaskToBeDone (+ ?nid 1)))
    (printout blue "machine Done Orders.clp" crlf)
)


(defrule agentDoneOrders

  (protobuf-msg (type "llsf_msgs.AgentTask") (comp-id ?comp-id) (msg-type ?msg-type)
    (rcvd-via ?via) (rcvd-from ?address ?port) (rcvd-at ?rcvd-at)
    (client-type ?c-type) (client-id ?c-id) (ptr ?ptr))

  ?cT-f <- (currentTask (robotID ?idR) (taskID ?tidRobot))
  ?order-tasks-f <- (order-tasks (taskIDInProcess ?tidRobot) (nextTaskToBeDone ?nT))
  ?currentlyPayed-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1) (ringStation2 ?rs2))
=>
  (bind ?robotID (pb-field-value ?ptr "robot_id"))

  (bind ?taskID (pb-field-value ?ptr "task_id"))
  (bind ?res (pb-has-field ?ptr "successful"))
  (if(and (= ?idR ?robotID) (and ?res (= ?tidRobot ?taskID)))
    then 
    (retract ?cT-f)
    (modify ?order-tasks-f (taskIDInProcess 0) (currentRobot 0) (nextTaskToBeDone (+ ?nT 1)))
    (printout blue "robot done" ?idR crlf)

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


(defrule whereAreBasesNeededUrgent
  ?waitingForRS-f <- (machineWaitingForInstruction ?machine)
  (test (or (eq ?machine M-RS1) (eq ?machine M-RS2)))
  ?neededAt-f <- (basesNeededAt (ringStation ?rsNeeded))
  ?cP-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))

=>
  
  (if(or (and (eq ?machine M-RS1) (< ?rs1Payed 3)) (and (eq ?machine M-RS2) (< ?rs2Payed 3))) then
    (modify ?neededAt-f (ringStation ?machine))
    (printout red "bases urgently needed at " ?machine crlf)
  )
)

(defrule whereAreBasesNeeded
  (not (machineWaitingForInstruction ?machine))
  ?cP-f <- (currentlyPayed (ringStation1 ?rs1Payed) (ringStation2 ?rs2Payed))
  ?neededAt-f <- (basesNeededAt (ringStation ?rsNeeded))
  ?fillMachineWithBases-f <- (fillMachineWithBases (ringStation1 ?rs1Fill) (ringStation2 ?rs2Fill))
=>
  (if (and (>= ?rs1Payed 3) (>= ?rs2Payed 3)) then
    (modify ?neededAt-f (ringStation STOP))
    (printout white "both RS full" crlf)
  else
    (if (< ?rs1Payed ?rs2Payed) then 
      (modify ?neededAt-f (ringStation M-RS1))
      (printout red "bases  needed at M-RS1"  crlf)
      else
      (modify ?neededAt-f (ringStation M-RS2))
      (printout red "bases  needed at M-RS2"  crlf)

    ) 
  )
  
)


