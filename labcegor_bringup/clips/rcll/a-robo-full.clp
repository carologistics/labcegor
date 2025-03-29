(deftemplate order_status
  (slot id (type INTEGER))
  (slot state (type SYMBOL)); (allowed-values RC BS RS1 RS2 CS1 CS2 DE))
  (slot next_step (type SYMBOL) (allowed-values BASE RING_1 RING_2 RING_3 CAP DELIVER NONE))
  (slot complexity (type SYMBOL))
  (slot next_color (type SYMBOL) (default EMPTY))
  (slot start_d_time (type INTEGER))
  (slot last_d_time (type INTEGER))
  (slot prio (type INTEGER))
)
(deftemplate robo_status
  (slot id (type INTEGER)); robo-id
  (slot task (type INTEGER)) ;current task-id 0 = free
  (slot order (type INTEGER)) ;odrder id of workpice in Hand 0=empty, 20 = hands full unassigned, 2X assigend to slide fo RSX
  (slot pos (type SYMBOL)); waypoint
  (slot pos_at_waypoint (type SYMBOL));if any
  (slot des (type SYMBOL) (default EMPTY)); destination waypoint
  (slot des_at_waypoint (type SYMBOL) (default EMPTY));if any
)
(deftemplate machine_status
  (slot name (type SYMBOL))
  (slot task (type INTEGER) (default 0)) ;0/1 ?
  (slot order (type INTEGER) (default 0)) ; order id 0= emty, 20 full unassigend
  (slot pos (type SYMBOL)(allowed-values INPUT inside OUTPUT empty) (default empty)) ; for CS especialy wp not cap
  (slot slide_shelf (type INTEGER)) ; 0,1,2,3 (pay in for RS) (0,1,2 - pickup point fo CS) 
)
(deftemplate request_task
  (slot id (type INTEGER));robo id
  (slot last_task (type INTEGER));taskid of last completet task
  (slot robo_order (type INTEGER));id of last order 0 if delivered as last task
  (slot machine_order (type INTEGER) (default 0))
)
(deftemplate order_colors
(slot id (type INTEGER))
(slot base (type SYMBOL) (default EMPTY))
(slot ring_1 (type SYMBOL) (default EMPTY))
(slot ring_2 (type SYMBOL) (default EMPTY) )
(slot ring_3 (type SYMBOL) (default EMPTY) )
(slot cap (type SYMBOL)(default EMPTY) )
)
(deftemplate perprocess_ring_colors 
(slot id (type INTEGER))
(multislot rings (type SYMBOL))
(slot it (type INTEGER))
)
(deftemplate init_it 
(slot id (type INTEGER))
(slot iteration (type INTEGER)))

(deftemplate cs_it 
(slot id (type INTEGER))
(slot iteration (type INTEGER)))

(deftemplate pay_it 
(slot id (type INTEGER))
(slot iteration (type INTEGER)))

(deftemplate update_rs
  (slot id (type INTEGER)) ;; rs1/RS2
  (slot payment (type INTEGER) (allowed-values 1 0 -1 -2)) ;1 for ring is added -1, -2 für payment for ring 0 as optional
)


(deftemplate team
  (slot name (type SYMBOL))
  (slot prefix (type SYMBOL))
)

(deftemplate last_checked
(slot id (type INTEGER))
(slot c_time (type FLOAT)))


(deftemplate station-free
(slot name (type SYMBOL)))

(deffacts team_machineinit
  (team (name MAGENTA)(prefix M))
  (init_moves)
  (machine_status (name M-RS1) (slide_shelf 0))
  (machine_status (name M-RS2) (slide_shelf 0))
  (machine_status (name M-CS1) (task 0) (pos empty))
  (machine_status (name M-CS2) (task 0) (pos empty))
  (machine_status (name M-BS) (task 0) (order 0) (pos empty))
  (machine_status (name M-DS) (task 0) (order 0) (pos empty))
  (robo_status (id 1) (task 0) (order 0) (pos START) (pos_at_waypoint NONE));repeat for other robos
  (robo_status (id 2) (task 0) (order 0) (pos START) (pos_at_waypoint NONE))
  (robo_status (id 3) (task 0) (order 0) (pos START) (pos_at_waypoint NONE))
  (last_checked (id 1) (c_time 0.0))
  (last_checked (id 2) (c_time 0.0))
  (last_checked (id 3) (c_time 0.0))
  (station-free (name M-CS1))
  (station-free (name M-CS2))
  (station-free (name M-RS1))
  (station-free (name M-RS2))
  (station-free (name M-BS))
  (station-free (name M-DS))
)

(deftemplate action
    (slot id (type INTEGER));robo id
    (slot a_type (type STRING)) ;(m)ove,(r)etrive,(p)ut
    (slot machine (type SYMBOL)) ;can be movepoint for move
    (slot io (type SYMBOL)) ;(i)nput,(o)utput, left, center, right
    (slot color (type SYMBOL) (default NONE) ) ;identifier or ""
    (slot task_id (type INTEGER))
    (slot wait (type INTEGER) (default 0))
)

(deftemplate instruct
    ;(slot a_type (type SYMBOL)) ;(m)ove,(r)etrive,(p)ut
    (slot machine (type SYMBOL)) ;can be movepoint for move
    (slot operation (type SYMBOL)) ;(i)nput,(o)utput, left, center, right
    (slot color (type SYMBOL) (default NONE) ) ;identifier or ""
    (slot task_id (type INTEGER))
    (slot wait (type INTEGER) (default 0))
    (slot order_id (type INTEGER))
)
(deftemplate processed_order
(slot id (type INTEGER)))

