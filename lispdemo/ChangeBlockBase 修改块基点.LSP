;;--------------------=={ Change Block Base Point }==--------------------;;
;;                                                                      ;;
;;  程序用于修改选中的块参照的基点                                      ;;
;;  程序提供两个独立命令：                                              ;;
;;  ------------------------------------------------------------------  ;;
;;  ChangeBasePoint (修改基点)                                           ;;
;;  命令保持块位置不变，修改基点后块从视觉上位置变动                    ;;
;;  ChangeBasePointRetainPosition (修改基点并保留位置)                    ;;
;;  命令同时修改块的位置，使修改基点后块从视觉上位置不变                ;;
;;  ------------------------------------------------------------------  ;;
;;  在CAD中执行命令后，程序按以下步骤操作：                             ;;
;;  1.提示用户选择需要修改基点的块                                      ;;
;;  2.提示用户选择新的基点位置                                          ;;
;;  3.修改块定义，并更新当前图中所有同名块；                            ;;
;;    如果块含有属性，自动执行ATTSYNC命令同步属性                       ;;
;;  4.重生成图形                                                        ;;
;;  ------------------------------------------------------------------  ;;
;;  注意：如果执行UNDO命令撤销本操作，需要使用REGEN命令更新            ;;
;;----------------------------------------------------------------------;;
;;  Author:  Lee Mac, Copyright (c) 2013  -  www.lee-mac.com            ;;
;;  Version 1.5    -    20-10-2013                                      ;;
;;----------------------------------------------------------------------;;

(vl-load-com)

(defun PM:EnsureLib ()
  (or *PM-LibDir*
    (setq *PM-LibDir* (strcat (vl-filename-directory (getvar "lastloaded")) "\\lib-pm\\"))
  )
  (or *PM-Core-Loaded* (load (strcat *PM-LibDir* "PM_Core")))
  (or *PM-Block-Loaded* (load (strcat *PM-LibDir* "PM_Block")))
)

;; 修改基点
(defun C:ChangeBasePoint nil (PM:EnsureLib) (LM:changeblockbasepoint nil))

;; 修改基点并保留位置
(defun C:ChangeBasePointRetainPosition nil (PM:EnsureLib) (LM:changeblockbasepoint t))

;;----------------------------------------------------------------------;;

(defun LM:changeblockbasepoint (flg / *error* bln cmd ent lck mat nbp vec)

  (defun *error* (msg)
    (foreach lay lck (vla-put-lock lay :vlax-true))
    (if (= 'int (type cmd)) (setvar 'cmdecho cmd))
    (PM:EndUndo (PM:AcDoc))
    (if (not (wcmatch (strcase msg t) "*break,*cancel*,*exit*"))
      (princ (strcat "\n错误: " msg))
    )
    (princ)
  )

  (while
    (progn (setvar 'errno 0) (setq ent (car (entsel "\n选择块: ")))
      (cond
        ((= 7 (getvar 'errno))
         (princ "\n选择失败，请重试."))
        ((= 'ename (type ent))
         (if (/= "INSERT" (cdr (assoc 0 (entget ent))))
           (princ "\n选择对象不是块."))
        )
      )
    )
  )
  (if (and (= 'ename (type ent)) (setq nbp (getpoint "\n指定新基点:")))
    (progn
      (setq mat (car (revrefgeom ent))
            vec (PM:mxv mat (mapcar '- (trans nbp 1 0) (trans (cdr (assoc 10 (entget ent))) ent 0)))
            bln (PM:GetBlockName ent)
      )
      (PM:StartUndo (PM:AcDoc))
      (vlax-for lay (vla-get-layers (PM:AcDoc))
        (if (= :vlax-true (vla-get-lock lay))
          (progn
            (vla-put-lock lay :vlax-false)
            (setq lck (cons lay lck))
          )
        )
      )
      (vlax-for obj (vla-item (vla-get-blocks (PM:AcDoc)) bln)
        (vlax-invoke obj 'move vec '(0.0 0.0 0.0))
      )
      (if flg
        (vlax-for blk (vla-get-blocks (PM:AcDoc))
          (if (= :vlax-false (vla-get-isxref blk))
            (vlax-for obj blk
              (if
                (and
                  (= "AcDbBlockReference" (vla-get-objectname obj))
                  (= bln (PM:GetBlockName obj))
                  (vlax-write-enabled-p obj)
                )
                (vlax-invoke obj 'move '(0.0 0.0 0.0) (PM:mxv (car (refgeom (vlax-vla-object->ename obj))) vec))
              )
            )
          )
        )
      )
      (if (= 1 (cdr (assoc 66 (entget ent))))
        (progn
          (setq cmd (getvar 'cmdecho))
          (setvar 'cmdecho 0)
          (vl-cmdf "_.attsync" "_N" bln)
          (setvar 'cmdecho cmd)
        )
      )
      (foreach lay lck (vla-put-lock lay :vlax-true))
      (vla-regen (PM:AcDoc) acallviewports)
      (PM:EndUndo (PM:AcDoc))
    )
  )
  (princ)
)

;; RefGeom (gile)
(defun refgeom (ent / ang enx mat ocs)
  (setq enx (entget ent)
        ang (cdr (assoc 050 enx))
        ocs (cdr (assoc 210 enx))
  )
  (list
    (setq mat
      (PM:mxm
        (mapcar '(lambda (v) (trans v 0 ocs t))
          '(
            (1.0 0.0 0.0)
            (0.0 1.0 0.0)
            (0.0 0.0 1.0)
          )
        )
        (PM:mxm
          (list
            (list (cos ang) (- (sin ang)) 0.0)
            (list (sin ang) (cos ang)     0.0)
            '(0.0 0.0 1.0)
          )
          (list
            (list (cdr (assoc 41 enx)) 0.0 0.0)
            (list 0.0 (cdr (assoc 42 enx)) 0.0)
            (list 0.0 0.0 (cdr (assoc 43 enx)))
          )
        )
      )
    )
    (mapcar '- (trans (cdr (assoc 10 enx)) ocs 0)
      (PM:mxv mat (cdr (assoc 10 (tblsearch "block" (cdr (assoc 2 enx))))))
    )
  )
)

;; RevRefGeom (gile)
(defun revrefgeom (ent / ang enx mat ocs)
  (setq enx (entget ent)
        ang (cdr (assoc 050 enx))
        ocs (cdr (assoc 210 enx))
  )
  (list
    (setq mat
      (PM:mxm
        (list
          (list (/ 1.0 (cdr (assoc 41 enx))) 0.0 0.0)
          (list 0.0 (/ 1.0 (cdr (assoc 42 enx))) 0.0)
          (list 0.0 0.0 (/ 1.0 (cdr (assoc 43 enx))))
        )
        (PM:mxm
          (list
            (list (cos ang)     (sin ang) 0.0)
            (list (- (sin ang)) (cos ang) 0.0)
            '(0.0 0.0 1.0)
          )
          (mapcar '(lambda (v) (trans v ocs 0 t))
            '(
              (1.0 0.0 0.0)
              (0.0 1.0 0.0)
              (0.0 0.0 1.0)
            )
          )
        )
      )
    )
    (mapcar '- (cdr (assoc 10 (tblsearch "block" (cdr (assoc 2 enx)))))
      (PM:mxv mat (trans (cdr (assoc 10 enx)) ocs 0))
    )
  )
)

;;----------------------------------------------------------------------;;
;;                             End of File                              ;;
;;----------------------------------------------------------------------;;