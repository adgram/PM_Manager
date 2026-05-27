;; LayerTool.LSP - 图层管理工具
;; 命令：PMLayer / PMLayerCreate / PMLayerQuick / PMLayerOnAll / PMLayerOff / PMLayerOffOthers
;; 功能：创建图层、切换当前图层、快速切换预设图层、图层全开、关闭图层、关闭其他图层
;; 依赖：lib-pm/PM_Layer.lsp

(vl-load-com)

;; ======== 用户配置区 ========
;; 快速切换预设图层列表（最多 9 个）
;; 格式: (名称 颜色号)
(setq *PM:QuickLayers*
  '(
    ("0"            7)
    ("DIM"          3)
    ("TEXT"         7)
    ("HATCH"        8)
    ("CENTER"       1)
    ("HIDDEN"       2)
    ("THICK"        4)
    ("LIGHT"        5)
    ("VIEWPORT"     6)
  )
)

(defun c:PMLayer (/ name)
  (or *PM-Layer-Loaded* (load "lib-pm/PM_Layer"))
  (princ "\n=== 切换图层 ===\n")
  (if (/= (setq name (getstring "\n请输入图层名称: ")) "")
    (progn
      (PM:SetLayerCurrent name)
      (princ (strcat "\n当前图层: " name))
    )
  )
  (princ)
)

(defun c:PMLayerCreate (/ name color)
  (or *PM-Layer-Loaded* (load "lib-pm/PM_Layer"))
  (princ "\n=== 创建图层 ===\n")
  (if (/= (setq name (getstring "\n图层名称: ")) "")
    (progn
      (setq color (getint "\n颜色号 <7(白/黑)>: "))
      (if (null color) (setq color 7))
      (PM:CreateLayerWithColor name color)
      (setvar "CLAYER" name)
      (princ (strcat "\n图层 \"" name "\" 已创建，颜色: " (itoa color) "，已切换为当前"))
    )
  )
  (princ)
)

(defun c:PMLayerQuick (/ i n name)
  (or *PM-Layer-Loaded* (load "lib-pm/PM_Layer"))
  (princ "\n=== 快速切换图层 ===\n")
  (setq i 0)
  (foreach pair *PM:QuickLayers*
    (setq i (1+ i))
    (princ (strcat "\n  " (itoa i) ". " (car pair) " (颜色 " (itoa (cadr pair)) ")"))
  )
  (princ (strcat "\n  Q. 自定义图层\n"))
  (setq n (getstring "\n请选择编号: "))
  (cond
    ((wcmatch n "Qq")
     (if (/= (setq name (getstring "\n请输入图层名称: ")) "")
       (PM:SetLayerCurrent name)
     )
    )
    ((setq i (atoi n))
     (if (and (> i 0) (<= i (length *PM:QuickLayers*)))
       (progn
         (setq pair (nth (1- i) *PM:QuickLayers*))
         (PM:CreateLayerWithColor (car pair) (cadr pair))
         (setvar "CLAYER" (car pair))
         (princ (strcat "\n当前图层: " (car pair)))
       )
       (princ "\n无效编号")
     )
    )
  )
  (princ)
)

(defun c:PMLayerOnAll nil
  (or *PM-Layer-Loaded* (load "lib-pm/PM_Layer"))
  (princ "\n=== 图层全开 ===\n")
  (PM:TurnOnAllLayers)
  (princ "所有图层已打开并解冻")
  (princ)
)

(defun c:PMLayerOff (/ sel i name layerNames)
  (or *PM-Layer-Loaded* (load "lib-pm/PM_Layer"))
  (princ "\n=== 关闭图层 ===\n")
  (setq sel (ssget "_I"))
  (if (null sel)
    (setq sel (ssget))
  )
  (if sel
    (progn
      (repeat (setq i (sslength sel))
        (setq name (cdr (assoc 8 (entget (ssname sel (setq i (1- i)))))))
        (if (not (member name layerNames))
          (setq layerNames (cons name layerNames))
        )
      )
      (PM:TurnOffLayers layerNames)
      (princ (strcat "已关闭图层: " (apply 'strcat (mapcar '(lambda (x) (strcat " " x)) layerNames))))
    )
  )
  (princ)
)

(defun c:PMLayerOffOthers (/ sel i name layerNames)
  (or *PM-Layer-Loaded* (load "lib-pm/PM_Layer"))
  (princ "\n=== 关闭其他图层 ===\n")
  (setq sel (ssget "_I"))
  (if (null sel)
    (setq sel (ssget (strcat "\n选择要保留的图元")))
  )
  (if sel
    (progn
      (repeat (setq i (sslength sel))
        (setq name (cdr (assoc 8 (entget (ssname sel (setq i (1- i)))))))
        (if (not (member name layerNames))
          (setq layerNames (cons name layerNames))
        )
      )
      (PM:TurnOffOtherLayers layerNames)
      (princ (strcat "已保留图层: " (apply 'strcat (mapcar '(lambda (x) (strcat " " x)) layerNames))))
    )
  )
  (princ)
)
