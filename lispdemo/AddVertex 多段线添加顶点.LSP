;; AddVertex.LSP - 多段线添加顶点
;; 在用户指定位置向轻量多段线插入新顶点（兼容弧段和变宽）
;; Author: Lee Mac, Copyright (c) 2012 - www.lee-mac.com

(vl-load-com)

(defun c:AddVertex (/ a b e h l n p r w x z)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Entity-Loaded* (load "lib-pm/PM_Entity"))

  (while
    (progn (setq p (getpoint "\n请选择要添加顶点的位置: "))
      (cond
        ((null p) nil)
        ((null (setq e (nentselp p)))
         (princ "\n点不在多段线上"))
        ((= 4 (length e))
         (princ "\n对象为嵌套图块"))
        ((/= "LWPOLYLINE" (cdr (assoc 0 (entget (setq e (car e))))))
         (princ "\n对象不是轻量多段线"))
      )
    )
  )
  (if (and p e
          (setq p (vlax-curve-getclosestpointto e (trans p 1 0))
                n (vlax-curve-getparamatpoint e p)
          )
      )
      (if (not (equal n (fix n) 1e-8))
        (progn
          (setq e (entget e)
                h (reverse (member (assoc 39 e) (reverse e)))
                l (PM:GetLWVertices e)
                z (assoc 210 e)
          )
          (repeat (fix n)
            (setq a (cons (car l) a)
                  l (cdr l)
            )
          )
          (setq x (car l)
                r (- n (fix n))
                w (cdr (assoc 40 x))
                w (+ w (* r (- (cdr (assoc 41 x)) w)))
                b (atan (cdr (assoc 42 x)))
          )
          (entmod
            (append h
              (apply 'append (reverse a))
              (list
                (assoc 10 x)
                (assoc 40 x)
                (cons 41 w)
                (cons 42 (PM:Tan (* r b)))
              )
              (list
                (cons 10 (trans p 0 (cdr z)))
                (cons 40 w)
                (assoc 41 x)
                (cons 42 (PM:Tan (* (- 1.0 r) b)))
              )
              (apply 'append (cdr l))
              (list z)
            )
          )
        )
        (princ "\n顶点已存在该位置")
      )
    )
  (princ)
)