(deftemplate order_status
  (slot id (type INTEGER))
  (slot state (type SYMBOL) (allowed-values RC BS RS1 RS2 CS1 CS2 DE))
  (slot next_step (type SYMBOL) (allowed-values Base Ring_1 Ring_2 Ring_3 Cap Deliver None))
  (slot start_d_time (type INTEGER))
  (slot last_d_time (type INTEGER))
  (slot prio (type INTEGER))
)
(deftemplate robo_status
  (slot id (type INTEGER)); robo-id
  (slot task (type INTEGER)) ;current task-id 0 = free
  (slot order (type INTEGER)) ;odrder id of workpice in Hand 0=empty, 20 = hands full unassigned, 2X assigend to slide fo RSX
  (slot pos (type SYMBOL)); waypoint
  (slot pos_at_wp (type SYMBOL));if any
  (slot des (type SYMBOL)); destination waypoint
  (slot des (type SYMBOL));if any
)
(deftemplate machine-status
  (slot name (type SYMBOL))
  (slot task (type INTEGER)) ;0/1 ?
  (slot order (type INTEGER)) ; order id 0= emty, 20 full unassigend
  (slot pos (type SYMBOL)(allowed-values input inside output)) ; for CS especialy wp not cap
  (slot slide_shelf (type INTEGER)) ; 0,1,2,3 (pay in for RS) (0,1,2 - pickup point fo CS) 
)
(deftemplate request_task
  (slot id (type INTEGER));robo id
  (slot last_task (type INTEGER));taskid of last completet task
  (slot order (type INTEGER));id of last order 0 if delivered as last task
)



(deftemplate team
  (slot name (type SYMBOL))
  (slot prefix (type SYMBOL))
)

(deffacts
  (team (name MAGENTA)(prefix M))
)