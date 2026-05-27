;; PM_Layer.lsp - 图层操作函数
;; 职责：图层锁定/解锁、冻结/解冻、图层查询等
;; 依赖：PM_Core.lsp

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
