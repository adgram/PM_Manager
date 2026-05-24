;; FlattenZ.LSP - Z 坐标归零及拍平工具
;; 将选中实体的 Z 坐标归零、厚度归零、拉伸方向归正

(vl-load-com)

(defun c:FlattenZ (/ *error* old-cmdecho sel i count)
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

  (princ "\n请选择要归零的实体: ")
  (if (setq sel (ssget))
    (progn
      (setq count 0)
      (repeat (sslength sel)
        (PM:FlattenEntity (ssname sel count))
        (setq count (1+ count))
      )
      (princ (strcat "\n已完成 " (itoa count) " 个实体的 Z 坐标归零"))
    )
    (princ "\n未选择任何实体")
  )

  (setvar "cmdecho" old-cmdecho)
  (princ)
)