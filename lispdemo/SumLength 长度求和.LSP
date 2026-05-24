;; SumLength.LSP - 长度求和工具
;; 选择多条曲线对象，汇总其总长度

(vl-load-com)

(defun c:SumLength (/ *error* old-cmdecho selection i object total-length length-val ent-type)
  (or *PM-LibDir*
    (setq *PM-LibDir* (strcat (vl-filename-directory (getvar "lastloaded")) "\\library\\"))
  )
  (or *PM-Core-Loaded* (load (strcat *PM-LibDir* "PM_Core")))
  (or *PM-Entity-Loaded* (load (strcat *PM-LibDir* "PM_Entity")))

  (defun *error* (msg)
    (if old-cmdecho (setvar "cmdecho" old-cmdecho))
    (PM:ErrorHandler msg)
  )

  (setq old-cmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)

  (princ "\n选择要计算长度的对象: ")

  (cond
    ((setq selection (ssget '((0 . "SPLINE,ARC,LINE,ELLIPSE,LWPOLYLINE,POLYLINE,CIRCLE"))))
     (setq total-length 0.0
           i 0)

     (repeat (sslength selection)
       (setq object (ssname selection i)
             ent-type (cdr (assoc 0 (entget object)))
             i (1+ i))

       (cond
         ((= ent-type "CIRCLE")
          (setq length-val (* 2.0 pi (cdr (assoc 40 (entget object)))))
          (setq total-length (+ total-length length-val)))

         (t
          (if (setq length-val (PM:GetCurveLength object))
            (setq total-length (+ total-length length-val))
            (princ (strcat "\n警告: 无法计算 " ent-type " 对象的长度。"))
          ))
       ))

     (princ (strcat "\n所选对象总长度为: " (rtos total-length 2 2)))
     (alert (strcat "计算完成!\n\n所选对象总长度: " (rtos total-length 2 2) " 单位"))

     (setvar "cmdecho" old-cmdecho)
     (princ))

    (t
     (princ "\n未选择任何对象或选择无效。")
     (setvar "cmdecho" old-cmdecho)
     (princ)))

  (princ)
)