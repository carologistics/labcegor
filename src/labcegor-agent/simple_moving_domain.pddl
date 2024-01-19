(define (domain robot-movement)
  (:requirements :strips :typing)
  (:types
    location - object
    robot - object
    team-color - object
    mps - object
    mps-side - object
    mps-typename - object
    base-color - object
    ring-color - object
    cap-color - object
    complexity - object
    workpiece - object
  )

  (:constants
    START - location
    LOC1 - location
    LOC2 - location
    INPUT OUTPUT WAIT - mps-side
    BS CS DS RS SS - mps-typename
    C0 C1 C2 C3 - complexity
  )

  (:predicates
    (at ?r - robot ?x - location)
    (visited ?loc - location)
    (mps-side-free ?m - mps ?side - mps-side)
    (mps-side-approachable ?m - location ?side - mps-side)
    (mps-team ?m - mps ?col - team-color)
    (mps-type ?m - mps ?t - mps-typename)
    (mps-location ?loc - location)
    (robot-at-loc ?r - robot ?loc - location)
    (robot-grip-free ?r - robot)
    (robot-grip-busy ?r - robot ?wp - workpiece)
  )

  (:action move
    :parameters (?from - location ?to - location ?r - robot)
    :precondition (and (at ?r ?from))
    :effect (and (not (at ?r ?from)) (at ?r ?to))
  )

  (:action pick
    :parameters (?r - robot ?wp - workpiece)
    :precondition (and (robot-grip-free ?r))
    :effect (and (not (robot-grip-free ?r)) (robot-grip-busy ?r ?wp))
  )

  (:action place
    :parameters (?r - robot ?wp - workpiece ?loc - location)
    :precondition (and (robot-grip-busy ?r ?wp) (at ?r ?loc))
    :effect (and (robot-grip-free ?r))
  )

)
