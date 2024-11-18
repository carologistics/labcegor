"Todos if publisher not yet exisist => create"
"Todos if topic /cmd_val exist => set publisher to /cmd_val"
"Todos if speed == 0 => get next point()"
"Todos if if speed == 0 and currentPos*margin != target_point => move to point"

(deftemplate rider
    (slot target_point (default ?None))
    (slot current_pos (type float32[2] static array)(default ?None))
    (slot margin (type float32) (default ?None))
    (slot speed (type float32) (default ?None)))
