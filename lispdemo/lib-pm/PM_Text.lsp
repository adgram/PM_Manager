;; PM_Text.lsp - 文字操作函数
;; 职责：所有与文字/标注相关的函数
;; 依赖：PM_Core.lsp

;; 图纸比例尺（默认 1:100）
;; 例：100 表示 1:100，50 表示 1:50，0.1 表示 1:0.1
(setq *PM:Scale* 100)

;; 设置图纸比例尺（值 = 比例分母，如 100 表示 1:100）
(defun PM:SetScale (val)
  (setq *PM:Scale* val)
  (princ (strcat "\n[PM] 比例尺已设为 1:" (rtos val 2 2)))
  (princ)
)

;; 命令：PMScale - 设置图纸比例尺
(defun C:PMScale (/ val)
  (princ (strcat "\n当前比例尺 1:" (rtos *PM:Scale* 2 2)))
  (if (setq val (getreal "\n请输入新比例尺（如 100 表示 1:100）: "))
    (PM:SetScale val)
    (princ "\n[PM] 取消，比例尺未更改。")
  )
  (princ)
)

;; 获取按比例尺缩放后的文字高度（图纸空间高度 3.5）
(defun PM:GetScaledTextHeight ()
  (* 3.5 *PM:Scale*)
)

;; 按比例尺在指定位置创建文字（图纸高度默认为 3.5）
(defun PM:MakeScaledText (pos content)
  (PM:MakeText pos (* 3.5 *PM:Scale*) content)
)

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
