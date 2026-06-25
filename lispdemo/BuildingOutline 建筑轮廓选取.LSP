;; BuildingOutline.LSP - 建筑轮廓提取
;; 功能：选择建筑图层上的封闭多段线轮廓
;; 命令：BuildingOutline

(vl-load-com)

(defun c:BuildingOutline (/ *error* old-cmdecho ss ent entData layerName inclZero selAll i obj objData thickness objList resultSS)
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))

  (defun *error* (msg)
    (if old-cmdecho (setvar "cmdecho" old-cmdecho))
    (PM:ErrorHandler msg)
  )

  (setq old-cmdecho (getvar "cmdecho"))
  (setvar "cmdecho" 0)

  (princ "\n选择建筑图层上任一轮廓线（多段线）: ")
  (if (setq ss (entsel))
    (progn
      (setq ent (car ss))
      (setq entData (entget ent))
      (if (member (cdr (assoc 0 entData)) '("LWPOLYLINE" "POLYLINE"))
        (progn
          (setq layerName (cdr (assoc 8 entData)))
          (princ (strcat "\n已识别图层: " layerName))

          (initget "Y N")
          (setq inclZero (getkword "\n是否包含高度为0的轮廓 <N>: "))
          (if (null inclZero) (setq inclZero "N"))

          (princ "\n正在搜索满足条件的轮廓线...")
          (setq selAll (ssget "_X"
            (list
              '(-4 . "<OR")
              '(0 . "LWPOLYLINE")
              '(0 . "POLYLINE")
              '(-4 . "OR>")
              (cons 8 layerName)
              '(-4 . "&")
              '(70 . 1)
            )
          ))

          (if selAll
            (progn
              (setq objList '())
              (repeat (setq i (sslength selAll))
                (setq obj (ssname selAll (setq i (1- i))))
                (setq objData (entget obj))
                (setq thickness (cdr (assoc 39 objData)))
                (if (null thickness) (setq thickness 0.0))
                (if (equal thickness (float (fix (+ thickness 0.5))) 1e-4)
                  (if (or (= inclZero "Y") (not (equal thickness 0.0 1e-4)))
                    (setq objList (cons obj objList))
                  )
                )
              )

              (princ (strcat "\n找到 " (itoa (length objList)) " 个满足条件的轮廓线"))
              (if objList
                (progn
                  (sssetfirst nil nil)
                  (setq resultSS (ssadd))
                  (foreach obj objList
                    (ssadd obj resultSS)
                  )
                  (sssetfirst nil resultSS)
                )
              )
            )
            (princ "\n未找到任何轮廓线")
          )
        )
        (princ "\n所选对象不是多段线")
      )
    )
    (princ "\n未选择对象")
  )

  (setvar "cmdecho" old-cmdecho)
  (princ)
)

