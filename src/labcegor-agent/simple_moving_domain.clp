(defrule load-domain
    (not (domain-loaded))
    (wm-fact (id "/refbox/phase") (value $?))
    (wm-fact (id "/refbox/state") (value $?))
    => 
    (parse-pddl-domain (path-resolve "labcegor-agent/complex_moving_domain.pddl"))
    (assert (domain-loaded))
    (printout t "successfully load domain" crlf)
)

(defrule domain-set-sensedpredicates
  (domain-loaded)
  ?p <- (domain-predicate (name mps-state) (sensed FALSE))
  =>
  (modify ?p (sensed TRUE))
)

(defrule domain-nowait-actions
  (domain-loaded)
  ?o <- (domain-operator (name place|place_at_slide|prepare_bs|prepare_rs|prepare_ds|prepare_cs) (wait-sensed ~FALSE))
  =>
  (modify ?o (wait-sensed FALSE))
)


(defrule domain-load-initial-facts
    (domain-loaded)
    (wm-fact (id "/refbox/phase") (value SETUP))
    (wm-fact (key refbox state) (value $?))
    (not (domain-init))
    =>
    (printout t "in the production phase, start initializing domain facts ..." crlf)

    (foreach ?robot (create$ robot1 robot2)
        (assert (domain-object (name ?robot) (type robot)))
        (assert (domain-fact (name at) (param-values ?robot START)))
        (assert (wm-fact (key central agent robot args? r ?robot)))
        (assert (domain-fact (name visited) (param-values START)))
        (assert (domain-fact (name robot-at-loc) (param-values ?robot START)))
	(assert (domain-fact (name robot-grip-free) (param-values ?robot)))
     )
    (assert (wm-fact (key all robot) (values robot1 robot2 robot3)))


    (bind ?team-color CYAN)
    (if (eq ?team-color CYAN)
    then
        (bind ?bs C-BS)
        (bind ?cs1 C-CS1)
        (bind ?cs2 C-CS2)
        (bind ?rs1 C-RS1)
        (bind ?rs2 C-RS2)
        (bind ?ds C-DS)
        (bind ?ss C-SS)
    else
        (bind ?bs M-BS)
        (bind ?cs1 M-CS1)
        (bind ?cs2 M-CS2)
        (bind ?rs1 M-RS1)
        (bind ?rs2 M-RS2)
        (bind ?ds M-DS)
        (bind ?ss M-SS)
    )
    (bind ?input-side INPUT)
    (bind ?output-side OUTPUT)
    (bind ?wait-side WAIT)
    (foreach ?mps (create$ ?bs ?cs1 ?cs2 ?rs1 ?rs2 ?ds ?ss)
      (assert
        (domain-fact (name mps-side-free) (param-values ?mps INPUT))
        (domain-fact (name mps-side-free) (param-values ?mps OUTPUT))
        (domain-fact (name mps-side-free) (param-values ?mps WAIT))
	(domain-fact (name mps-state) (param-values ?mps IDLE))
      )
      (foreach ?side (create$ ?input-side ?output-side ?wait-side)  
        (bind ?mps-side (sym-cat ?mps ?side))
        (assert (domain-fact (name mps-location) (param-values ?mps-side)))
      )
    )
    (assert (domain-fact (name mps-type) (param-values ?bs BS))
	    (domain-fact (name mps-type) (param-values ?cs1 CS))	
	    (domain-fact (name mps-type) (param-values ?cs2 CS))	
	    (domain-fact (name mps-type) (param-values ?rs1 RS))	
	    (domain-fact (name mps-type) (param-values ?rs2 RS))	
	    (domain-fact (name mps-type) (param-values ?ds DS))	
    )

    (printout t "initialization complete." crlf)
)
