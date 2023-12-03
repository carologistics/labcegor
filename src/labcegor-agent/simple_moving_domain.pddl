(define (domain robot-movement)
  (:requirements :strips :typing)
  (:types
    location - object
    robot - object
  )
  
  (:predicates
    (at ?r - robot ?x - location)
    (connected ?x ?y - location)
  )
 
  (:constants
     start-pos pos-1-2 pos-1-3 pos-2-1 pos-2-2 pos-2-3 pos-3-1 pos-3-2 pos-3-3 - location
  )
 
  (:action move
    :parameters (?from - location ?to - location ?r - robot)
    :precondition (and (at ?r ?from) (connected ?from ?to))
    :effect (and (not (at ?r ?from)) (at ?r ?to))
  )
  
  ; (:action move-random ; instant movement
  ;   :parameters (?from - location ?r - robot ?to - location)
  ;   :precondition (at ?r ?from)
  ;   :effect (and 
  ;             (not (at ?r ?from))
  ;             (at ?r ?to) ; Note: ?to is a free variable, indicating a random location
  ;             (forall (?l - location) (when (not (= ?l ?to)) (not (at ?r ?l)))) ; Ensure no other location is true
  ;           )
  ; )
)

