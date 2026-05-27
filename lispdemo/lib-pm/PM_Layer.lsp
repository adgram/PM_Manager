;; PM_Layer.lsp - 图层操作函数
;; 职责：图层创建/切换、锁定/解锁、冻结/解冻、图层查询等
;; 依赖：PM_Core.lsp

(vl-load-com)
(setq *PM-Layer-Loaded* T)

;; 创建图层（如已存在则跳过）
(defun PM:CreateLayer (name)
  (if (not (tblsearch "LAYER" name))
    (vla-add (vla-get-layers (vla-get-activedocument (vlax-get-acad-object))) name)
  )
)

;; 创建图层并设置颜色
(defun PM:CreateLayerWithColor (name color / layer)
  (if (not (tblsearch "LAYER" name))
    (progn
      (setq layer (PM:CreateLayer name))
      (vla-put-color layer color)
      layer
    )
    (vlax-ename->vla-object (tblobjname "LAYER" name))
  )
)

;; 切换当前图层（创建如不存在）
(defun PM:SetLayerCurrent (name)
  (PM:CreateLayer name)
  (setvar "CLAYER" name)
)

;; 获取图层颜色
(defun PM:GetLayerColor (name / ent)
  (if (setq ent (tblobjname "LAYER" name))
    (cdr (assoc 62 (entget ent)))
  )
)

;; 解锁所有图层，返回原锁定图层列表
(defun PM:UnlockAllLayers (*DOC / locks)
  (vlax-for x (vla-get-layers *DOC)
    (if (= (vla-get-lock x) :vlax-true)
      (progn
        (setq locks (cons x locks))
        (vla-put-lock x :vlax-false)
      )
    )
  )
  (reverse locks)
)

;; 恢复图层锁定状态
(defun PM:RestoreLockedLayers (locks)
  (if locks
    (mapcar (function (lambda (x) (vla-put-lock x :vlax-true))) locks)
  )
)

;; 解冻所有图层，返回原冻结图层列表
(defun PM:UnFreezeAllLayers (*DOC / layers)
  (vlax-for x (vla-get-layers *DOC)
    (if (= (vla-get-freeze x) :vlax-true)
      (progn
        (setq layers (cons x layers))
        (vla-put-freeze x :vlax-false)
      )
    )
  )
  (reverse layers)
)
