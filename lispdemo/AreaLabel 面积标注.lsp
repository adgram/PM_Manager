;; AreaLabel.lsp - 面积标注工具
;; 在封闭区域内点选后自动标注面积

(vl-load-com)

(defun c:AreaLabel (/ ptBoundary boundaryObj areaVal textPt)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Entity-Loaded* (load "lib-pm/PM_Entity"))
  (or *PM-Text-Loaded* (load "lib-pm/PM_Text"))

  (princ "\n=== 面积标注 ===\n")

  (if (setq ptBoundary (getpoint "\n请拾取要标注的封闭区域内部一点: "))
    (progn
      (command "_boundary" ptBoundary "")
      (if (setq boundaryObj (entlast))
        (progn
          (setq areaVal (abs (PM:GetObjectArea boundaryObj)))
          (command "erase" boundaryObj "")
          (if (and areaVal (> areaVal 1e-6))
            (if (setq textPt (getpoint "\n请指定标注位置: "))
              (PM:MakeScaledText textPt (strcat "S=" (rtos (PM:ConvertArea areaVal) 2 3) (PM:GetUnitSuffix "area")))
            )
            (princ "\n无法计算面积")
          )
        )
      )
    )
  )

  (princ)
)
