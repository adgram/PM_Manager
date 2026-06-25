;; FloorToHeight.LSP - 建筑层数转高度
;; 命令：FloorToHeight

(vl-load-com)

(defun c:FloorToHeight (/ *error* old-cmdecho ss i obj objData thickness count)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Entity-Loaded* (load "lib-pm/PM_Entity"))

  (defun *error* (msg)
    (if old-cmdecho (setvar "cmdecho" old-cmdecho))
    (PM:ErrorHandler msg)
  )

  (setq old-cmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)

  (princ "\n选择建筑轮廓(多段线): ")
  (setq ss (ssget
    '((-4 . "<OR")
      (0 . "LWPOLYLINE")
      (0 . "POLYLINE")
      (-4 . "OR>")
    )
  ))
  (if ss
    (progn
      (setq count 0)
      (repeat (setq i (sslength ss))
        (setq obj (ssname ss (setq i (1- i))))
        (setq objData (entget obj))
        (if (= 1 (logand 1 (cdr (assoc 70 objData))))
          (progn
            (setq thickness (cdr (assoc 39 objData)))
            (if (null thickness) (setq thickness 0.0))
            (if (and (equal thickness (float (fix (+ thickness 0.5))) 1e-4)
                     (not (equal thickness 0.0 1e-4)))
              (progn
                (PM:PutDXF 39 (* thickness 3) obj)
                (setq count (1+ count))
              )
            )
          )
        )
      )
      (princ (strcat "\n已处理 " (itoa count) " 个轮廓线,厚度乘以3"))
    )
    (princ "\n未选择到多段线")
  )

  (setvar "cmdecho" old-cmdecho)
  (princ)
)

