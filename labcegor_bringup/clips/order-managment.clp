(deffunction dismantel-order (?order ?team)
  (bind ?id (fact-slot-value ?order id))
  (bind ?refbox-order (fact-slot-value ?order refbox-order))
  ; (bind ?complexity (fact-slot-value ?order complexity))
  (bind ?base (fact-slot-value ?refbox-order base-color))
  (bind ?cap (fact-slot-value ?refbox-order cap-color))
  ; (bind ?rings (fact-slot-value ?order ring_colors))

  ; INSTRUCT base depend on nothing
  ; move_base to cap station depend on buffer cap instruction
  ; move_base cap shelf to input
  ; INSTRUCT buffer cap
  ; move_base output cap to delivery station
  ; INSTRUCT MOUNT CAP
  (if (eq ?cap CAP_BLACK) 
    then
      (if (eq ?team CYAN) then (bind ?cs_machine C-CS2) else (bind ?cs_machine M-CS1)) ;; TODO PROBABLY WRONG COLOR
    else
      (if (eq ?team CYAN) then (bind ?cs_machine C-CS1) else (bind ?cs_machine M-CS1))
  )
  (if (eq ?team CYAN) then (bind ?bs_machine C-BS) else (bind ?bs_machine M-BS))
  (if (eq ?team CYAN) then (bind ?bs_machine C-DS) else (bind ?ds_machine M-DS))
  (if (eq ?team CYAN) then (bind ?rs1_machine C-RS1) else (bind ?rs1_machine M-RS1))
  (bind ?dispense (assert (instruct (operation DISPENSE-BASE) (machine ?bs_machine) (side OUTPUT) (base_color ?base) (team ?team))))
  (bind ?shelf_to_cs (assert (move_base (from ?cs_machine) (from_side SHELF) (target ?cs_machine))))
  (bind ?buffer (assert (instruct (operation RETRIEVE_CAP) (machine ?cs_machine) (depend_on ?shelf_to_cs) (team ?team))))
  (bind ?bs_to_cs (assert (move_base (from ?bs_machine) (target ?cs_machine) (depend_on ?dispense ?buffer))))
  (bind ?cs_to_rs (assert (move_base (from ?cs_machine) (target ?rs1_machine) (target_side SLIDE) (depend_on ?buffer))))
  (bind ?mount_cap (assert (instruct (operation MOUNT_CAP) (machine ?cs_machine) (depend_on ?cs_to_rs ?bs_to_cs) (team ?team))))
  (bind ?cs_to_ds (assert (move_base (from ?cs_machine) (target ?ds_machine) (depend_on ?mount_cap))))
  (bind ?deliver (assert (instruct (operation DELIVER) (machine ?ds_machine) (order_id ?id) (depend_on ?cs_to_ds) (team ?team))))
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