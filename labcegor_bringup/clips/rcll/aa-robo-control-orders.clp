(deftemplate order_status
  (slot id (type INTEGER))
  (slot state (type SYMBOL) (allowed-values RC BS R1 R2 R3 CO DE))
)
(deftemplate robo_busy
    (slot id (type INTEGER))
)
(deftemplate last_task
    (slot id (type INTEGER))
    (slot l_task_id (type INTEGER))
)
(deftemplate move
    (slot id (type INTEGER))
    (slot waypoint (type STRING))
    (slot io (type STRING))
)

(deffacts hiho
    (last_task (id 1) (l_task_id 1000))
    (last_task (id 2) (l_task_id 2000))
    (last_task (id 3) (l_task_id 3000))
)



(defrule recive_orders
    (order(id ?id_1))
    (not (order_status (id ?id_1)))
    (not (and (order (id ?oid&:(< ?oid ?id_1)))
              (not (order_status (id ?oid))))
    )
=>
    (assert (order_status (id ?id_1) (state RC)))    
)

(defrule select_next_order
    (order (id ?id_1) (complexity ?complexity_1) (base-color ?base_1) (ring-colors $?ring-colors_1) (cap-color ?cap_1) (quantity-delivered ?qd-us_1))
    (order_status (id ?id_1) (state RC))
    (not (and  (order (id ?oid&:(< ?oid ?id_1)))
               (order_status (id ?oid) (state ?o_state&:(eq ?o_state RC)))
        )
    )
=>   
 (printout red ?id_1 crlf)
 (if (eq ?cap_1 CAP_GREY)
 then
    (assert (move (id 3) (waypoint "M-CS1") (io "i")))
    ;erstelle fact to watch shoing completion of task ( evtl mit last task ??)
    ;when complet retrive, and place
 ;then CS-2
 else
    (assert (move (id 3) (waypoint "M-CS2") (io "i")))
 ;then CS-1
)
;sum costs for rings
;robo 1 to base station
;base station instructen on base color
;robo 2 capcarrier pick up and drop of at base station for first payed ring
;robo 3 to out of first ring (and bring cap carrier with you)
;robo 1 to out of 2ed ring (and bring one base with you)
;robo 2 to paymnents

)



(defrule watchmy_stuff
=>
(watch activations recive_orders))

;----WIP-----


(defrule robo_move
  (move (id ?id) (waypoint ?wp) (io ?io))
  (protobuf-peer (name ?name) (peer-id ?peer-id))
  (test (eq ?name (sym-cat (str-cat "ROBOT" ?id))))
  (last_task (id ?id) (l_task_id ?last_t))
  (not (robo_busy (id ?id)))
  =>
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" (+ ?last_t 1))
  ;TODO UPdate fact (maybe in check funktion)
  (pb-set-field ?msg "robot_id" ?id)
  (bind ?move-msg (pb-create "llsf_msgs.Move")) 
  (pb-set-field ?move-msg "waypoint" ?wp)
  (if (eq ?io i)
  then
    (pb-set-field ?move-msg "machine_point" "input")
  else
      (if (eq ?io o)
        then
            (pb-set-field ?move-msg "machine_point" "output")
      )
  )
  (pb-set-field ?msg "move" ?move-msg)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
  (assert (robo_busy (id ?id)))
)
