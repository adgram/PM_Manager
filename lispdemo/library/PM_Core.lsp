;; PM_Core.lsp - 核心基础函数
;; 职责：通用基础设施，不依赖其他模块

(setq *PM-Core-Loaded* T)

;; 通用错误处理
(defun PM:ErrorHandler (msg / ignoreList)
  (setq ignoreList '("*break*" "*cancel*" "*exit*"))
  (if (not (apply 'or (mapcar (function (lambda (x) (wcmatch (strcase msg t) x))) ignoreList)))
    (princ (strcat "\n错误: " msg))
  )
  (princ)
)

;; 安全获取系统变量（自动恢复）
(defun PM:GetSysVar (name / val)
  (setq val (getvar name))
  (if (null val)
    (prompt (strcat "\n警告: 系统变量 \"" name "\" 不存在"))
  )
  val
)

;; 打印分隔线
(defun PM:PrintLine (char count)
  (princ "\n")
  (repeat count (princ char))
  (princ "\n")
)

;; 正切函数 - Lee Mac
(defun PM:Tan (x)
  (if (not (equal 0.0 (cos x) 1e-10))
    (/ (sin x) (cos x))
  )
)

;; 数值舍入到指定容差的整数倍
(defun PM:Round (x tol / frac half)
  (setq half (/ tol 2.0))
  (setq frac (rem x tol))
  (if (< (abs frac) half)
    (- x frac)
    (if (< x 0)
      (- x frac tol)
      (- x frac (- tol))
    )
  )
)

;; 替换关联表中的键值对
(defun PM:Replace (key new lst)
  (subst (cons key new) (assoc key lst) lst)
)

;; 列表转安全数组
(defun PM:ListToArray (lst)
  (vlax-make-variant
    (vlax-safearray-fill
      (vlax-make-safearray vlax-vbdouble (cons 0 (1- (length lst))))
      lst
    )
  )
)

;; 安全数组转列表
(defun PM:ArrayToList (array)
  (vlax-safearray->list (vlax-variant-value array))
)

;; 矩阵乘向量 - Vladimir Nesterovsky
(defun PM:mxv (m v)
  (mapcar '(lambda (r) (apply '+ (mapcar '* r v))) m)
)

;; 矩阵乘矩阵 - Vladimir Nesterovsky
(defun PM:mxm (m n)
  ((lambda (a) (mapcar '(lambda (r) (PM:mxv a r)) m)) (PM:trp n))
)

;; 矩阵转置 - Doug Wilson
(defun PM:trp (m)
  (apply 'mapcar (cons 'list m))
)

;; 开始撤销标记 - Lee Mac
(defun PM:StartUndo (doc)
  (PM:EndUndo doc)
  (vla-startundomark doc)
)

;; 结束撤销标记 - Lee Mac
(defun PM:EndUndo (doc)
  (while (= 8 (logand 8 (getvar 'undoctl)))
    (vla-endundomark doc)
  )
)

;; 获取活动文档 - Lee Mac
(defun PM:AcDoc nil
  (eval (list 'defun 'PM:AcDoc 'nil (vla-get-activedocument (vlax-get-acad-object))))
  (PM:AcDoc)
)
