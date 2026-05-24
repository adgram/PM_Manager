;; AreaLabel.lsp - 面积标注工具
;; 在封闭区域内点选后自动标注面积

(vl-load-com)

(defun c:AreaLabel (/ ptBoundary boundaryObj areaVal areaStr autoHt textHt textPt)
  (or *PM-LibDir*
    (setq *PM-LibDir* (strcat (vl-filename-directory (getvar "lastloaded")) "\\library\\"))
  )
  (or *PM-Text-Loaded* (load (strcat *PM-LibDir* "PM_Text")))

  (princ "\n=== 面积标注 ===\n")

  (if (setq ptBoundary (getpoint "\n请拾取要标注的封闭区域内部一点: "))
    (progn
      (command "_boundary" ptBoundary "")
      (if (setq boundaryObj (entlast))
        (progn
          (command "area" "o" boundaryObj)
          (setq areaVal (getvar "area"))
          (setq areaStr (strcat "S=" (rtos areaVal 2 3) "m2"))

          (setq autoHt (/ (sqrt (abs areaVal)) 15))
          (if (not (setq textHt (getdist (strcat "\n请输入文字高度 <" (rtos autoHt 2 1) ">: "))))
            (setq textHt autoHt)
          )

          (if (setq textPt (getpoint "\n请指定标注位置: "))
            (PM:MakeText textPt textHt areaStr)
          )

          (command "erase" boundaryObj "")
        )
      )
    )
  )
  (princ)
)
