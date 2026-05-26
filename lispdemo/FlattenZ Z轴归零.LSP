;; FlattenZ.LSP - Z 坐标归零及拍平工具
;; 将选中实体的 Z 坐标归零、厚度归零、拉伸方向归正

(vl-load-com)

(defun c:FlattenZ (/ *error* old-cmdecho sel i)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Entity-Loaded* (load "lib-pm/PM_Entity"))

  (defun *error* (msg)
    (if old-cmdecho (setvar "cmdecho" old-cmdecho))
    (PM:ErrorHandler msg)
  )

  (setq old-cmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)

  (princ "\n请选择要归零的实体: ")
  (if (setq sel (ssget))
    (progn
      (repeat (setq i (sslength sel))
        (PM:FlattenEntity (ssname sel (setq i (1- i))))
      )
      (princ (strcat "\n已完成 " (itoa (sslength sel)) " 个实体的 Z 坐标归零"))
    )
    (princ "\n未选择任何实体")
  )

  (setvar "cmdecho" old-cmdecho)
  (princ)
)