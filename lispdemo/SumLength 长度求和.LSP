;; SumLength.LSP - 长度求和工具
;; 选择多条曲线对象，汇总其总长度

(vl-load-com)

(defun c:SumLength (/ *error* old-cmdecho selection i object total-length length-val ent-type ins-pt)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Entity-Loaded* (load "lib-pm/PM_Entity"))
  (or *PM-Text-Loaded* (load "lib-pm/PM_Text"))

  (defun *error* (msg)
    (if old-cmdecho (setvar "cmdecho" old-cmdecho))
    (PM:ErrorHandler msg)
  )

  (setq old-cmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)

  (princ "\n选择要计算长度的对象（支持曲线和文字）: ")

  (cond
    ((setq selection (ssget '((0 . "SPLINE,ARC,LINE,ELLIPSE,LWPOLYLINE,POLYLINE,CIRCLE,TEXT,MTEXT"))))
     (setq total-length 0.0
           i 0)

     (repeat (sslength selection)
       (setq object (ssname selection i)
             ent-type (cdr (assoc 0 (entget object)))
             i (1+ i))

       (cond
         ((member ent-type '("TEXT" "MTEXT"))
          (setq length-val (PM:ValueFromText (cdr (assoc 1 (entget object))) "length"))
          (if length-val
            (setq total-length (+ total-length length-val))
            (princ (strcat "\n警告: 无法解析文字中的数值。"))
          ))

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

     (if (setq ins-pt (getpoint "\n请点击标注位置: "))
       (PM:MakeScaledText ins-pt (strcat "长度:" (rtos (PM:ConvertLength total-length) 2 2) (PM:GetUnitSuffix "length")))
     )

     (setvar "cmdecho" old-cmdecho)
     (princ))

    (t
     (princ "\n未选择任何对象或选择无效。")
     (setvar "cmdecho" old-cmdecho)
     (princ)))
  (princ)
)
