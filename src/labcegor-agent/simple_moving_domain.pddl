(define (domain robot-movement)
  (:requirements :strips :typing)
  (:types
    location - object
    robot - object
  )

  (:constants
    START - location
    LOC1 - location
    LOC2 - location
  )

  (:predicates
    (at ?r - robot ?x - location)
    (visited ?x - location)
  )

  (:action move
    :parameters (?from - location ?to - location ?r - robot)
    :precondition (and (at ?r ?from))
    :effect (and (not (at ?r ?from)) (at ?r ?to) (visited ?from))
  )
)
