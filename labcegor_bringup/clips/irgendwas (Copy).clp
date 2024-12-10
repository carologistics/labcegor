;(deftemplate turtle
;  (slot linearVelocity(type FLOAT))
;  (slot angularVelocity(type FLOAT))
;  (slot posX(type FLOAT))
;  (slot posY(type FLOAT))
;)

(deftemplate turtle
  (slot topic (type STRING))
)


(defglobal ?*x* = 3)
(deffacts my-init-Fact
  (initial-fact)
)

(defrule my-rule 
  (initial-fact)
=>
  (printout green “Hello” crlf)

(printout green (+ 2 ?*x*) crlf)
)




(defrule hw
    (f ?x)
=>
    (printout green ?x crlf))

; Facts:
(deffacts families
  (father tom john) ; tom is father of john
  (mother susan john) ; susan is mother of john
  (father george tom)) ; george is father of tom
; Rules:
(defrule parent-rule
  (or (father ?x ?y) (mother ?x ?y))
 =>
  (assert (parent ?x ?y)))
(defrule grandparent-rule
  (and (parent ?x ?y) (parent ?y ?z))
 =>
  (assert (grandparent ?x ?z)))
(defrule grandfather-rule
  (and (father ?x ?y) (parent ?y ?z))
 =>
 (assert (grandfather ?x ?z)))

(defrule my-rule2
  (father tom john)
=>
  (printout green "father" crlf)
)




; Licensed under GPLv2. See LICENSE file. Copyright Carologistics.

(defrule ros-msgs-pub-init
" Create publisher for ros_cx_out."
  (not (ros-msgs-publisher (topic "ros_cx_out")))
  (not (executive-finalize))
=>
  ; print welcome text
  (printout green "-------------------- ")
  (printout bold  "ros msg example")
  (printout green " -------------------" crlf)
  (printout green "| ")
  (printout blue  "Creates a subscription to /turtle1/cmd_vel and a publisher")
  (printout green " |" crlf)
  (printout green "| ")
  (printout  blue "on /ros_cx_out. Whenever a message on /turtle1/cmd_vel is ")
  (printout green " |" crlf)
  (printout green "| ")
  (printout  blue "received, a response is published on /ros_cx_out    ")
  (printout green " |" crlf)
  (printout green "| ")
  (printout  blue "with content \"Hello World!\".                        ")
  (printout green " |" crlf)
  (printout green "--------------------------------------------------------" crlf)
  ; create the publisher
  (ros-msgs-create-publisher "ros_cx_out" "std_msgs/msg/String")
  (printout info "Publishing on /ros_cx_out" crlf)
)

(defrule ros-msgs-pub-hello
" Whenever a message comes in, send out a Hello World message in response. "
  (declare (salience 1))
  (ros-msgs-publisher (topic ?topic))
  (ros-msgs-message)
  =>
  (printout yellow "Sending Hello World Message!" crlf)
  (bind ?msg (ros-msgs-create-message "std_msgs/msg/String"))
  (ros-msgs-set-field ?msg "data" "Hello world!")
  (ros-msgs-publish ?msg ?topic)
  (ros-msgs-destroy-message ?msg)
)

(defrule ros-msgs-sub-init
" Create a simple subscriber using the generated bindings. "
  (not (ros-msgs-subscription (topic "turtle1/cmd_vel")))
  (not (executive-finalize))
=>
  (ros-msgs-create-subscription "turtle1/cmd_vel" "std_msgs/msg/String")
  (printout info "Listening for String messages on /turtle1/cmd_vel" crlf)
)

(defrule ros-msgs-receive
" React to incoming messages and answer (on a different topic). "
  (ros-msgs-subscription (topic ?sub))
  ?msg-f <- (ros-msgs-message (topic ?sub) (msg-ptr ?inc-msg))
  =>
  (bind ?recv (ros-msgs-get-field ?inc-msg "data"))
  (printout blue "Recieved via " ?sub ": " ?recv crlf)
  (ros-msgs-destroy-message ?inc-msg)
  (retract ?msg-f)
)

(defrule ros-msgs-sub-finalize
" Delete the subscription on executive finalize. "
  (executive-finalize)
  (ros-msgs-subscription (topic ?topic))
=>
  (printout debug "Destroying topic " ?topic crlf)
  (ros-msgs-destroy-subscription ?topic)
)

(defrule ros-msgs-pub-finalize
" Delete the publisher on executive finalize. "
  (executive-finalize)
  (ros-msgs-publisher (topic ?topic))
=>
  (printout info "Destroying topic " ?topic crlf)
  (ros-msgs-destroy-publisher ?topic)
)

(defrule ros-msgs-message-cleanup
" Delete the subscription on executive finalize. "
  (executive-finalize)
  ?msg-f <- (ros-msgs-message (msg-ptr ?ptr))
=>
  (ros-msgs-destroy-message ?ptr)
  (retract ?msg-f)
)

