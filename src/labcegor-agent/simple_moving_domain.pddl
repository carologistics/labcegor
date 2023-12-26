(define (domain robot-movement)
  (:requirements :strips :typing)
  (:types
    location - object
    robot - object
    team-color - object
    mps-side - object
    mps-typename - object
  )

  (:constants
    START - location
    LOC1 - location
    LOC2 - location
    INPUT OUTPUT WAIT - mps-side
    BS CS DS RS SS - mps-typename
  )

  (:predicates
    (at ?r - robot ?x - location)
    (visited ?r - robot ?loc - location)
    (mps-side-free ?m - mps ?side - mps-side)
    (mps-side-approachable ?m - location ?side - mps-side)
    (mps-team ?m - mps ?col - team-color)
    (mps-type ?m - mps ?t - mps-typename)
    (mps-location ?loc - location)
  )

  (:action move
    :parameters (?from - location ?to - location ?r - robot)
    :precondition (and (at ?r ?from))
    :effect (and (not (at ?r ?from)) (at ?r ?to))
  )
)
