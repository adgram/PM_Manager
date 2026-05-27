;; PM_Block.lsp - 块参照操作函数
;; 职责：所有与图块（Block）相关的查询、统计、编辑函数
;; 依赖：PM_Core.lsp

;; 统计全图中指定块名的所有实例数量
(defun PM:CountBlockByName (blockName / allInst)
  (if (setq allInst (ssget "X" (list (cons 2 blockName))))
    (sslength allInst)
    0
  )
)

;; 获取选中实体的块名（若为块参照），动态块返回有效名
(defun PM:GetBlockName (ent / data obj)
  (if (= "INSERT" (cdr (assoc 0 (entget ent))))
    (if (setq obj (vlax-ename->vla-object ent))
      (if (vlax-property-available-p obj 'effectivename)
        (vla-get-effectivename obj)
        (vla-get-name obj)
      )
    )
    (prompt "\n错误: 选中对象不是块参照")
  )
)
