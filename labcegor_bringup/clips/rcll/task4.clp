(defrule send-robot-task
  "Send a movement task to a robot"
  (robot (state ACTIVE) (name ?robot-name))
  (game-state (state RUNNING))
  =>
  (printout t "Sending move command to " ?robot-name crlf)
  (bind ?task (pb-create "llsf_msgs.AgentTask"))
  (pb-field-set ?task "task_id" 1)
  (pb-field-set ?task "robot_id" 101)
  (pb-field-create-message ?task "move")
  (pb-field-set ?task "move.waypoint" "Zone1")
  (pb-send-message ?task)
)