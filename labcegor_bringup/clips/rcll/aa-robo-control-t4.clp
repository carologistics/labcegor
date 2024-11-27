(defrule peer-send-msg
  (peer ?peer-id)
  (not (protobuf-msg))
  =>
  (bind ?msg (pb-create "SearchRequest"))
  (pb-set-field ?msg "query" "hello")
  (pb-set-field ?msg "page_number" ?peer-id)
  (pb-set-field ?msg "results_per_page" ?peer-id)
  (pb-broadcast ?peer-id ?msg)
  (pb-destroy ?msg)
)

(defrule protobuf-init-example-peer
  (not (peer ?any-peer-id))
  =>
  (bind ?peer-1 (pb-peer-create-local 127.0.0.1 4444 4445))
  (bind ?peer-2 (pb-peer-create-local 127.0.0.1 4445 4444))
  (assert (peer ?peer-1))
  (assert (peer ?peer-2))
)