(vl-load-com)

;;;*************************************************************
;;;将CAD图元坐标、顶点、长度、角度等归算到整数、整数倍容差
;;;支持直线、圆、圆弧、多段线、块、柱、门窗、墙等
;;;可自动容差检测，容差点会被捕获
;;;*************************************************************

(defun C:AutoCorrect (/ *DOC Ent I Locks BasePt Sel str TOL Data filter *error*_Old *error*_New)
  (or *PM-LibDir*
    (setq *PM-LibDir* (strcat (vl-filename-directory (getvar "lastloaded")) "\\library\\"))
  )
  (or *PM-Core-Loaded* (load (strcat *PM-LibDir* "PM_Core")))
  (or *PM-Layer-Loaded* (load (strcat *PM-LibDir* "PM_Layer")))

  ;;自定义错误处理
  (defun *error*_New (msg)
    (setq *error* *error*_Old)
    (if (wcmatch (strcase msg t) "*break,*cancel*,*exit*,*取消*")
      (if (= (getvar "LOCALE") "CHS")
        (princ "\n用户按<Esc>强制退出")
        (princ "\nYou cancelled The operation!")
      )
      (princ (strcat "\n" msg))
    )
    (vla-EndUndoMark (vla-get-ActiveDocument (vlax-get-acad-object)))
    (PM:RestoreLockedLayers Locks)
    (princ)
  )
  (setq *error*_Old *error*)
  (setq *error* *error*_New)

  ;;初始化
  (setq *DOC (vla-get-ActiveDocument (vlax-get-acad-object)))
  (vla-StartUndoMark *DOC)
  (setq Locks (PM:UnlockAllLayers *DOC))
  (setq Data (read (getvar "USERS5")))
  (if (not (CheckData data))
    (setq Data (SetDefault))
  )

  (setq TOL (cdr (assoc "TOL" Data)))
  ;;选择部分
  (setq str (strcat "\n请选择[设置(Set)]<" TOL ">:"))
  (initget "Set")
  (setq BasePt (getpoint str))
  (cond
    ( (= BasePt "Set")
      (setq Data (C:SetByDCL))
      (setq BasePt (list (atof (cdr (assoc "X" Data)))
                         (atof (cdr (assoc "Y" Data)))
                         (atof (cdr (assoc "Z" Data)))
                   )
      )
    )
    ( BasePt
      (setq Data (PM:Replace "X" (rtos (car BasePt) 2 20) Data))
      (setq Data (PM:Replace "Y" (rtos (cadr BasePt) 2 20) Data))
      (setq Data (PM:Replace "Z" (rtos (caddr BasePt) 2 20) Data))
      (setvar "USERS5" (VL-PRIN1-TO-STRING data))
    )
    (t
      (setq BasePt '(0 0 0))
    )
  )

  ;;获取容差
  (setq Data (read (getvar "USERS5")))
  (setq TOL (atof (cdr (assoc "TOL" Data))))
  (if (<= TOL 0)
    (progn
      (setq TOL 50.0)
      (setq Data (PM:Replace "TOL" "50.0" Data))
      (setvar "USERS5" (VL-PRIN1-TO-STRING data))
    )
  )

  ;;获取图元过滤
  (setq filter "")
  (repeat 10
    (if (= (cdar Data) "1")
      (setq filter (strcat filter "," (caar data)))
    )
    (setq Data (cdr Data))
  )
  (setq filter (substr filter 2))
  (if (= filter "")
    (setq filter "*LINE,INSERT,CIRCLE,ARC,ELLIPSE,*_COLUMN,*_OPENING,*_WALL")
  )

  ;;归正操作
  (setq i 0)
  (if (setq sel (ssget (list (cons 0 filter))))
    (repeat (sslength sel)
      (setq ent (ssname sel i))
      (RoundEnt ent BasePt TOL)
      (setq i (1+ i))
    )
  )

  ;;收尾处理
  (PM:RestoreLockedLayers Locks)
  (vla-EndUndoMark *DOC)
  (princ)
)

;;;*************************************************************
;;;归正函数
;;;输入: ent      图元
;;;       BasePt  基点
;;;       tol     容差
;;;返回: 无
;;;*************************************************************
(defun RoundEnt (ent BasePt TOL / DXF typ obj pt1 pt2 e pts lst)
  (setq DXF (entget ent))
  (setq typ (cdr (assoc 0 DXF)))
  (setq obj (vlax-ename->vla-object ent))
  (cond
    ( (or (= "LINE" typ)
          (wcmatch typ "*_WALL")
          (wcmatch typ "*_OPENING")
      )
      (setq pt1 (cdr (assoc 10 DXF)))
      (setq pt2 (cdr (assoc 11 DXF)))
      (setq pt1 (RoundPoint pt1 BasePt TOL))
      (setq pt2 (RoundPoint pt2 BasePt TOL))
      (setq DXF (PM:Replace 10 pt1 DXF))
      (setq DXF (PM:Replace 11 pt2 DXF))
      (entmod DXF)
      (entupd ent)
    )

    ( (= "LWPOLYLINE" typ)
      (setq pts nil)
      (foreach x DXF
        (if (= (car x) 10)
          (setq pt1 (RoundPoint (cdr x) BasePt TOL)
                pts (cons (cons 10 pt1) pts)
          )
          (setq pts (cons x pts))
        )
      )
      (setq pts (reverse pts))
      (entmod pts)
      (entupd ent)
    )

    ( (= "POLYLINE" typ)
      (setq e (entnext ent))
      (while (/= (cdr (assoc 0 (setq lst (entget e)))) "SEQEND")
        (setq pt1 (cdr (assoc 10 lst)))
        (setq pt1 (RoundPoint pt1 BasePt TOL))
        (setq lst (PM:Replace 10 pt1 lst))
        (entmod lst)
        (entupd e)
        (setq e (entnext e))
      )
    )
    ( (or (= "INSERT" typ)
          (= "CIRCLE" typ)
          (= "ARC" typ)
          (= "ELLIPSE" typ)
      )
      (setq pt1 (cdr (assoc 10 DXF)))
      (setq pt1 (RoundPoint pt1 BasePt TOL))
      (setq DXF (PM:Replace 10 pt1 DXF))
      (entmod DXF)
      (entupd ent)
    )

    ( (wcmatch typ "*_COLUMN")
      (setq pt1 (cdr (assoc 11 DXF)))
      (setq pt1 (RoundPoint pt1 BasePt TOL))
      (setq DXF (PM:Replace 11 pt1 DXF))
      (entmod DXF)
      (entupd ent)
    )
  )
)

;;;*************************************************************
;;;对点归正--适用于AutoLISP格式点(坐标点为用户坐标系)
;;;输入: Point    要归正的点，以表形式
;;;       BasePt  基点
;;;       tol     容差
;;;返回: Pnt      归正后的点(相对基点)，以表形式
;;;*************************************************************
(defun RoundPoint (Point BasePt TOL / Pnt ptX ptY)
  (setq Pnt (trans Point 0 1))
  (setq Pnt (mapcar '- Pnt BasePt))
  (setq ptX (car Pnt))
  (setq ptY (cadr Pnt))
  (setq ptX (PM:Round ptX TOL))
  (setq ptY (PM:Round ptY TOL))
  (if (caddr Point)
    (setq Pnt (list ptX ptY 0))
    (setq Pnt (list ptX ptY))
  )
  (setq Pnt (mapcar '+ Pnt BasePt))
  (setq Pnt (trans Pnt 1 0))
  (if (caddr Point)
    Pnt
    (list (car Pnt) (cadr Pnt))
  )
)

;;;*************************************************************
;;;对点归正--适用于ActiveX格式点
;;;输入: Array    要归正的点，以安全数组格式
;;;       BasePt  基点
;;;       tol     容差
;;;返回: Pnt      归正后的点(相对基点)，以安全数组格式
;;;*************************************************************
(defun RoundArray (Array BasePt TOL / Pnt)
  (setq Pnt (PM:ArrayToList Array))
  (setq Pnt (RoundPoint Pnt BasePt TOL))
  (setq Pnt (PM:ListToArray Pnt))
)

;;;*************************************************************
;;;设置默认参数
;;;*************************************************************
(defun SetDefault ( / Default)
  (setq Default
     '(("LINE" . "1")
       ("LWPOLYLINE" . "1")
       ("POLYLINE" . "1")
       ("ARC" . "1")
       ("CIRCLE" . "1")
       ("ELLIPSE" . "1")
       ("INSERT" . "1")
       ("*_COLUMN" . "1")
       ("*_OPENING" . "1")
       ("*_WALL" . "1")
       ("TOL" . "50.0")
       ("X" . "0.0")
       ("Y" . "0.0")
       ("Z" . "0.0")
      )
  )
  (setvar "USERS5" (VL-PRIN1-TO-STRING Default))
  Default
)

;;;*************************************************************
;;;检查数据
;;;*************************************************************
(defun CheckData (data)
  (equal
    (mapcar 'car data)
    (list
      "LINE" "LWPOLYLINE" "POLYLINE" "ARC" "CIRCLE" "ELLIPSE"
      "INSERT" "*_COLUMN" "*_OPENING" "*_WALL" "TOL" "X" "Y" "Z"
    )
  )
)

;;;*************************************************************
;;;用对话框获取参数
;;;对话框为动态生成，参数可以保存。
;;;*************************************************************
(defun C:SetByDCL(/ catchit)
  (setq catchit (VL-CATCH-ALL-APPLY 'dcl_load))
  (if (vl-catch-all-error-p catchit)
    (progn
      (princ "\n错误信息:")
      (princ (vl-catch-all-error-message catchit))
      nil
    )
    catchit
  )
)

;;;Load the dialog
(defun DCL_load (/ dcl_id DlgRet Dcl_File data)
  (setq Dcl_File (Write_Dcl (DialogData)))
  (setq dcl_id (load_dialog Dcl_File))
  (vl-file-delete Dcl_File)

  (setq data (read (getvar "USERS5")))
  (if (not (CheckData data))
    (setq data (SetDefault))
  )

  (setq DlgRet 2)
  (while (> DlgRet 1)
    (new_dialog "DCL" dcl_id)
    (InitiateDialog data)
    (setq DlgRet (start_dialog))
    (cond
      ( (= DlgRet 2)
        (setq data (GETTOL data))
      )
      ( (= DlgRet 3)
        (setq data (PickBasePoint data))
      )
    )
  )

  (cond
    ( (= DlgRet 0)
      (princ "\n已取消操作。")
    )
  )
  (setvar "USERS5" (VL-PRIN1-TO-STRING data))
  (unload_dialog dcl_id)
  data
)

;;;初始化对话框
(defun InitiateDialog (data)
  (action_tile "help" "(helpMsg)")
  (action_tile "PICK" "(done_dialog 3)")
  (action_tile "GETTOL" "(done_dialog 2)")
  (foreach key data
    (and (cdr key) (set_tile (car key) (cdr key)))
    (action_tile (car key)"(Action_DCL_Keys   )")
  )
)

;;;从图形中获取容差
(defun GETTOL (data / dist sDist)
  (Initget 14)
  (setq dist (getdist "\n请输入容差:"))
  (if dist
    (progn
      (setq sDist (rtos dist 2 20))
      (set_tile "TOL" sDist)
      (PM:Replace "TOL" sDist data)
    )
    data
  )
)

;;;从图形中获取基点
(defun PickBasePoint (data / Pnt strX strY strZ NewDat)
  (Initget 8)
  (setq Pnt (getPoint "\n请选择基点:"))
  (if Pnt
    (progn
      (setq strX (rtos (car pnt) 2 20))
      (setq strY (rtos (cadr pnt) 2 20))
      (setq strZ (rtos (caddr pnt) 2 20))
      (set_tile "X" strX)
      (set_tile "Y" strY)
      (set_tile "Z" strZ)
      (setq NewDat data)
      (setq NewDat (PM:Replace "X" strX NewDat))
      (setq NewDat (PM:Replace "Y" strY NewDat))
      (setq NewDat (PM:Replace "Z" strZ NewDat))
    )
    data
  )
)

;;;在此处添加自己的帮助信息
(defun helpMsg()
  (alert "未提供帮助文档!")
)

;;;所有控件的动作响应
(defun Action_DCL_Keys (key value keydata / str)
  (setq str (get_tile key))
  (cond
    ( (= key "TOL")
      (if (<= (atof str) 0)
        (progn
          (alert "错误: 请输入正数!")
          (set_tile "TOL" "50.0")
          (setq str "50.0")
        )
        (setq str (rtos (atof str) 2 20))
      )
    )
    ( (or (= key "X")
          (= key "Y")
          (= key "Z")
      )
      (setq str (rtos (atof str) 2 20))
    )
  )
  (setq data (PM:Replace key str data))
)

;;;临时生成Dcl文件 及文件内容
(defun Write_Dcl (DialogData / Dcl_File file str)
  (setq Dcl_File (vl-filename-mktemp nil nil ".DCL"))
  (setq file (open Dcl_File "W"))
  (foreach str DialogData
    (write-line str file)
  )
  (close file)
  Dcl_File
)

(defun DialogData ()
  (list "DCL:dialog"
        "{"
                "key = \"DLG\" ;"
                "label = \"归正设置\";"
                "spacer;"
                ":boxed_row"
                "{"
                        "label = \"图元选取\" ;"
                        ":column"
                        "{"
                                ":toggle"
                                "{"
                                        "key = \"LINE\" ;"
                                        "label = \"线段\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"LWPOLYLINE\" ;"
                                        "label = \"轻量多段线\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"POLYLINE\" ;"
                                        "label = \"三维多段线\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"ARC\" ;"
                                        "label = \"弧\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"CIRCLE\" ;"
                                        "label = \"圆\" ;"
                                        "value = 1 ;"
                                "}"
                        "}"

                        ":column"
                        "{"
                                ":toggle"
                                "{"
                                        "key = \"ELLIPSE\" ;"
                                        "label = \"椭圆\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"INSERT\" ;"
                                        "label = \"块参照\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"*_COLUMN\" ;"
                                        "label = \"柱子\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"*_OPENING\" ;"
                                        "label = \"门窗\" ;"
                                        "value = 1 ;"
                                "}"

                                ":toggle"
                                "{"
                                        "key = \"*_WALL\" ;"
                                        "label = \"墙\" ;"
                                        "value = 1 ;"
                                "}"
                        "}"
                "}"

                ":boxed_column"
                "{"
                        "label = \"容差设置\" ;"
                        ":row"
                        "{"
                                ":text"
                                "{"
                                        "key = \"LABLE1\" ;"
                                        "label = \"容差\" ;"
                                "}"

                                ":edit_box"
                                "{"
                                        "key = \"TOL\" ;"
                                        "value = \"50.0\" ;"
                                        "fixed_width = true;"
                                        "width = 15;"
                                "}"

                                ":button"
                                "{"
                                        "key = \"GETTOL\";"
                                        "label = \"获取容差\";"
                                "}"
                        "}"
                        "spacer;"
                "}"

                ":boxed_row"
                "{"
                        "label = \"基点设置\" ;"
                        ":column"
                        "{"
                                ":row"
                                "{"
                                        ":text"
                                        "{"
                                                "key = \"LABLEX\" ;"
                                                "label = \"X=   \" ;"
                                        "}"

                                        ":edit_box"
                                        "{"
                                                "key = \"X\" ;"
                                                "value = \"0.0\" ;"
                                                "fixed_width = true;"
                                                "width = 15;"
                                        "}"
                                "}"

                                ":row"
                                "{"
                                        ":text"
                                        "{"
                                                "key = \"LABLEY\" ;"
                                                "label = \"Y=   \" ;"
                                        "}"

                                        ":edit_box"
                                        "{"
                                                "key = \"Y\" ;"
                                                "value = \"0.0\" ;"
                                                "fixed_width = true;"
                                                "width = 15;"
                                        "}"
                                "}"

                                ":row"
                                "{"
                                        ":text"
                                        "{"
                                                "key = \"LABLEZ\" ;"
                                                "label = \"Z=   \" ;"
                                        "}"

                                        ":edit_box"
                                        "{"
                                                "key = \"Z\" ;"
                                                "value = \"0.0\" ;"
                                                "fixed_width = true;"
                                                "width = 15;"
                                        "}"
                                "}"
                                "spacer;"
                        "}"
                        ":button"
                        "{"
                                "key = \"PICK\";"
                                "label = \"获取基点\";"
                        "}"
                "}"
                "spacer;"
                "ok_cancel_help;"
                ":text"
                "{"
                        "key = \"INFO\" ;"
                        "label = \"All Copyright Reserved. Highflybird\" ;"
                        "alignment = centered;"
                "}"
        "}"
  )
)