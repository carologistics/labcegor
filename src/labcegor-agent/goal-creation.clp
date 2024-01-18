(deffunction is-machine-free()
)

(defrule goal-creation-prepare-cap
    "cap carrier from shelf -> input"
    ?g <- (goal (id ?goal-id) (class PREPARE-CAPS)(mode FORMULATED))
    (wm-fact (key refbox team-color) (value ?team-color))
    (wm-fact (key domain fact wp-on-shelf args? wp ?cc m ?mps spot ?spot))
    (wm-fact (key domain fact wp-cap-color args? wp ?cc color ?cap-color))

    (wm-fact (key domain fact self args? r ?robot))
    (not (wm-fact (key domain fact holding args? r ?robot wp ?wp-h)))

    (wm-fact (key domain fact mps-type args? m ?mps t CS))
    (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))
    (not (wm-fact (key domain fact wp-at args? wp ?wp-a m ?mps side INPUT)))
    =>
    (printout t "Goal " FILL-CAP " formulated" crlf)

    (assert (goal (id (sym-cat FILL-CAP- (gensym*)))
                (class FILL-CAP) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        mps ?mps
                        cc ?cc
                )
                (required-resources (sym-cat ?mps -INPUT) ?cc)
  ))
)

(defrule goal-creation-rmv-capless-carriers
    " Remove a capless capcarrier from the output of a CS"

  (goal (id ?goal-id) (class CAP-CLEAR) (mode FORMULATED))
  (wm-fact (key refbox team-color) (value ?team-color))
  
  (wm-fact (key domain fact self args? r ?robot))
  (not (wm-fact (key domain fact holding args? r ?robot wp ?wp-h)))
 
  (wm-fact (key domain fact mps-type args? m ?mps t CS))
  (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))

  (wm-fact (key domain fact wp-at args? wp ?wp m ?mps side OUTPUT))
  (wm-fact (key domain fact wp-cap-color args? wp ?wp col CAP_NONE))
  =>
  (printout t "Goal " CLEAR-MPS " ("?mps") formulated" crlf)

  (assert (goal (id (sym-cat CLEAR-MPS- (gensym*)))
                (class CLEAR-MPS) (sub-type SIMPLE)
                (priority ?prio)
                (parent ?production-id)
                (params robot ?robot
                        mps ?mps
                        wp ?wp
                        side OUTPUT
                )
                (required-resources (sym-cat ?mps -OUTPUT) ?wp)
    ))
)

(defrule goal-creation-clear-bs
  "Take wp -> BS OUTPUT"
  
  (goal (id ?goal-id) (class GETBASE) (mode FORMULATED))
  (wm-fact (key refbox team-color) (value ?team-color))
  
  (wm-fact (key domain fact self args? r ?robot))
  (not (wm-fact (key domain fact holding args? r ?robot wp ?wp-h)))

  (wm-fact (key domain fact mps-type args? m ?mps t BS))
  (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))
  
  (wm-fact (key domain fact wp-at args? wp ?wp m ?mps side ?side))
  =>
  (printout t "Goal " BSOUT " ("?mps") formulated" crlf)
  (assert (goal (id (sym-cat BSOUT- (gensym*)))
                (class BSOUT) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        mps ?mps
                        wp ?wp
                        side ?side
                )
                (required-resources (sym-cat ?mps - ?side) ?wp)
  ))
)

(defrule goal-creation-get-base-to-rs
  "Fill the ring station with a base from the base station."

  (or (goal (id ?goal-id) (class PREPARE-RINGS) (mode FORMULATED))
      (goal (id ?goal-id) (class GET-TO-FILL-RS) (mode FORMULATED))
  )
  (wm-fact (key refbox team-color) (value ?team-color))
  
  (wm-fact (key domain fact self args? r ?robot))
  (not (wm-fact (key domain fact holding args? r ?robot wp ?wp-h)))

  ;RS 
  (wm-fact (key domain fact mps-type args? m ?mps t RS))
  (wm-fact (key domain fact mps-team args? m ?mps color ?team-color))
  (wm-fact (key domain fact rs-filled-with args? m ?mps n ?rs-before&ZERO|ONE|TWO))

  ;BS
  (wm-fact (key domain fact mps-type args? m ?bs t BS))
  (wm-fact (key domain fact mps-team args? m ?bs color ?team-color))
  (domain-object (name ?bs-side&:(or (eq ?bs-side INPUT) (eq ?bs-side OUTPUT))) (type mps-side))

  (wm-fact (key domain fact order-base-color args? ord ?order color ?base-color))
  
  ; check fr existing goal
  (not (goal (class GET-BASE-TO-RS) (parent ?goal-id)
                                         (params robot ?robot
                                          bs ?bs
                                          bs-side ?bs-side
                                          base-color ?
                                          wp ?wp)))
  =>
  (printout t "Goal " GET-BASE-TO-RS " formulated" crlf)
  (assert (goal (id (sym-cat GET-BASE-TO-RS- (gensym*)))
                (class GET-BASE-TO-RS)
                (parent ?goal-id) (sub-type SIMPLE)
                             (params robot ?robot
                                     bs ?bs
                                     bs-side ?bs-side
                                     base-color ?base-color
                                     wp ?wp
                                     )
                            (required-resources ?wp)
  ))
)


(defrule goal-creation-prefill-ring-station
  "Fill a ring station with the currently holding workpiece"

  (goal (id ?goal-id) (class PREPARE-RINGS) (mode FORMULATED))
  (wm-fact (key refbox team-color) (value ?team-color))
  ;Robot
  (wm-fact (key domain fact self args? r ?robot))
  (wm-fact (key domain fact wp-usable args? wp ?wp))
  (wm-fact (key domain fact holding args? r ?robot wp ?wp-h))
  ;MPS-RS
  (wm-fact (key domain fact mps-type args? m ?mps t RS))
  (wm-fact (key domain fact mps-team args? m ?mps col ?team-color))
  (wm-fact (key domain fact rs-filled-with args? m ?mps n ?rs-before&ZERO|ONE|TWO))
  (wm-fact (key domain fact rs-inc args? summand ?rs-before sum ?rs-after))
  =>
  (printout t "Goal " FILL-RS " formulated" crlf)
  (assert (goal (id (sym-cat FILL-RS- (gensym*)))
                (class FILL-RS) (sub-type SIMPLE)
                (parent ?goal-id)
                (params robot ?robot
                        mps ?mps
                        wp ?wp
                        rs-before ?rs-before
                        rs-after ?rs-after
                )
                (required-resources ?mps ?wp (sym-cat ?mps -FILL))
  ))
)