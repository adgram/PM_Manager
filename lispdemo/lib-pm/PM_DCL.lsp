;; PM_DCL.lsp - 动态 DCL 对话框生成
;; 职责：运行时创建 DCL 临时文件、加载并显示对话框
;; 依赖：PM_Core.lsp
;; 使用示例：
;;   (PM:DCLDialog
;;     '("sample : dialog { label = \"示例\";"
;;       "  : edit_box { key = \"NAME\"; label = \"名称\"; }"
;;       "  : button { key = \"OK\"; label = \"确定\"; is_default = true; }"
;;       "}"
;;      )
;;     '(lambda nil
;;        (action_tile "OK" "(done_dialog 1)")
;;       )
;;   )

(setq *PM-DCL-Loaded* T)

;; 从 DCL 定义中提取对话框名称
(defun PM:DCL-Name (dcl-lines / line pos)
  (setq line (vl-string-trim " " (car dcl-lines)))
  (setq pos (vl-string-search ":" line))
  (if pos
    (vl-string-trim " " (substr line 1 pos))
  )
)

;; 将 DCL 定义写入临时文件
(defun PM:DCLWrite (dcl-file dcl-lines / fp)
  (if (setq fp (open dcl-file "w"))
    (progn
      (foreach line dcl-lines (write-line line fp))
      (close fp)
      T
    )
  )
)

;; 创建并显示动态 DCL 对话框
;; dcl-lines: DCL 定义字符串列表
;; callback: 初始化回调函数（无参数），在其中设置 action_tile 等
;; 返回: start_dialog 结果（done_dialog 传入值）或 nil
(defun PM:DCLDialog (dcl-lines callback / dcl-file dcl-id dlg-name result)
  (setq dcl-file (vl-filename-mktemp "pm_" ".dcl"))
  (if (and (PM:DCLWrite dcl-file dcl-lines)
           (setq dcl-id (load_dialog dcl-file))
           (setq dlg-name (PM:DCL-Name dcl-lines))
           (new_dialog dlg-name dcl-id)
      )
    (progn
      (if callback (callback))
      (setq result (start_dialog))
      (unload_dialog dcl-id)
      (vl-file-delete dcl-file)
      result
    )
    (progn
      (if dcl-id (unload_dialog dcl-id))
      (vl-file-delete dcl-file)
      (princ "\nPM:DCLDialog 错误: 创建对话框失败")
      nil
    )
  )
)
