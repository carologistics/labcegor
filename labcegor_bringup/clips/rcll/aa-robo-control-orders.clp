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
;(deftemplate move
;    (slot id (type INTEGER))
;    (slot waypoint (type STRING))
;    (slot io (type STRING))
;    (slot task_id (type INTEGER))
;)
(deftemplate action
    (slot id (type INTEGER));robo id
    (slot a_type (type STRING)) ;(m)ove,(r)etrive,(p)ut
    (slot machine (type STRING)) ;can be movepoint for move
    (slot io (type STRING)) ;(i)nput,(o)utput, left, center, right
    (slot color (type STRING) (default "") ) ;identifier or ""
    (slot task_id (type INTEGER))
)

(deftemplate do
    (slot id (type INTEGER))
    (slot task (type INTEGER))
)

(deffacts hiho
    (last_task (id 1) (l_task_id 1000))
    (last_task (id 2) (l_task_id 2000))
    (last_task (id 3) (l_task_id 3000))
)

;(deftemplate nexttasks
;   (slot id (type INTEGER)) ;robo id
;   (multislot tasks)
;)

;(deffacts nexttasts_define
;    (nexttasks (id 1) (tasks))
 ;   (nexttasks (id 2) (tasks))
 ;   (nexttasks (id 3) (tasks))
;)



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
    (last_task (id 3) (l_task_id ?last_t))
    ;?nt <- (nexttasks (id 3) (tasks $?tasks))
=>   
 (printout red ?id_1 crlf)
 (if (eq ?cap_1 CAP_GREY)
 then
    (assert (action (a_type "m") (id 3) (machine "M-CS1") (io "i") (task_id (+ ?last_t 1)))) ;action unify
    (assert (action (a_type "r") (id 3) (machine "M-CS1") (io "left") (task_id (+ ?last_t 2)))) ;action unify
    (assert (action (a_type "p") (id 3) (machine "M-CS1") (io "i") (task_id (+ ?last_t 3))))
    (assert (action (a_type "m") (id 3) (machine "M-CS1") (io "o") (task_id (+ ?last_t 4))))
    ; istruct capstatoin
    ; wait capstaion
    ; retrive base
    ;move to ring station

    ;(modify ?nt (tasks ?tasks (move (id 3) (waypoint "M-CS1") (io "i") (task_id (+ ?last_t 1)))))
    ;erstelle fact to watch showing completion of task ( evtl mit last task ??)
    ;when complete retrive, and place
 else
    (assert (action (a_type "m") (id 3) (machine "M-CS2") (io "i") (task_id (+ ?last_t 1)))) ;action unify
)
;sum costs for rings
;robo 1 to base station
;base station instructen on base color
;robo 2 capcarrier pick up and drop of at base station for first payed ring
;robo 3 to out of first ring (and bring cap carrier with you)
;robo 1 to out of 2ed ring (and bring one base with you)
;robo 2 to paymnents

)

(defrule nexttask
    (not (robo_busy (id ?id)))
    (not (do (id ?id) (task ?t-id)))
    (action (id ?id) (task_id ?t-id))
    (not  (action (id ?id)(task_id ?t-id2&:(< ?t-id2 ?t-id))))
    ;action mit kleinster t-id
    =>
    (assert (do (id ?id) (task ?t-id)))
)


;todo check tasks for finish (s. t4 listen to comunication)


(defrule watchmy_stuff
=>
(watch activations recive_orders))

;----WIP-----


(defrule robo_move
  (action (a_type "m") (id ?id) (machine ?wp) (io ?io) (task_id ?t-id))
  (protobuf-peer (name ?name) (peer-id ?peer-id))
  (test (eq ?name (sym-cat (str-cat "ROBOT" ?id))))
  ?lt <-(last_task (id ?id) (l_task_id ?last_t))
  ;(not (robo_busy (id ?id)))
  ?do <- (do (id ?id) (task ?t-id))
  =>
  (assert (robo_busy (id ?id)))
  (retract ?do)
  (bind ?msg (pb-create "llsf_msgs.AgentTask"))
  (pb-set-field ?msg "team_color" MAGENTA)
  (pb-set-field ?msg "task_id" ?t-id)
  (modify ?lt (l_task_id ?t-id)); UPdate fact (maybe in check funktion)
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
)

