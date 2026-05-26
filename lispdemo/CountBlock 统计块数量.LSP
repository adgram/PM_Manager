;; CountBlock.LSP - 图块统计标注工具
;; 选择块参照后自动统计全图中同名块的数量并标注

(vl-load-com)

(defun c:CountBlock (/ offset userOffset sel i entData blockName names blockCount pt)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Text-Loaded* (load "lib-pm/PM_Text"))
  (or *PM-Block-Loaded* (load "lib-pm/PM_Block"))

  (princ "\n=== 图块统计标注 ===\n")

  (setq offset 0)
  (if (setq userOffset (getint "\n请输入数量偏移量 <0>: "))
    (setq offset userOffset)
  )

  (while (progn (princ "\n请选择要统计的块...") (setq sel (ssget '((0 . "INSERT")))))
    (setq names nil)
    (repeat (setq i (sslength sel))
      (setq entData (entget (ssname sel (setq i (1- i)))))
      (setq blockName (cdr (assoc 2 entData)))
      (if (not (member blockName names))
        (setq names (cons blockName names))
      )
    )
    (foreach blockName names
      (setq blockCount (+ (PM:CountBlockByName blockName) offset))
      (if (setq pt (getpoint (strcat "\n\"" blockName "\" = " (itoa blockCount) " 个，标注位置: ")))
        (PM:MakeScaledText pt (strcat blockName " × " (itoa blockCount)))
      )
    )
  )

  (princ)
)
