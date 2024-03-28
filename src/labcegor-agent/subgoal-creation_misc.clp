; made by Yuan,Chengzhi, last modified @20240310

(deftemplate mps-occupied
  (slot mps (type SYMBOL))
)

(deftemplate cs-prepared
  (slot cs (type SYMBOL))
  (slot order-id (type INTEGER))
)

(deftemplate order-is-expanding
  (slot order-id (type INTEGER))
)

; fact to ensure only fire each lifecycle rule once, to avoid deadlock caused by the multiplt calls.
(deftemplate already_fire_lifecycle
  (slot order-id (type INTEGER))
  (slot index (type INTEGER))
)
