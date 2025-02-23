(defglobal ?*counter* = 0)

(deffunction next-number* ()
  (bind ?*counter* (+ ?*counter* 1))  ; Increment the counter by 1 
  (return ?*counter*)
)

(deftemplate order
  (slot id (type INTEGER))
  (slot refbox-order)
  (slot finished (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
)

(deftemplate move_base
  (slot task_id (type INTEGER) (default-dynamic (next-number*)))
  ; (slot robot-id (type INTEGER)
  ;   (allowed-values 1 2 3))
  (slot from (type SYMBOL))
  (slot from_side (type SYMBOL) (default SHELF)
    (allowed-values OUTPUT SHELF))
  (slot target (type SYMBOL))
  (slot target_side (type SYMBOL) (default INPUT)
    (allowed-values INPUT SLIDE))
  (multislot depend_on)
  (slot state (type SYMBOL)
    (allowed-values PRE MOVING_FROM MOVED_FROM GRIPPING GRIPPED MOVING_TARGET MOVED_TARGET PUTTING FINISHED)
  )
  (slot finished (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
)

(deftemplate instruct
  (slot action (type SYMBOL)
      (allowed-values DELIVER RETRIEVE DISPENSE-BASE BUFFER-CAP MOUNT-RING MOUNT-CAP DELIVER))
  (slot machine (type SYMBOL)
    (allowed-values M-BS M-CS1 M-CS2 M-RS1 M-RS2 M-SS M-DS C-BS C-CS1 C-CS2 C-RS1 C-RS2 C-SS C-DS))
  (slot side (type SYMBOL)
    (allowed-values INPUT OUTPUT)) ; FOR BS
  (slot base_color (type SYMBOL)
    (allowed-values BASE_BLACK BASE_SILVER BASE_RED)) ; FOR BS
  (slot order-id (type INTEGER)) ; FOR DS
  (multislot depend_on)
  (slot finished (type SYMBOL) (default FALSE)
    (allowed-values FALSE TRUE))
  (slot state (type SYMBOL) (default PRE)
    (allowed-values PRE STARTED FINISHED))
)