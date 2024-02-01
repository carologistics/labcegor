; (defglobal ?*robot-name-list* = (create$))

(defrule load-domain
    (not (domain-loaded))
    (wm-fact (id "/refbox/phase") (value $?))
    (wm-fact (id "/refbox/state") (value $?))
  => 
    (parse-pddl-domain (path-resolve "labcegor-agent/simple_moving_domain.pddl"))
    (assert (domain-loaded))
    (printout t "successfully load domain" crlf)
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
     )
    
    (assert (wm-fact (key all robot) (values robot1 robot2 robot3)))

    ; (do-for-all-facts ((?robot ?robot-value) (IN ?robot (create$ robot1 robot2 robot3)))
    ;     (assert (domain-fact (name at) (param-values ?robot start-pos)))
    ;     (bind ?*robot-name-list* (insert$ ?*robot-name-list* 1 ?robot))
    ; )
    ; (assert (wm-fact (key central agent robot) (values ?*robot-name-list*)))

    (bind ?team-color MAGENTA)
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
        (domain-fact (name mps-side-approachable) (param-values ?mps INPUT))
        (domain-fact (name mps-side-approachable) (param-values ?mps OUTPUT))
        (domain-fact (name mps-side-approachable) (param-values ?mps WAIT))
      )
      (foreach ?side (create$ ?input-side ?output-side ?wait-side)  
        (bind ?mps-side (sym-cat ?mps ?side))
        (assert (domain-fact (name mps-location) (param-values ?mps-side)))
      )
    )

    ;(do-for-all-facts ((?wm-fact wm-fact))
    ;  (wm-key-prefix ?wm-fact:key (create$ domain fact mps-side-free)
    ;  )
    ;  (printout t "mps side free: " ?wm-fact crlf)

    ;)

    (assert (domain-fact (name mps-team) (param-values ?bs ?team-color))
            (domain-fact (name mps-team) (param-values ?ds ?team-color))
            (domain-fact (name mps-team) (param-values ?ss ?team-color))
            (domain-fact (name mps-team) (param-values ?cs1 ?team-color))
            (domain-fact (name mps-team) (param-values ?cs2 ?team-color))
            (domain-fact (name mps-team) (param-values ?rs1 ?team-color))
            (domain-fact (name mps-team) (param-values ?rs2 ?team-color))
            (domain-fact (name mps-type) (param-values C-BS BS))
            (domain-fact (name mps-type) (param-values C-DS DS))
            (domain-fact (name mps-type) (param-values C-SS SS))
            (domain-fact (name mps-type) (param-values C-CS1 CS))
            (domain-fact (name mps-type) (param-values C-CS2 CS))
            (domain-fact (name mps-type) (param-values C-RS1 RS))
            (domain-fact (name mps-type) (param-values C-RS2 RS))
            (domain-fact (name mps-type) (param-values M-BS BS))
            (domain-fact (name mps-type) (param-values M-DS DS))
            (domain-fact (name mps-type) (param-values M-SS SS))
            (domain-fact (name mps-type) (param-values M-CS1 CS))
            (domain-fact (name mps-type) (param-values M-CS2 CS))
            (domain-fact (name mps-type) (param-values M-RS1 RS))
            (domain-fact (name mps-type) (param-values M-RS2 RS))
            (domain-facts-loaded)
            (domain-init)
    )
    (printout t "initialization complete." crlf)
)
