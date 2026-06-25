;; BuildingArea.LSP - 建筑面积统计
;; 命令：BuildingArea

(vl-load-com)

(defun c:BuildingArea (/ *error* old-cmdecho old-unit ss i obj objData thickness byFloor objList totalArea areaObj insPt)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Entity-Loaded* (load "lib-pm/PM_Entity"))
  (or *PM-Text-Loaded* (load "lib-pm/PM_Text"))

  (defun *error* (msg)
    (if old-cmdecho (setvar "cmdecho" old-cmdecho))
    (if old-unit (setq *PM:Unit-Mode* old-unit))
    (PM:ErrorHandler msg)
  )

  (setq old-cmdecho (getvar "cmdecho"))
  (setq old-unit *PM:Unit-Mode*)
  (setq *PM:Unit-Mode* "m-m")
  (setvar "cmdecho" 0)

  (princ "\n选择建筑轮廓（多段线）: ")
  (setq ss (ssget (list '(0 . "LWPOLYLINE,POLYLINE"))))
  (if ss
    (progn
      (setq objList '())
      (repeat (setq i (sslength ss))
        (setq obj (ssname ss (setq i (1- i))))
        (setq objData (entget obj))
        (if (= 1 (logand 1 (cdr (assoc 70 objData))))
          (progn
            (setq thickness (cdr (assoc 39 objData)))
            (if (null thickness) (setq thickness 0.0))
            (if (and (equal thickness (float (fix (+ thickness 0.5))) 1e-4)
                     (not (equal thickness 0.0 1e-4)))
              (setq objList (cons (cons obj thickness) objList))
            )
          )
        )
      )

      (if objList
        (progn
          (initget "Y N")
          (setq byFloor (getkword (strcat "\n按层数统计 <Y>: ")))
          (if (null byFloor) (setq byFloor "Y"))

          (setq totalArea 0.0)
          (foreach item objList
            (setq obj (car item) thickness (cdr item))
            (setq areaObj (abs (PM:GetObjectArea obj)))
            (if (= byFloor "Y")
              (setq totalArea (+ totalArea (* areaObj thickness)))
              (setq totalArea (+ totalArea (/ (* areaObj thickness) 3.0)))
            )
          )

          (if (and totalArea (> totalArea 1e-6))
            (if (setq insPt (getpoint "\n请点击标注位置: "))
              (PM:MakeText insPt 3.5
                (strcat "S=" (rtos (PM:ConvertArea totalArea) 2 3) (PM:GetUnitSuffix "area"))
              )
            )
            (princ "\n无法计算面积")
          )
        )
        (princ "\n未找到满足条件的轮廓线（封闭、厚度为整数且不为0）")
      )
    )
    (princ "\n未选择到多段线")
  )

  (setq *PM:Unit-Mode* old-unit)
  (setvar "cmdecho" old-cmdecho)
  (princ)
)

