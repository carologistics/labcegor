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


;(defrule action-send-robotinfo
;  (time $?now)
;  (wm-fact (key central agent robot) (values $?robot_list))
;  ?r_peer <- (refbox-peer (name refbox-public) (peer-id ?peer-id))
;  =>
;  (retract ?r_peer)
;  (bind ?robotinfo (pb-create "llsf_msgs.RobotInfo"))
  ; (pb-set-field ?robotinfo "robots" $?robot_list)
  ; (pb-add-list ?robotinfo "robots" $?robot_list)
  
;  (bind ?index 1)
;  (while (<= ?index (length$ $?robot_list)) do
;    (bind ?current_robot_name (nth$ ?index $?robot_list))
;    (pb-add-list ?robotinfo "robots" ?current_robot_name)
;    (bind ?index (+ ?index 1))
;  )
  
;  (pb-broadcast ?peer-id ?robotinfo)
;  (pb-destroy ?robotinfo)
;)

;(defrule test-send-beaconsignal
;  (time $?now)
;  =>
;  (bind ?tmp (nth$ 2 ?now))
;  (printout t "tmp time: " ?now crlf)
;)


(defrule action-send-beacon-signal
  (time ?now)

  ?bs <- (wm-fact (key refbox beacon seq) (value ?seq))
  (wm-fact (key central agent robot args? r ?robot))
  (wm-fact (key refbox robot task seq args? r ?robot) (value ?task-seq))
  (wm-fact (key config agent team)  (value ?team-name))
  ?r-peer <- (refbox-peer (name refbox-public) (peer-id ?peer-id))
  (wm-fact (key refbox phase) (value SETUP|PRODUCTION))
  ?tf <- (timer (name refbox-beacon) (time ?t&:(> (- ?now ?t) 1)) (seq ?seq))
  (wm-fact (id "/refbox/team-color") (value ?team-color&:(neq ?team-color nil)))
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
  
  (pb-set-field ?beacon "team_color" ?team-color)
  
  (pb-set-field ?beacon "seq" ?seq)
  (pb-broadcast ?peer-id ?beacon)
  (pb-destroy ?beacon)
)

