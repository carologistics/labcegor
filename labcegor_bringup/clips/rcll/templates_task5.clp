; Here is my stuff
(defglobal ?*global_task_id_base* = 0)

(deftemplate tasks_overview
  (slot robot_id (type INTEGER))
  (slot robot_type (type SYMBOL) (allowed-values PRODUCTION PAYMENT HELPER FASTPRODUCTION))
  (slot task_id (type INTEGER))
  (slot can_move (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_retrieve (type SYMBOL) (allowed-values FALSE TRUE))
  (slot can_deliver (type SYMBOL) (allowed-values FALSE TRUE))
  (slot state (type SYMBOL) (allowed-values IDLE MOVING CARRY HOLDING SOMETHING))
  (slot move_target (type STRING))
  (slot machine_target (type STRING))
)

(deftemplate machine_task_overview
  (slot machine_id (type SYMBOL))
  (slot machine_task (type SYMBOL))
)

(deftemplate machine_payment_info
  (slot machine_id (type SYMBOL))
  (slot money (type INTEGER))
)

(deftemplate check_robot
  (slot robot_id (type INTEGER))
  (slot did_something (type SYMBOL) (allowed-values FALSE TRUE))
  (slot is_assigned (type SYMBOL) (allowed-values FALSE TRUE))
  (slot go_to_next_step (type SYMBOL) (allowed-values FALSE TRUE))
)

(deftemplate assigned_order
  (slot order_id (type INTEGER))
  (slot robot_id (type INTEGER))
  (slot ready_for_next_step (type SYMBOL) (allowed-values FALSE TRUE))
)

(deftemplate base_order_from_machine
  (slot order_id (type INTEGER))
  (slot robot_id (type INTEGER))
  (slot color (type STRING))
  (slot position (type STRING))
)

; facts
(deffacts robottasks
  (tasks_overview (robot_id 1) (robot_type PRODUCTION) (task_id 1) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (state IDLE) (move_target "M-BS") (machine_target "input" ))
  (tasks_overview (robot_id 2) (robot_type FASTPRODUCTION) (task_id 1) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (state IDLE) (move_target "M-BS") (machine_target "output" ))
  (tasks_overview (robot_id 3) (robot_type PAYMENT) (task_id 1) (can_move TRUE) (can_retrieve FALSE) (can_deliver FALSE) (state IDLE) (move_target "M-BS") (machine_target "output" ))
  (check_robot (robot_id 1) (did_something FALSE) (is_assigned TRUE) (go_to_next_step TRUE))
  (check_robot (robot_id 2) (did_something FALSE) (is_assigned TRUE) (go_to_next_step TRUE))
  (check_robot (robot_id 3) (did_something FALSE) (is_assigned FALSE) (go_to_next_step TRUE))
  (assigned_order (order_id 1) (robot_id 1) (ready_for_next_step FALSE))
  (assigned_order (order_id 2) (robot_id 2) (ready_for_next_step FALSE))
  (assigned_order (order_id 0) (robot_id 3) (ready_for_next_step FALSE))
)

(deffacts machine_facts
  (machine_task_overview (machine_id M-CS1) (machine_task NOT-SET))
  (machine_task_overview (machine_id M-BS) (machine_task NOT-SET))
  (machine_payment_info (machine_id M-RS1) (money 0))
  (machine_payment_info (machine_id M-RS2) (money 0))
)