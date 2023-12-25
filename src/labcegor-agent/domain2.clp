
(defrule load-domain
  (executive-init)
  (not (domain-loaded))
=>
  (parse-pddl-domain (path-resolve "labcegor-agent/simple_moving_domain.pddl"))
  (assert (domain-loaded))
)



(defrule domain-load-initial-facts
" Load all initial domain facts on startup of the game "
  (domain-loaded)
  =>
  (printout info "Initializing worldmodel" crlf)
  (foreach ?robot (create$ robot1 robot2 robot3)
    (assert
      (domain-object (name ?robot) (type robot))
      (domain-fact (name at) (param-values ?robot START))
    )
  )
  (assert (domain-object (name LOC1) (type location)))
  (assert (domain-object (name LOC2) (type location)))
  (assert (domain-object (name START) (type location)))
  (assert (domain-facts-loaded))
)

;(defrule goal-visitall-formulate
;  (domain-facts-loaded)
;  (not (goal (class VISITALL))
;  =>
;  (assert
;    (goal
;      (id VISITALL1)
;      (class VISITALL)
;      (params)
;    ) 
;  )
;)
