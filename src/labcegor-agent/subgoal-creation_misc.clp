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

