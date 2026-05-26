;;--------------------=={ 修改图块基点 }==-------------------;;
;;                                                                      ;;
;;  本程序可以修改所有图块或参照的基点                ;;
;;  本程序有两个命令：                                    ;;
;;  ------------------------------------------------------------------  ;;
;;  ChangeBasePoint (修改基点)                                             ;;
;;  该命令保持插入点位置不变，即修改基点后图块视觉上将发生位置变动   ;;
;;  ChangeBasePointRetainPosition (修改基点并保留块位置)                  ;;
;;  该命令会同时修改插入点位置，使修改基点后图块视觉上位置不变     ;;
;;  ------------------------------------------------------------------  ;;
;;  在CAD中执行命令后，程序将有以下操作：             ;;
;;  1、提示用户选择需要修改基点的图块                   ;;
;;  2、提示用户选择新的基点位置                   ;;
;;  3、修改块定义，并更新所有同定义的块；如果块具有自定义属性，还将执行ATTSYNC操作，以同步更新块的属性基点参照   ;;
;;  4、更新窗口                   ;;
;;  ------------------------------------------------------------------  ;;
;;  注意：如果执行UNDO命令撤销操作，则需要使用REGEN命令进行更新   ;;
;;----------------------------------------------------------------------;;
;;  Author:  Lee Mac, Copyright ?2013  -  www.lee-mac.com              ;;
;;  Version 1.5    -    20-10-2013                                      ;;
;;----------------------------------------------------------------------;;

;; 修改基点
(defun C:ChangeBasePoint  nil (LM:changeblockbasepoint nil))

;; 修改基点并保留块位置
(defun C:ChangeBasePointRetainPosition nil (LM:changeblockbasepoint t))

;;----------------------------------------------------------------------;;

(defun LM:changeblockbasepoint ( flg / *error* bln cmd ent lck mat nbp vec )

    (defun *error* ( msg )
        (foreach lay lck (vla-put-lock lay :vlax-true))
        (if (= 'int (type cmd)) (setvar 'cmdecho cmd))
        (LM:endundo (LM:acdoc))
        (if (not (wcmatch (strcase msg t) "*break,*cancel*,*exit*"))
            (princ (strcat "\nError: " msg))
        )
        (princ)
    )

    (while
        (progn (setvar 'errno 0) (setq ent (car (entsel "\n选择图块: ")))
            (cond
                (   (= 7 (getvar 'errno))
                    (princ "\n选择失败，请重试.")
                )
                (   (= 'ename (type ent))
                    (if (/= "INSERT" (cdr (assoc 0 (entget ent))))
                        (princ "\n选定对象不是块.")
                    )
                )
            )
        )
    )
    (if (and (= 'ename (type ent)) (setq nbp (getpoint "\n指定新基点：")))
        (progn
            (setq mat (car (revrefgeom ent))
                  vec (mxv mat (mapcar '- (trans nbp 1 0) (trans (cdr (assoc 10 (entget ent))) ent 0)))
                  bln (LM:blockname (vlax-ename->vla-object ent))
            )
            (LM:startundo (LM:acdoc))
            (vlax-for lay (vla-get-layers (LM:acdoc))
                (if (= :vlax-true (vla-get-lock lay))
                    (progn
                        (vla-put-lock lay :vlax-false)
                        (setq lck (cons lay lck))
                    )
                )
            )
            (vlax-for obj (vla-item (vla-get-blocks (LM:acdoc)) bln)
                 (vlax-invoke obj 'move vec '(0.0 0.0 0.0))
            )
            (if flg
                (vlax-for blk (vla-get-blocks (LM:acdoc))
                    (if (= :vlax-false (vla-get-isxref blk))
                        (vlax-for obj blk
                            (if
                                (and
                                    (= "AcDbBlockReference" (vla-get-objectname obj))
                                    (= bln (LM:blockname obj))
                                    (vlax-write-enabled-p obj)
                                )
                                (vlax-invoke obj 'move '(0.0 0.0 0.0) (mxv (car (refgeom (vlax-vla-object->ename obj))) vec))
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
            (vla-regen  (LM:acdoc) acallviewports)
            (LM:endundo (LM:acdoc))
        )
    )
    (princ)
)

;; RefGeom (gile)
;; Returns a list whose first item is a 3x3 transformation matrix and
;; second item the object insertion point in its parent (xref, block or space)

(defun refgeom ( ent / ang enx mat ocs )
    (setq enx (entget ent)
          ang (cdr (assoc 050 enx))
          ocs (cdr (assoc 210 enx))
    )
    (list
        (setq mat
            (mxm
                (mapcar '(lambda ( v ) (trans v 0 ocs t))
                   '(
                        (1.0 0.0 0.0)
                        (0.0 1.0 0.0)
                        (0.0 0.0 1.0)
                    )
                )
                (mxm
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
            (mxv mat (cdr (assoc 10 (tblsearch "block" (cdr (assoc 2 enx))))))
        )
    )
)

;; RevRefGeom (gile)
;; The inverse of RefGeom

(defun revrefgeom ( ent / ang enx mat ocs )
    (setq enx (entget ent)
          ang (cdr (assoc 050 enx))
          ocs (cdr (assoc 210 enx))
    )
    (list
        (setq mat
            (mxm
                (list
                    (list (/ 1.0 (cdr (assoc 41 enx))) 0.0 0.0)
                    (list 0.0 (/ 1.0 (cdr (assoc 42 enx))) 0.0)
                    (list 0.0 0.0 (/ 1.0 (cdr (assoc 43 enx))))
                )
                (mxm
                    (list
                        (list (cos ang)     (sin ang) 0.0)
                        (list (- (sin ang)) (cos ang) 0.0)
                       '(0.0 0.0 1.0)
                    )
                    (mapcar '(lambda ( v ) (trans v ocs 0 t))
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
            (mxv mat (trans (cdr (assoc 10 enx)) ocs 0))
        )
    )
)

;; Matrix x Vector  -  Vladimir Nesterovsky
;; Args: m - nxn matrix, v - vector in R^n

(defun mxv ( m v )
    (mapcar '(lambda ( r ) (apply '+ (mapcar '* r v))) m)
)

;; Matrix x Matrix  -  Vladimir Nesterovsky
;; Args: m,n - nxn matrices

(defun mxm ( m n )
    ((lambda ( a ) (mapcar '(lambda ( r ) (mxv a r)) m)) (trp n))
)

;; Matrix Transpose  -  Doug Wilson
;; Args: m - nxn matrix

(defun trp ( m )
    (apply 'mapcar (cons 'list m))
)

;; Block Name  -  Lee Mac
;; Returns the true (effective) name of a supplied block reference
                        
(defun LM:blockname ( obj )
    (if (vlax-property-available-p obj 'effectivename)
        (defun LM:blockname ( obj ) (vla-get-effectivename obj))
        (defun LM:blockname ( obj ) (vla-get-name obj))
    )
    (LM:blockname obj)
)

;; Start Undo  -  Lee Mac
;; Opens an Undo Group.

(defun LM:startundo ( doc )
    (LM:endundo doc)
    (vla-startundomark doc)
)

;; End Undo  -  Lee Mac
;; Closes an Undo Group.

(defun LM:endundo ( doc )
    (while (= 8 (logand 8 (getvar 'undoctl)))
        (vla-endundomark doc)
    )
)

;; Active Document  -  Lee Mac
;; Returns the VLA Active Document Object

(defun LM:acdoc nil
    (eval (list 'defun 'LM:acdoc 'nil (vla-get-activedocument (vlax-get-acad-object))))
    (LM:acdoc)
)

;;----------------------------------------------------------------------;;

(vl-load-com)

;;----------------------------------------------------------------------;;
;;                             End of File                              ;;
;;----------------------------------------------------------------------;;