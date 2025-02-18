(defglobal ?*counter* = 0)

(deffunction next-number* ()
  (bind ?*counter* (+ ?*counter* 1))  ; Increment the counter by 1 
  (return ?*counter*)
)

(deftemplate order
  (slot id (type INTEGER))
  (slot refbox-order)
  (slot finished (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
)

(deftemplate move_base
  (slot task_id (type INTEGER) (default-dynamic (next-number*)))
  ; (slot robot-id (type INTEGER)
  ;   (allowed-values 1 2 3))
  (slot from (type SYMBOL))
  (slot from_side (type SYMBOL) (default SHELF)
    (allowed-values OUTPUT SHELF))
  (slot target (type SYMBOL))
  (slot target_side (type SYMBOL) (default INPUT)
    (allowed-values INPUT SLIDE))
  (multislot depend_on)
  (slot state (type SYMBOL)
    (allowed-values PRE MOVING_FROM MOVED_FROM GRIPPING GRIPPED MOVING_TARGET MOVED_TARGET PUTTING FINISHED)
  )
  (slot finished (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
)

(deftemplate instruct
  (slot action (type SYMBOL)
      (allowed-values DELIVER RETRIEVE DISPENSE-BASE BUFFER-CAP MOUNT-RING MOUNT-CAP DELIVER))
  (slot machine (type SYMBOL)
    (allowed-values M-BS M-CS1 M-CS2 M-RS1 M-RS2 M-SS M-DS C-BS C-CS1 C-CS2 C-RS1 C-RS2 C-SS C-DS))
  (slot side (type SYMBOL)
    (allowed-values INPUT OUTPUT)) ; FOR BS
  (slot base_color (type SYMBOL)
    (allowed-values BASE_BLACK BASE_SILVER BASE_RED)) ; FOR BS
  (slot order-id (type INTEGER)) ; FOR DS
  (multislot depend_on)
  (slot finished (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
)
(deffunction dismantel-order (?order ?team)
  (bind ?id (fact-slot-value ?order id))
  (bind ?refbox-order (fact-slot-value ?order refbox-order))
  ; (bind ?complexity (fact-slot-value ?order complexity))
  (bind ?base (fact-slot-value ?refbox-order base-color))
  ; (bind ?cap (fact-slot-value ?order cap))
  ; (bind ?rings (fact-slot-value ?order ring_colors))

  ; INSTRUCT base depend on nothing
  ; move_base to cap station depend on buffer cap instruction
  ; move_base cap shelf to input
  ; INSTRUCT buffer cap
  ; move_base output cap to delivery station
  ; INSTRUCT MOUNT CAP
  (if (eq cap CAP_BLACK) 
    then
      (if (eq ?team CYAN) then (bind ?cs_machine C-CS1) else (bind ?cs_machine M-CS1)) ;; TODO PROBABLY WRONG COLOR
    else
      (if (eq ?team CYAN) then (bind ?cs_machine C-CS2) else (bind ?cs_machine M-CS2))
  )
  (if (eq ?team CYAN) then (bind ?bs_machine C-BS) else (bind ?bs_machine M-BS))
  (if (eq ?team CYAN) then (bind ?bs_machine C-DS) else (bind ?ds_machine M-DS))
  (if (eq ?team CYAN) then (bind ?rs1_machine C-RS1) else (bind ?rs1_machine M-RS1))
  (bind ?dispense (assert (instruct (action DISPENSE-BASE) (machine ?bs_machine) (side OUTPUT) (base_color ?base))))
  (bind ?shelf_to_cs (assert (move_base (from ?cs_machine) (from_side SHELF) (target ?cs_machine))))
  (bind ?buffer (assert (instruct (action BUFFER-CAP) (machine ?cs_machine) (depend_on ?shelf_to_cs))))
  (bind ?bs_to_cs (assert (move_base (from ?bs_machine) (target ?cs_machine) (depend_on ?dispense ?buffer))))
  (bind ?cs_to_rs (assert (move_base (from ?cs_machine) (target ?rs1_machine) (target_side SLIDE) (depend_on ?buffer))))
  (bind ?mount_cap (assert (instruct (action MOUNT-CAP) (machine ?cs_machine) (depend_on ?cs_to_rs))))
  (bind ?cs_to_ds (assert (move_base (from ?cs_machine) (target ?ds_machine) (depend_on ?mount_cap))))
  (bind ?deliver (assert (instruct (action DELIVER) (machine ?ds_machine) (order-id ?id) (depend_on ?cs_to_ds))))
)

(defrule select-order
  ?refbox-order <- (refbox-order (id ?id) (complexity C0))
  (not (order (finished FALSE)))
  (not (and (refbox-order (id ?oid&: (< ?oid ?id))) 
              (order (id ?oid) (finished FALSE)) 
  ))
  (game-state (team-color ?team&: (neq ?team NOT-SET)))
=>
  (bind ?order (assert (order (id ?id) (refbox-order ?refbox-order))))
  (printout green "ORDER SELECTING" crlf)
  (dismantel-order ?order ?team)
)

; (defrule dasf
;   (time ?now)
; =>
;   (ppdefrule select-order)
; )