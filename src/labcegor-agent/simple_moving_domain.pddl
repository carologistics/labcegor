(define (domain robot-movement)
  (:requirements :strips :typing)
  (:types
    location - object
    robot - object
  )

  (:constants
    start-pos - location 
    pos-1-2 - location
    pos-1-3 - location
    pos-2-1 - location
    pos-2-2 - location
    pos-2-3 - location
    pos-3-1 - location
    pos-3-2 - location
    pos-3-3 - location
  )

  (:predicates
    (at ?r - robot ?x - location)
    (connected ?x - location ?y - location)
  )

  (:action move
    :parameters (?from - location ?to - location ?r - robot)
    :precondition (and (at ?r ?from) (connected ?from ?to))
    :effect (and (not (at ?r ?from)) (at ?r ?to))
  )
)
