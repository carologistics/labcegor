(deffunction create-beacon-msg (?robot-name ?time)
  (bind ?name-length (str-length (str-cat ?robot-name)))
  (bind ?robot-number (string-to-field (sub-string ?name-length ?name-length (str-cat ?robot-name))))
  (bind ?beacon (pb-create "llsf_msgs.BeaconSignal"))
  (bind ?beacon-time (pb-field-value ?beacon "time"))
  (pb-set-field ?beacon-time "sec" (nth$ 1 ?time))
  (pb-set-field ?beacon-time "nsec" (* (nth$ 2 ?time) 1000))
  (pb-set-field ?beacon "time" ?beacon-time) ; destroys ?beacon-time!
  ; (pb-set-field ?beacon "team_name" ?team-name)
  ; TODO: robot-name as peer? why?
  (pb-set-field ?beacon "peer_name" ?robot-name)
  ; (pb-set-field ?beacon "team_color" ?team-color)
  (pb-set-field ?beacon "number" ?robot-number)

  (bind ?trans (create$ 0 0))
  (bind ?ori (create$ 0 0 0 1))
  (bind ?ptime ?time)
  ;(if (not (do-for-fact ((?pose Position3DInterface)) (eq ?pose:id (remote-if-id ?robot-name "Pose"))
  ;                      (bind ?trans ?pose:translation)
  ;                      (bind ?ptime ?pose:time)))
  ; then
  ;  ; We do not have a correct Pose, fake it using the position of the machine we're at
  ;  (do-for-fact ((?at wm-fact) (?node navgraph-node))
  ;               (and (wm-key-prefix ?at:key (create$ domain fact at args? r (sym-cat ?robot-name)))
  ;                    (eq ?node:name (wm-fact-to-navgraph-node ?at:key)))
  ;               (bind ?trans ?node:pos)
  ;  )
  ;)
  (bind ?beacon-pose (pb-field-value ?beacon "pose"))
  (pb-set-field ?beacon-pose "x" (nth$ 1 ?trans))
  (pb-set-field ?beacon-pose "y" (nth$ 2 ?trans))
  ;(pb-set-field ?beacon-pose "ori" (tf-yaw-from-quat ?ori))
  (bind ?beacon-pose-time (pb-field-value ?beacon-pose "timestamp"))
  (pb-set-field ?beacon-pose-time "sec" (nth$ 1 ?ptime))
  (pb-set-field ?beacon-pose-time "nsec" (* (nth$ 2 ?ptime) 1000))
  (pb-set-field ?beacon-pose "timestamp" ?beacon-pose-time)
  (pb-set-field ?beacon "pose" ?beacon-pose)
  (return ?beacon)
)


(defrule action-send-beacon-signal
   (time ?now)
   ?bs <- (wm-fact (key refbox beacon seq) (value ?seq))
   (wm-fact (key central agent robot args? r ?robot))
   (wm-fact (key refbox robot task seq args? r ?robot) (value ?task-seq))
   (wm-fact (key config agent team)  (value ?team-name))
   ?r-peer <- (refbox-peer (name refbox-private) (peer-id ?peer-id))
   (wm-fact (key refbox phase) (value SETUP|PRODUCTION))
   ?tf <- (timer (name refbox-beacon) (time ?t&:(> (- ?now ?t) 1)) (seq ?seq))
   =>
   (bind ?bs (modify ?bs (value (+ ?seq 1))))
   (bind ?beacon (pb-create "llsf_msgs.BeaconSignal"))
   (bind ?beacon-time (pb-field-value ?beacon "time"))
   (pb-set-field ?beacon-time "sec" (integer ?now))
   (pb-set-field ?beacon-time "nsec" (integer (mod (* ?now 1000000) 1000000)))
   (pb-set-field ?beacon "time" ?beacon-time) ; destroys ?beacon-time!
   (pb-set-field ?beacon "peer_name" ?robot)
   (bind ?name-length (str-length (str-cat ?robot)))
   (bind ?robot-number (string-to-field (sub-string ?name-length ?name-length (str-cat ?robot))))
   (pb-set-field ?beacon "number" ?robot-number)
   (pb-set-field ?beacon "team_name" ?team-name)
   (pb-set-field ?beacon "team_color" CYAN)
 
   (pb-set-field ?beacon "seq" ?seq)
   (pb-broadcast ?peer-id ?beacon)
   (pb-destroy ?beacon)
   (modify ?tf (time ?now) (seq (+ ?seq 1)))
)


(defrule refbox-action-prepare-mps-start
  (time ?now)
  ?pa <- (plan-action (plan-id ?plan-id) (goal-id ?goal-id) (id ?id)
                      (state PENDING)
                      (action-name ?action&prepare_bs|
                                           prepare_cs|
                                           prepare_ds|
                                           prepare_rs)
                      (executable TRUE)
                      (param-names $?param-names)
                      (param-values $?param-values))
  (wm-fact (key refbox team-color) (value ?team-color&:(neq ?team-color nil)))
  ?r-peer <- (refbox-peer (name refbox-private) (peer-id ?peer-id))
  =>
  (bind ?mps (nth$ 1 ?param-values))
  (bind ?instruction_info (rest$ ?param-values))
  (printout t "Executing " ?action ?param-values crlf)
  (assert (metadata-prepare-mps ?mps ?team-color ?peer-id ?instruction_info))
  (assert (timer (name (sym-cat prepare- ?goal-id - ?plan-id
                                - ?id -send-timer))
          (time ?now) (seq 1)))
  (assert (timer (name (sym-cat prepare- ?goal-id - ?plan-id
                                - ?id -abort-timer))
          (time ?now) (seq 1)))
  (modify ?pa (state RUNNING))
)

(deftemplate plan-action-sent
  (slot plan-id (type INTEGER))
)

(defrule refbox-action-mps-prepare-send-signal
  ; (declare (salience ?*SALIENCE-LOW*))
  ?pa <- (plan-action (plan-id ?plan-id) (goal-id ?goal-id) (id ?id)
                      (state RUNNING)
                      (action-name prepare_bs|
                                   prepare_cs|
                                   prepare_ds|
                                   prepare_rs)
                      (executable TRUE)
                      (param-names $?param-names)
                      (param-values $?param-values))
  ; (domain-obj-is-of-type ?mps&:(eq ?mps (plan-action-arg m
  ;                                                        ?param-names
  ;                                                        ?param-values))
  ;                         mps)
  (not (plan-action-sent (plan-id ?id)))
  (metadata-prepare-mps ?mps ?team-color ?peer-id $?instruction_info)
  (wm-fact (key domain fact mps-type args? m ?mps t ?mps-type) (value TRUE))
  (protobuf-msg (type "llsf_msgs.MachineInfo"))
  (machine (name ?mps) (state ~DOWN))
  =>
  (bind ?machine-instruction (pb-create "llsf_msgs.PrepareMachine"))
  (pb-set-field ?machine-instruction "team_color" ?team-color)
  (pb-set-field ?machine-instruction "machine" (str-cat ?mps))
  
  (switch ?mps-type
    (case BS
      then
        (bind ?bs-inst (pb-create "llsf_msgs.PrepareInstructionBS"))
        (pb-set-field ?bs-inst "side" (nth$ 1 ?instruction_info))
        (pb-set-field ?bs-inst "color" (nth$ 2 ?instruction_info))
        (pb-set-field ?machine-instruction "instruction_bs" ?bs-inst)
    )
    (case RS
      then
        (bind ?rs-inst (pb-create "llsf_msgs.PrepareInstructionRS"))
        (pb-set-field ?rs-inst "ring_color" (nth$ 1 ?instruction_info) )
        (pb-set-field ?machine-instruction "instruction_rs" ?rs-inst)
    )
    (case CS
      then
      	(bind ?cs-inst (pb-create "llsf_msgs.PrepareInstructionCS"))
        (pb-set-field ?cs-inst "operation" (nth$ 1 ?instruction_info))
        (pb-set-field ?machine-instruction "instruction_cs" ?cs-inst)
    )
    (case DS
      then
        (bind ?ds-inst (pb-create "llsf_msgs.PrepareInstructionDS"))
        (bind ?order (nth$ 1 ?instruction_info))
        ; (bind ?order-id (float (string-to-field (sub-string 2 (length$ (str-cat ?order)) (str-cat ?order)))))
        (bind ?order-id (float ?order))
        (pb-set-field ?ds-inst "order_id" ?order-id)
        (pb-set-field ?machine-instruction "instruction_ds" ?ds-inst)
    )
  )
  (pb-broadcast ?peer-id ?machine-instruction)
  (pb-destroy ?machine-instruction)
  (printout t "Sent Prepare Msg for " ?mps " with " ?instruction_info  crlf) 
  (assert (plan-action-sent (plan-id ?id)))
  ; (retract ?pb-msg)
)


(defrule refbox-action-prepare-mps-final
  "Finalize the prepare action if the desired machine state was reached"
  (time ?now)
  ?pa <- (plan-action (plan-id ?plan-id) (goal-id ?goal-id) (id ?id)
                      (state RUNNING)
                      (action-name prepare_bs|
                                   prepare_cs|
                                   prepare_ds|
                                   prepare_rs)
                      (param-names $?param-names)
                      (param-values $?param-values))
  ?st <- (timer (name ?nst&:(eq ?nst
                               (sym-cat prepare- ?goal-id - ?plan-id
                                        - ?id -send-timer))))
  ?at <- (timer (name ?nat&:(eq ?nat
                               (sym-cat prepare- ?goal-id - ?plan-id
                                        - ?id -abort-timer))))
  ?md <- (metadata-prepare-mps ?mps $?date)
  ; (machine (name ?mps) (state READY-AT-OUTPUT|WAIT-IDLE|PROCESSED|PREPARED))
  (machine (name ?mps) (state READY-AT-OUTPUT|WAIT-IDLE|PROCESSED))
  ?plan-action-sent <- (plan-action-sent (plan-id ?id))
  =>
  (printout t "Action Prepare " ?mps " is final" crlf)
  (retract ?st ?at ?md ?plan-action-sent)
  (modify ?pa (state EXECUTION-SUCCEEDED))
)

;(defrule refbox-action-prepare-mps-final-ds-special-case
;  "Finalize the prepare action if the desired machine state was reached"
;  (time ?now)
;  ?pa <- (plan-action (plan-id ?plan-id) (goal-id ?goal-id) (id ?id)
;                      (state RUNNING)
;                      (action-name prepare_ds)
;                      (param-names $?param-names)
;                      (param-values $?param-values))
;  ?st <- (timer (name ?nst&:(eq ?nst
;                               (sym-cat prepare- ?goal-id - ?plan-id
;                                        - ?id -send-timer))))
;  ?at <- (timer (name ?nat&:(eq ?nat
;                               (sym-cat prepare- ?goal-id - ?plan-id
;                                        - ?id -abort-timer))))
;  ?md <- (metadata-prepare-mps ?mps $?date)
;  (machine (name ?mps) (state READY-AT-OUTPUT|WAIT-IDLE|PROCESSED|PREPARED))
;  ?plan-action-sent <- (plan-action-sent (plan-id ?id))
;  =>
;  (printout t "Action Prepare " ?mps " is final" crlf)
;  (retract ?st ?at ?md ?plan-action-sent)
;  (modify ?pa (state EXECUTION-SUCCEEDED))
;)

(defrule refbox-action-prepare-mps-abort-on-broken
  "Abort preparing if the mps got broken"
  ?pa <- (plan-action (plan-id ?plan-id) (goal-id ?goal-id) (id ?id)
                      (state RUNNING)
                      (action-name prepare_bs|
                                   prepare_cs|
                                   prepare_ds|
                                   prepare_rs)
                      (param-names $?param-names)
                      (param-values $?param-values))
  ?st <- (timer (name ?nst&:(eq ?nst
                               (sym-cat prepare- ?goal-id - ?plan-id
                                        - ?id -send-timer))))
  ?at <- (timer (name ?nat&:(eq ?nat
                               (sym-cat prepare- ?goal-id - ?plan-id
                                        - ?id -abort-timer))))
  ?md <- (metadata-prepare-mps ?mps $?date)
  (machine (name ?mps) (state BROKEN))
  =>
  (printout t "Action Prepare " ?mps " is Aborted because mps is broken" crlf)
  (retract ?st ?md ?at)
  (modify ?pa (state EXECUTION-FAILED))
)
