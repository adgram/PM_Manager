;; PM_Text.lsp - 文字操作函数
;; 职责：所有与文字/标注相关的函数
;; 依赖：PM_Core.lsp

;; 获取文字高度（带默认值提示）
(defun PM:GetTextSize (/ size)
  (setq size (getvar "textsize"))
  (if (not (setq size (getreal (strcat "请输入文字高度 <" (rtos size 2 4) ">: "))))
    (setq size (getvar "textsize"))
  )
  size
)

;; 在指定位置创建单行文字
(defun PM:MakeText (pos height content)
  (entmake (list (cons 0 "TEXT")
                 (cons 10 pos)
                 (cons 40 height)
                 (cons 1 content)
                 (cons 72 0)
                 (cons 73 0)))
)
