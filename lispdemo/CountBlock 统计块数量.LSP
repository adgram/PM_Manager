;; CountBlock.LSP - 图块统计标注工具
;; 选择块参照后自动统计全图中同名块的数量并标注

(vl-load-com)

(defun c:CountBlock (/ textSize offset userOffset sel entData blockName blockCount ptName ptCount)
  (or *PM-LibDir*
    (setq *PM-LibDir* (strcat (vl-filename-directory (getvar "lastloaded")) "\\library\\"))
  )
  (or *PM-Text-Loaded* (load (strcat *PM-LibDir* "PM_Text")))
  (or *PM-Block-Loaded* (load (strcat *PM-LibDir* "PM_Block")))

  (princ "\n=== 图块统计标注 ===\n")

  (setq textSize (PM:GetTextSize))

  (setq offset 0)
  (if (setq userOffset (getint "请输入数量偏移量 <0>: "))
    (setq offset userOffset)
  )

  (while (and (princ "\n请选择要统计的块...") (setq sel (ssget)))
    (setq entData (entget (ssname sel 0)))
    (setq blockName (cdr (assoc 2 entData)))
    (setq blockCount (+ (PM:CountBlockByName blockName) offset))
    (if (setq ptName (getpoint (strcat "\n块名 \"" blockName "\" 的标注位置: ")))
      (PM:MakeText ptName textSize blockName)
    )
    (if (setq ptCount (getpoint (strcat "\n数量 " (itoa blockCount) " 的标注位置: ")))
      (PM:MakeText ptCount textSize (itoa blockCount))
    )
  )
  (princ)
)
