(deftemplate protobuf-peer
  (slot name (type SYMBOL))
  (slot peer-id (type INTEGER))
)

(deftemplate game-state
  (slot state (type SYMBOL) (allowed-values INIT WAIT-START RUNNING PAUSED))
  (slot phase (type SYMBOL) (allowed-values PRE_GAME SETUP EXPLORATION PRODUCTION POST_GAME))
  (slot points (type INTEGER))
  (slot points-other (type INTEGER))
  (slot team (type STRING))
  (slot team-other (type STRING))
  (slot team-color (type SYMBOL) (allowed-values NOT-SET CYAN MAGENTA) (default NOT-SET))
  (slot field-width (type INTEGER))
  (slot field-height (type INTEGER))
  (slot field-mirrored (type SYMBOL) (allowed-values FALSE TRUE))
)

(deftemplate machine
   (slot name (type SYMBOL))
   (slot type (type SYMBOL))
   (slot team-color (type SYMBOL))
   (slot zone (type SYMBOL))
   (slot rotation (type INTEGER))
   (slot state (type SYMBOL))
   (slot waitingFor (type SYMBOL) (default FALSE))
   (slot capPrepared (type SYMBOL) (default NULL))
)

(deftemplate ring-assignment
  (slot machine (type SYMBOL))
  (multislot colors (type SYMBOL))
)

(deftemplate ring-spec
  (slot color (type SYMBOL))
  (slot cost (type INTEGER))
)

(deftemplate robot
  (slot name (type SYMBOL))
  (slot number (type INTEGER))
  (slot state (type SYMBOL) (allowed-values ACTIVE MAINTENANCE))
  (slot is-busy (type SYMBOL) (allowed-values TRUE FALSE) (default FALSE))
  (slot currentOrder (type INTEGER) (default 0)) ;0 = arbeitslos
  (slot isHoldingSomething (type SYMBOL) (default FALSE))
)

(deftemplate order
  (slot id (type INTEGER))
  (slot name (type SYMBOL))
  (slot workpiece (type SYMBOL))
  (slot complexity (type SYMBOL))

  (slot base-color (type SYMBOL))
  (multislot ring-colors (type SYMBOL))
  (slot cap-color (type SYMBOL))

  (slot quantity-requested (type INTEGER))
  (slot quantity-delivered (type INTEGER))
  (slot quantity-delivered-other (type INTEGER))

  (slot delivery-begin (type INTEGER))
  (slot delivery-end (type INTEGER))
  (slot competitive (type SYMBOL))

  (slot ringsAddedToList (type SYMBOL) (default FALSE))
  (slot firstPartDone (type SYMBOL) (default FALSE))
)


(deftemplate order-tasks
  (slot robot-to-BS (type SYMBOL) (default FALSE))  ;1 roboter fährt zu base station
  (slot instruct-base (type SYMBOL) (default FALSE)) ;2 BS legt base in festgelegter Farbe hin
  (slot robot-retrieve-base (type SYMBOL) (default FALSE)) ;3 robotor nimmt base
  (slot product-to-ring-1 (type SYMBOL) (default FALSE)) ;4 Robotor bringt produkt zu Input ringstation mit erster Farbe
  (slot place-product-1 (type SYMBOL) (default FALSE)) ;5 Roboter legt produkt auf ringstation
  (slot instruct-ring-1 (type SYMBOL) (default FALSE)) ;6 maschine zaubert Ring auf produkt
  (slot robot-to-output-1 (type SYMBOL) (default FALSE)) ;7 roboter fährt zu output 
  (slot get-product-1 (type SYMBOL) (default FALSE)) ;8 roboter holt produkt wieder ab
  (slot product-to-ring-2 (type SYMBOL) (default FALSE)) ;9
  (slot place-product-2 (type SYMBOL) (default FALSE));10
  (slot instruct-ring-2 (type SYMBOL) (default FALSE)) ;11
  (slot robot-to-output-2 (type SYMBOL) (default FALSE)) ;12
  (slot get-product-2 (type SYMBOL) (default FALSE))  ;13
  (slot product-to-ring-3 (type SYMBOL) (default FALSE)) ;14
  (slot place-product-3 (type SYMBOL) (default FALSE)) ;15
  (slot instruct-ring-3 (type SYMBOL) (default FALSE)) ;16
  (slot robot-to-output-3 (type SYMBOL) (default FALSE)) ;17
  (slot get-product-3 (type SYMBOL) (default FALSE))   ;18

  ;hier fehlt was 
  (slot robot-to-CS (type SYMBOL) (default FALSE)) ;19
  (slot place-product-CS (type SYMBOL) (default FALSE));20
  ;instruct CS to get Cap
  ;robot to output
  ;get cap
  ;put cap in slide
  ;then instruct machine
  (slot instruct-CS (type SYMBOL) (default FALSE)) ;21 CS anweisen irgend was zu tun
  
  
  ;(slot instruct-CS (type SYMBOL) (default FALSE))
  (slot robot-to-output-CS (type SYMBOL) (default FALSE))
  ;hier fehlt was

  (slot currentRobot (type INTEGER) (default 0)) ;current robot working on task
  (slot nextTaskToBeDone (type INTEGER) (default 1))
  (slot orderID (type INTEGER) (default 0)) ;order ID
  (slot taskIDInProcess (type INTEGER) (default 0))
  (slot complexity (type INTEGER) (default 0))
  
  ;ändern: anstatt pro task einen slot, nextTaskID mit vordefinierten zahlen für Tasks nutzen
)


(deftemplate currentTask
  (slot robotID (type INTEGER) (default 0)) ;ID of Robot
  (slot taskID (type INTEGER) (default 0)) ;ID of task the robot is working on
  (slot station (type SYMBOL) (default NULL)) ;if machine is involved
)

(deftemplate waitingFor
  (slot machine (type SYMBOL) (default leer))
  (slot orderID (type INTEGER) (default 0))
  (slot refillBases (type SYMBOL) (default FALSE)) ;only true if machine was istructed to refill bases)
)

(deftemplate testComplexity
  (slot orderID (type INTEGER))
  (slot nextStep (type INTEGER))
) 

(deftemplate ringsToProduce
  (slot blue (type INTEGER) (default 0))
  (slot green (type INTEGER) (default 0))
  (slot yellow (type INTEGER) (default 0))
  (slot orange (type INTEGER) (default 0))
)

(deftemplate fillMachineWithBases
  (slot ringStation1 (type INTEGER) (default 0))
  (slot ringStation2 (type INTEGER) (default 0))
  (slot order (type INTEGER) (default 0))
)

(deftemplate currentlyPayed
  (slot ringStation1 (type INTEGER) (default 0))
  (slot ringStation2 (type INTEGER) (default 0))
)

(deftemplate basesNeededAt 
  (slot ringStation (type SYMBOL) (default M-RS1))
)

(deftemplate taskRobot3
  (multislot list (type INTEGER)) ;list with task Ids that need to be finished for Robot3
)

(deftemplate taskRobot1
  (multislot list (type INTEGER)) ;list with task Ids that need to be finished for Robot3
)