
(defrule print-action-start
	?pa <- (plan-action (plan-id ?plan-id) (id ?id) (state PENDING)
                      (action-name move) (executable TRUE)
                      (param-names $?param-names)
                      (param-values $?param-values))
	=>
	(bind ?severity (plan-action-arg severity ?param-names ?param-values info))
	(bind ?text     (plan-action-arg text ?param-names ?param-values ""))
        ; (printout t "----------------" crlf)
	(printout ?severity ?text crlf)
	; (modify ?pa (state FINAL))
)
