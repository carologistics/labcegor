(defrule init-yaml-config
  (not (yaml-loaded))
=>
  (bind ?share-dir (ament-index-get-package-share-directory "labcegor_bringup"))
  (config-load (str-cat ?share-dir "/params/game.yaml") "/")
  (assert (yaml-loaded))
  (assert (game-state (team "Carologistics")))
  (assert (game-time 0.)) 

  (assert (taskID 1))
  ;(assert (task "moveInput"))
  (assert (ringsToProduce (blue 0) (green 0) (yellow 0) (orange 0)))
  (assert (fillMachineWithBases (ringStation1 0) (ringStation2 0) (order 0)))
  (assert (robot (name ROBOT1)))
  (assert (currentlyPayed (ringStation1 0) (ringStation2 0)))
  (assert (basesNeededAt (ringStation M-RS1)))
  (assert (taskRobot3 (list 0)));list starts always with 0
  (assert (taskRobot1 (list 0)));list starts always with 0
)
