(define (domain robot-movement)
  (:requirements :strips :typing)
  (:types
    location - object
    robot - object
    team-color - object
    mps - location 
    mps-side - object
    mps-statename - object
    mps-typename - object
    base-color - object
    ring-color - object
    cap-color - object
    complexity - object
    workpiece - object
    order - object
  )
  
  (:constants
    START - location
    INPUT OUTPUT WAIT SLIDE - mps-side
    BS CS DS RS SS - mps-typename
    C0 C1 C2 C3 - complexity
    IDLE BROKEN PREPARED PROCESSING PROCESSED WAIT-IDLE READY-AT-OUTPUT DOWN - mps-statename
  )
  
  (:predicates
    (at ?r - robot ?mps-with-side - location)
    (visited ?loc - location)
    (mps-side-free ?m - mps ?side - mps-side)
    (mps-team ?m - mps ?col - team-color)
    (mps-type ?m - mps ?t - mps-typename)
    (robot-grip-free ?r - robot)
    (robot-grip-busy ?r - robot ?wp - workpiece)
    (mps-state ?m - mps ?statename - mps-statename)
    (bs-prepared-color ?m - mps ?col - base-color)
    (bs-prepared-side ?m - mps ?side - mps-side)
    (ds-prepared-order ?m - mps ?ord - order)
    (rs-prepared-color ?m - mps ?col - ring-color)
  )
  
  (:action move
    :parameters (?from - mps ?from-side - mps-side ?to - mps ?to-side - mps-side ?r - robot)
    :precondition (and (at ?r ?from) 
		       (mps-side-free ?to ?to-side))
    :effect (and (not (at ?r ?from)) 
	         (at ?r ?to)
		 (mps-side-free ?from ?from-side)
		 (not (mps-side-free ?to ?to-side)))
  )
  
  (:action pick-at-slide
    :parameters (?r - robot ?mpswithside - location ?wp - workpiece)
    :precondition (and (robot-grip-free ?r) (at ?r ?mpswithside))
    :effect (and (not (robot-grip-free ?r)) (robot-grip-busy ?r ?wp))
  )
  
  (:action pick-at-output
    :parameters (?r - robot ?mpswithside - location ?m - mps ?wp - workpiece)
    :precondition (and (robot-grip-free ?r) 
		       (at ?r ?mpswithside) 
		       (mps-state ?m READY-AT-OUTPUT))
    :effect (and (not (robot-grip-free ?r)) 
		 (robot-grip-busy ?r ?wp)
		 (not (mps-state ?m READY-AT-OUTPUT))
		 (mps-state ?m IDLE))
  )

 
  (:action place
    :parameters (?r - robot ?wp - workpiece ?mpswithside - location)
    :precondition (and (robot-grip-busy ?r ?wp) (at ?r ?mpswithside))
    :effect (and (robot-grip-free ?r))
  )

  (:action place-at-slide
    :parameters (?r - robot ?wp - workpiece ?mpswithside - location)
    :precondition (and (robot-grip-busy ?r ?wp) (at ?r ?mpswithside))
    :effect (and (robot-grip-free ?r))
  )


  (:action prepare-bs
    :parameters (?m - mps ?side - mps-side ?bc - base-color)
    :precondition (and (mps-type ?m BS) (mps-state ?m IDLE))
    :effect (and (not (mps-state ?m IDLE))
	         (mps-state ?m READY-AT-OUTPUT)
	         (bs-prepared-color ?m ?bc)
	         (bs-prepared-side ?m ?side)
	    )
  )

  (:action prepare-ds
    :parameters (?m - mps ?ord - order)
    :precondition (and (mps-type ?m DS) (mps-state ?m IDLE))
    :effect (and (not (mps-state ?m IDLE)) 
                 (mps-state ?m PREPARED)
	         (ds-prepared-order ?m ?ord)
	    )
  )
  
  (:action prepare-cs
    :parameters (?m - mps)
    :precondition (and (mps-type ?m CS)
                       (mps-state ?m IDLE))
    :effect (and (not (mps-state ?m IDLE))
	         (mps-state ?m READY-AT-OUTPUT)
	    )
  )

  (:action prepare-rs
    :parameters (?m - mps ?rc - ring-color)
    :precondition (and (mps-type ?m RS)
                   (mps-state ?m IDLE))
    :effect (and (not (mps-state ?m IDLE))
             (mps-state ?m READY-AT-OUTPUT)
             (rs-prepared-color ?m ?rc)
            )
  )
)
