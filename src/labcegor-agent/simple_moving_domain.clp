(defrule load-domain
    (not (domain-loaded))
    ; ?r_phase <- (refbox-phase (value SETUP))
    ?r_phase <- (wm-fact (id "/refbox/phase") (value SETUP))
  => 
    (parse-pddl-domain (path-resolve "labcegor-agent/simple_moving_domain.pddl"))
    (assert (domain-loaded))
    (retract ?r_phase)
    (printout t "successfully load domain" crlf)
)


(defrule domain-load-initial-facts
    (domain-loaded)
    ?r_phase2 <- (wm-fact (id "/refbox/phase") (value PRODUCTION))
    ?r_state2 <- (wm-fact (key refbox state) (value $?))
    (not (domain-init))
    =>
    (printout t "in the production phase, start initializing domain facts ..." crlf)
    (retract ?r_phase2 ?r_state2)
    ; (retract ?r_phase2)
    (foreach ?robot (create$ robot1 robot2 robot3)
        (assert (domain-fact (name at) (param-values ?robot start-pos)))
        )
    (assert 
        (domain-fact (name connected) (param-values start-pos pos-2-1))
        (domain-fact (name connected) (param-values start-pos pos-1-2))
        (domain-fact (name connected) (param-values start-pos pos-2-2))
        
        (domain-fact (name connected) (param-values pos-1-2 start-pos))
        (domain-fact (name connected) (param-values pos-1-2 pos-2-2))
	(domain-fact (name connected) (param-values pos-1-2 pos-1-3))
	(domain-fact (name connected) (param-values pos-1-2 pos-2-1))
	(domain-fact (name connected) (param-values pos-1-2 pos-2-3))
        
        (domain-fact (name connected) (param-values pos-1-3 pos-1-2))
        (domain-fact (name connected) (param-values pos-1-3 pos-2-3))
        (domain-fact (name connected) (param-values pos-1-3 pos-2-2))

        (domain-fact (name connected) (param-values pos-2-1 start-pos))
	(domain-fact (name connected) (param-values pos-2-1 pos-1-2))
	(domain-fact (name connected) (param-values pos-2-1 pos-2-2))
	(domain-fact (name connected) (param-values pos-2-1 pos-3-1))
	(domain-fact (name connected) (param-values pos-2-1 pos-3-2))

	(domain-fact (name connected) (param-values pos-2-2 pos-2-1))
	(domain-fact (name connected) (param-values pos-2-2 pos-2-3))
	(domain-fact (name connected) (param-values pos-2-2 pos-1-2))
	(domain-fact (name connected) (param-values pos-2-2 pos-3-2))
	(domain-fact (name connected) (param-values pos-2-2 pos-3-1))
	(domain-fact (name connected) (param-values pos-2-2 pos-3-3))
	(domain-fact (name connected) (param-values pos-2-2 pos-1-3))
	(domain-fact (name connected) (param-values pos-2-2 start-pos))

        (domain-fact (name connected) (param-values pos-2-3 pos-1-3))
        (domain-fact (name connected) (param-values pos-2-3 pos-1-2))
        (domain-fact (name connected) (param-values pos-2-3 pos-2-2))
        (domain-fact (name connected) (param-values pos-2-3 pos-3-2))
        (domain-fact (name connected) (param-values pos-2-3 pos-3-3))

        (domain-fact (name connected) (param-values pos-3-1 pos-2-1))
        (domain-fact (name connected) (param-values pos-3-1 pos-2-2))
        (domain-fact (name connected) (param-values pos-3-1 pos-3-2))


        (domain-fact (name connected) (param-values pos-3-2 pos-2-1))
        (domain-fact (name connected) (param-values pos-3-2 pos-2-2))
        (domain-fact (name connected) (param-values pos-3-2 pos-2-3))
        (domain-fact (name connected) (param-values pos-3-2 pos-3-1))
        (domain-fact (name connected) (param-values pos-3-2 pos-3-3))
        

        (domain-fact (name connected) (param-values pos-3-3 pos-3-2))
        (domain-fact (name connected) (param-values pos-3-3 pos-2-3))
        (domain-fact (name connected) (param-values pos-3-3 pos-2-2))
    )
    (assert (domain-facts-loaded))
    (assert (domain-init))
)
