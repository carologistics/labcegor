
; Copyright (c) 2024 Carologistics
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

; A start-task routine to initialize pddl using the pddl_manager
; Parts:
;  - init-clients: start all service clients
;  - init-problem: setup an initial pddl domain
;  - init-planning-actions: retrieve the list of actions to prepare the main planning filter
;  - init-fluents: retrieve fluents and numeric fluents from pddl domain and store them
;  - init-plan-server: create a client for the planner server
;

(deftemplate start-task
  " Establish start routines with defined order of execution.
    @slot name: unique name of the task. Set manually. No modification needed.
    @slot wait-for: list of other start-task names that need to complete before
          the current one is started. Set manually, modified automatically.
    @slot parts: list of things this task consists of. This list describes the
          things the task will do once it is active.
          Hence, user-code is needed to subsequently delete each member of the
          list in order to achieve the task.
          Set and modified manually.
    @slot state: Set and modified automatically.
     - WAITING: Initial state of each task, is switched to ACTIVE once all
       dependent tasks (defined by wait-for) are DONE.
     - ACTIVE: task is started, user-code needs to fulfill the parts (and
       subsequently delete each part from the list of parts).
     - DONE: Once an ACTIVE task has no more parts, it is automatically
       switched to DONE.
  "
  (slot name (type SYMBOL))
  (multislot wait-for (type SYMBOL) (default (create$)))
  (multislot parts (type SYMBOL) (default (create$)))
  (slot state (type SYMBOL) (allowed-values WAITING ACTIVE DONE) (default WAITING))
)

(deffacts pddl-task
  (start-task (name pddl)
    (wait-for)
    (parts init-cfg init-clients init-problem init-fluents init-planner)
  )
)

(defrule start-task-active
  " A start-task is active if there is nothing to wait for anymore."
  ?st <- (start-task (state WAITING) (wait-for))
  =>
  (modify ?st (state ACTIVE))
)

(defrule start-task-wait-for-reduce
  " A start-task can cross-of a task it waits for, once said task is done. "
  (start-task (name ?done-task) (state DONE))
  ?st <- (start-task (state WAITING) (wait-for $?wait-for&:(member$ ?done-task ?wait-for)))
  =>
  (modify ?st (wait-for (delete-member$ ?wait-for ?done-task)))
)

(defrule start-task-done
  " A start-task is done once it has no parts to work on."
  ?st <- (start-task (state ACTIVE) (parts))
  =>
  (modify ?st (state DONE))
)
(defrule start-task-startup-completed
  " All start-tasks are done, mark startup as completed."
  (not (start-task (state ~DONE)))
  =>
  (assert (startup-completed))
)

(defrule init-from-config
  ?st <- (start-task (name pddl) (state ACTIVE) (parts init-cfg $?rest-parts))
  (confval (path "/pddl/manager_node") (value ?node))
  =>
  (assert (pddl-manager (node ?node)))
  (modify ?st (parts ?rest-parts))
)

(defrule pddl-init-pddl-manager-services
" Create publisher for ros_cx_out."
  (pddl-manager (node ?node))
  ?st <- (start-task
    (name pddl) (state ACTIVE)
    (parts init-clients $?rest-parts)
  )
  (not (executive-finalize))
=>
  ; create all clients
  (bind ?services (create$
    add_fluents AddFluents
    rm_fluents RemoveFluents
    add_objects AddObjects
    rm_objects RemoveFluents
    set_function SetFunctions
    add_pddl_instance AddPddlInstance
    check_action_precondition CheckActionPrecondition
    get_action_effects GetActionEffects
    get_action_names GetActionNames
    get_fluents GetFluents
    get_functions GetFunctions
    set_goals SetGoals
    clear_goals ClearGoals
  ))
  (bind ?index 1)
  (bind ?length (length$ ?services))
  (while (< ?index ?length)
     (bind ?service-name (nth$ ?index ?services))
     (bind ?service-type (nth$ (+ ?index 1) ?services))
     (ros-msgs-create-client
       (str-cat ?node "/" ?service-name)
       (str-cat "expertino_msgs/srv/" ?service-type)
     )
     (bind ?index (+ ?index 2))
  )
  (modify ?st (parts $?rest-parts))
)

(defrule pddl-request-load-problem-instance
  (pddl-manager (node ?node))
  (confval (path "/pddl/problem_instance") (value ?instance))
  (confval (path "/pddl/pddl_dir") (value ?dir))
  (confval (path "/pddl/init_domain_file") (value ?domain))
  (confval (path "/pddl/init_problem_file") (value ?problem))
  (start-task (name pddl) (state ACTIVE) (parts init-problem $?rest-parts))
  =>
  (assert (pddl-instance (name (sym-cat ?instance)) (domain ?domain) (problem ?problem) (directory ?dir) (state PENDING)))
)

(defrule pddl-init-problem-loading-successful
  (pddl-instance (state LOADED) (name ?instance))
  (confval (path "/pddl/problem_instance") (value ?instance-str&:(eq ?instance (sym-cat ?instance-str))))
  ?st <- (start-task (name pddl) (state ACTIVE) (parts init-problem $?rest-parts))
  =>
  (modify ?st (parts $?rest-parts))
)

(defrule pddl-init-load-facts
  (start-task (name pddl) (state ACTIVE) (parts init-fluents $?rest-parts))
  (confval (path "/pddl/problem_instance") (value ?instance-str))
  =>
  (assert (pddl-get-fluents (instance (sym-cat ?instance-str))))
  (assert (pddl-get-numeric-fluents (instance (sym-cat ?instance-str))))
)

(defrule pddl-init-load-facts-done
  (pddl-get-fluents (instance ?instance) (state DONE))
  (pddl-get-numeric-fluents (instance ?instance) (state DONE))
  (confval (path "/pddl/problem_instance") (value ?instance-str&:(eq ?instance (sym-cat ?instance-str))))
  ?st <- (start-task (name pddl) (state ACTIVE) (parts init-fluents $?rest-parts))
=>
  (modify ?st (parts $?rest-parts))
)

(defrule pddl-init-plan-client
  (confval (path "/pddl/manager_node") (value ?node))
  (start-task (name pddl) (state ACTIVE) (parts init-planner $?rest-parts))
  =>
  (expertino-msgs-plan-temporal-create-client (str-cat ?node "/temp_plan"))
)

(defrule pddl-init-plan-client-successful
  (confval (path "/pddl/manager_node") (value ?node))
  (expertino-msgs-plan-temporal-client (server ?s&:(eq ?s (str-cat ?node "/temp_plan"))))
  ?st <- (start-task (name pddl) (state ACTIVE) (parts init-planner $?rest-parts))
  =>
  (modify ?st (parts ?rest-parts))
)


