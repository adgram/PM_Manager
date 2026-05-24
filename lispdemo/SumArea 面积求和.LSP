;; SumArea.LSP - 面积求和工具
;; 选择多个对象，按类型汇总面积并显示总计

(vl-load-com)

(defun c:SumArea (/ *error* old-cmdecho selection i object total-area area-obj entity-data entity-type obj-list radius area)
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

  (princ "\n选择要计算面积的对象（支持多段线、圆、椭圆、样条曲线、面域、填充图案）: ")

  (cond
    ((setq selection
           (ssget
             '((-4 . "<OR")
               (0 . "LWPOLYLINE")
               (0 . "POLYLINE")
               (0 . "CIRCLE")
               (0 . "ELLIPSE")
               (0 . "SPLINE")
               (0 . "REGION")
               (0 . "HATCH")
             (-4 . "OR>")
             ))
     )
     (setq total-area 0.0
           obj-list '()
           i 0)

     (repeat (sslength selection)
       (setq object (ssname selection i)
             entity-data (entget object)
             entity-type (cdr (assoc 0 entity-data))
             i (1+ i))

       (cond
         ((= entity-type "CIRCLE")
          (setq radius (cdr (assoc 40 entity-data)))
          (setq area-obj (PM:CircleArea radius)))

         ((= entity-type "HATCH")
          (setq area-obj (PM:GetHatchArea object)))

         (t
          (setq area-obj (PM:GetObjectArea object)))
       )

       (if (and area-obj (> (abs area-obj) 1e-6))
         (progn
           (setq area-obj (abs area-obj))
           (setq total-area (+ total-area area-obj))
           (setq obj-list (cons (cons entity-type area-obj) obj-list))
         )
         (princ (strcat "\n注意: " entity-type " 类型对象的面积为零或无法计算"))
       )
     )

     (princ "\n")
     (PM:PrintLine "=" 50)
     (princ "面积计算结果:")
     (PM:PrintLine "-" 50)

     (if obj-list
       (progn
         (princ "\n按对象类型汇总:\n")
         (setq type-summary '())
         (foreach item obj-list
           (setq type (car item)
                 area-val (cdr item))
           (if (setq existing (assoc type type-summary))
             (setq type-summary (subst (cons type (+ (cdr existing) area-val)) existing type-summary))
             (setq type-summary (cons (cons type area-val) type-summary))
           )
         )
         (foreach type-item type-summary
           (princ (strcat "  " (car type-item) ": " (rtos (cdr type-item) 2 4) "\n"))
         )
       )
     )

     (PM:PrintLine "-" 50)
     (princ (strcat "总计面积 = " (rtos total-area 2 4) "\n"))
     (princ (strcat "对象总数 = " (itoa (sslength selection)) "\n"))
     (PM:PrintLine "=" 50)

     (alert (strcat "面积计算完成!\n\n"
                    "总面积: " (rtos total-area 2 4) "\n"
                    "对象数量: " (itoa (sslength selection))))

     (setvar "cmdecho" old-cmdecho)
     (princ))

    (t
     (princ "\n未选择任何对象或选择无效。")
     (setvar "cmdecho" old-cmdecho)
     (princ)))

  (princ)
)