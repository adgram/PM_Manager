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

;; 带错误保护的选择集创建
;; msg: 提示字符串或 nil, filter: DXF 过滤表或 nil
;; 返回: 选择集或 nil（失败/取消）
(defun PM:SSGet (msg filter / sel)
  (if (vl-catch-all-error-p
        (setq sel
          (cond
            ((and msg filter) (vl-catch-all-apply 'ssget (list msg filter)))
            (msg             (vl-catch-all-apply 'ssget (list msg)))
            (filter          (vl-catch-all-apply 'ssget (list filter)))
            (t               (vl-catch-all-apply 'ssget nil))
          )
        )
     )
    (progn (princ "\nPM:SSGet 错误: 选择失败") nil)
    sel
  )
)

;; 单位换算系统
;; 模式格式: "图纸单位-标注单位"，如 "mm-m" 表示图纸 mm、标注 m
(if (not (member *PM:Unit-Mode* '("mm-mm" "m-m" "mm-m" "m-mm")))
  (setq *PM:Unit-Mode* "mm-m")
)

(defun PM:SetUnitMode (mode / valid)
  (setq valid '("mm-mm" "m-m" "mm-m" "m-mm"))
  (if (member mode valid)
    (progn
      (setq *PM:Unit-Mode* mode)
      (princ (strcat "\n[PM] 单位模式已设为 " mode))
    )
    (princ (strcat "\n[PM] 无效模式，可选: mm-mm, m-m, mm-m, m-mm"))
  )
  (princ)
)

(defun C:PMUnit (/ mode)
  (princ (strcat "\n当前单位模式: " *PM:Unit-Mode*))
  (princ "\n   mm-mm  图纸:毫米 → 标注:毫米")
  (princ "\n   m-m    图纸:米   → 标注:米")
  (princ "\n   mm-m   图纸:毫米 → 标注:米")
  (princ "\n   m-mm   图纸:米   → 标注:毫米")
  (if (setq mode (getstring "\n请输入新模式: "))
    (PM:SetUnitMode mode)
  )
  (princ)
)

(defun PM:ConvertLength (val)
  (* val
    (cond
      ((= *PM:Unit-Mode* "mm-mm") 1)
      ((= *PM:Unit-Mode* "m-m")   1)
      ((= *PM:Unit-Mode* "mm-m")  0.001)
      ((= *PM:Unit-Mode* "m-mm")  1000)
      (t 1)
    )
  )
)

(defun PM:ConvertLengthRev (val)
  (* val
    (cond
      ((= *PM:Unit-Mode* "mm-mm") 1)
      ((= *PM:Unit-Mode* "m-m")   1)
      ((= *PM:Unit-Mode* "mm-m")  1000)
      ((= *PM:Unit-Mode* "m-mm")  0.001)
      (t 1)
    )
  )
)

(defun PM:ConvertArea (val)
  (* val
    (cond
      ((= *PM:Unit-Mode* "mm-mm") 1)
      ((= *PM:Unit-Mode* "m-m")   1)
      ((= *PM:Unit-Mode* "mm-m")  1e-6)
      ((= *PM:Unit-Mode* "m-mm")  1e6)
      (t 1)
    )
  )
)

(defun PM:ConvertAreaRev (val)
  (* val
    (cond
      ((= *PM:Unit-Mode* "mm-mm") 1)
      ((= *PM:Unit-Mode* "m-m")   1)
      ((= *PM:Unit-Mode* "mm-m")  1e6)
      ((= *PM:Unit-Mode* "m-mm")  1e-6)
      (t 1)
    )
  )
)

(defun PM:GetUnitSuffix (type / ann-unit)
  (setq ann-unit
    (cond
      ((member *PM:Unit-Mode* '("mm-mm" "m-mm")) "mm")
      ((member *PM:Unit-Mode* '("m-m" "mm-m"))   "m")
      (t "mm")
    )
  )
  (if (= type "area")
    (strcat ann-unit "²")
    ann-unit
  )
)

;; 从字符串中提取第一个数值
(defun PM:ParseNumber (str / i len c num-str started dot)
  (setq i 0 len (strlen str) num-str "" started nil dot nil)
  (while (< i len)
    (setq c (substr str (setq i (1+ i)) 1))
    (cond
      ((wcmatch c "#")
       (setq num-str (strcat num-str c) started T))
      ((and (= c ".") started (not dot))
       (setq num-str (strcat num-str c) dot T))
      (started
       (setq i len))
    )
  )
  (if started (distof num-str) nil)
)

;; 从文字内容提取数值并换算为图纸单位
;; type: "length" 或 "area"
(defun PM:ValueFromText (str type / val detected dwg-unit factor s)
  (setq val (PM:ParseNumber str))
  (if (null val) (setq val nil))
  (if val
    (progn
      (setq s (strcase str))
      (setq detected
        (if (wcmatch s "*MM*") "mm"
          (if (wcmatch s "*M*") "m" nil)
        )
      )
      (setq dwg-unit
        (if (wcmatch *PM:Unit-Mode* "mm-*") "mm" "m")
      )
      (if detected
        (* val
          (cond
            ((= type "length")
             (cond
               ((and (= detected "mm") (= dwg-unit "mm")) 1)
               ((and (= detected "m")  (= dwg-unit "mm")) 1000)
               ((and (= detected "mm") (= dwg-unit "m"))  0.001)
               ((and (= detected "m")  (= dwg-unit "m"))  1)
             ))
            ((= type "area")
             (cond
               ((and (= detected "mm") (= dwg-unit "mm")) 1)
               ((and (= detected "m")  (= dwg-unit "mm")) 1e6)
               ((and (= detected "mm") (= dwg-unit "m"))  1e-6)
               ((and (= detected "m")  (= dwg-unit "m"))  1)
             ))
          )
        )
        val
      )
    )
  )
)
