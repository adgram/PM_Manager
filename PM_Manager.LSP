(vl-load-com)

;; PM_Manager.lsp - AutoCAD 插件管理器 v1.0.0

(setq *PM:VER* "1.0.0")
(setq *PM:APPDIR* (strcat (getvar "roamablerootprefix") "\\ACAD-PM"))
(setq *PM:CFG* (strcat *PM:APPDIR* "\\acad-pm.cfg"))
(setq *PM:DCL* (strcat (getenv "TEMP") "\\acad-pm.dcl"))

(setq *PM:LOADED* nil)
(setq *PM:AUTOLOAD* nil)
(setq *PM:DIRS* nil)
(setq *PM:ALL-DIRS* nil)
(setq *PM:FILES* nil)
(setq *PM:UI-ITEMS* nil)

(defun *PM:TRIM (s)
  (vl-string-trim " \t\r\n" s)
)

(defun *PM:BROWSE-FOLDER (prompt-str / sh wsh folder path)
  (setq path nil)
  (if (member 'vl-browser-for-folder (atoms-family 1))
    (setq path (vl-browser-for-folder prompt-str "" 0))
    (progn
      (setq sh (vlax-create-object "Shell.Application"))
      (setq folder (vlax-invoke-method sh 'BrowseForFolder 0 prompt-str 0))
      (if folder
        (progn
          (setq wsh (vlax-get-property folder 'Self))
          (setq path (vlax-get-property wsh 'Path))
          (vlax-release-object wsh)
          (vlax-release-object folder)
        )
      )
      (vlax-release-object sh)
    )
  )
  (if (and path (/= path ""))
    (vl-filename-directory (strcat (*PM:TRIM path) "\\x"))
    nil
  )
)

(defun *PM:GET-SUBDIRS (dir / sub sub-path result)
  (setq result (list dir))
  (foreach d (vl-directory-files dir)
    (if (and (/= d ".") (/= d "..") (not (wcmatch d "lib-*")))
      (progn
        (setq sub-path (strcat dir "\\" d))
        (if (vl-file-directory-p sub-path)
          (setq result (append result (*PM:GET-SUBDIRS sub-path)))
        )
      )
    )
  )
  result
)

;; 配置文件

(defun *PM:READ-CFG ( / f line mode cfg-dirs cfg-auto)
  (setq cfg-dirs nil cfg-auto nil mode nil)
  (if (not (vl-file-directory-p *PM:APPDIR*)) (vl-mkdir *PM:APPDIR*))
  (if (setq f (open *PM:CFG* "r"))
    (progn
      (while (setq line (read-line f))
        (setq line (*PM:TRIM line))
        (cond
          ((= (strcase line) "[PATHS]") (setq mode 'paths))
          ((= (strcase line) "[AUTO]")  (setq mode 'auto))
          ((wcmatch line ";*")        ) 
          ((= mode 'paths)
            (if (/= "" line) (setq cfg-dirs (cons line cfg-dirs)))
          )
          ((= mode 'auto)
            (if (/= "" line) (setq cfg-auto (cons line cfg-auto)))
          )
        )
      )
      (close f)
      (if cfg-dirs (setq *PM:DIRS* (reverse cfg-dirs)))
      (if cfg-auto (setq *PM:AUTOLOAD* (reverse cfg-auto)))
    )
  )
  (if (null *PM:DIRS*)
    (setq *PM:DIRS* (list (strcat (getenv "USERPROFILE") "\\lisp")))
  )
)

(defun *PM:WRITE-CFG ( / f tm)
  (if (not (vl-file-directory-p *PM:APPDIR*)) (vl-mkdir *PM:APPDIR*))
  (if *PM:DIRS*
    (progn
      (setq f (open *PM:CFG* "w"))
      (setq tm (menucmd "m=$(edtime,$(getvar,date),YYYY-MO-DD HH:MM:SS)"))
      (write-line "; ACAD Plugin Manager Config v1.0.0" f)
      (write-line (strcat "; Auto-Saved: " tm) f)
      (write-line "" f)
      (write-line "[Paths]" f)
      (foreach d *PM:DIRS* (write-line d f))
      (write-line "" f)
      (write-line "[Auto]" f)
      (foreach p *PM:AUTOLOAD* (write-line p f))
      (close f)
    )
  )
  (princ)
)

;; 扫描

(defun *PM:SCAN ( / root all-subs dir files-in-dir f)
  (setq *PM:FILES* nil *PM:ALL-DIRS* nil)
  (foreach root *PM:DIRS*
    (if (vl-file-directory-p root)
      (progn
        (setq all-subs (*PM:GET-SUBDIRS root))
        (foreach dir all-subs
          (setq files-in-dir nil)
          (foreach f (vl-directory-files dir)
            (if (and (wcmatch (strcase f) "*.LSP,*.FAS,*.VLX")
                     (not (vl-file-directory-p (strcat dir "\\" f))))
              (setq files-in-dir (cons f files-in-dir))
            )
          )
          (if files-in-dir
            (progn
              (if (null (member dir *PM:ALL-DIRS*))
                (setq *PM:ALL-DIRS* (append *PM:ALL-DIRS* (list dir)))
              )
              (foreach f files-in-dir
                (if (null (assoc f *PM:FILES*))
                  (setq *PM:FILES* (cons (cons f dir) *PM:FILES*))
                )
              )
            )
          )
        )
      )
    )
  )
  (setq *PM:FILES* (reverse *PM:FILES*))
  *PM:FILES*
)

;; 加载

(defun *PM:FIND-FILE-PATH (name / pair)
  (setq pair (assoc name *PM:FILES*))
  (if pair (strcat (cdr pair) "\\" name) nil)
)

(defun *PM:LOAD (name / path result)
  (setq path (*PM:FIND-FILE-PATH name))
  (if path
    (progn
      (setq result (load path "FAILED"))
      (if (/= result "FAILED")
        (progn
          (if (null (member name *PM:LOADED*)) (setq *PM:LOADED* (cons name *PM:LOADED*)))
          (princ (strcat "\n[PM] 成功加载: " name))
        )
        (princ (strcat "\n[PM] 加载失败: " name))
      )
    )
  )
  (princ)
)

(defun *PM:LOAD-ALL-AUTO ( / count)
  (*PM:READ-CFG)
  (*PM:SCAN)
  (setq count 0)
  (foreach p *PM:AUTOLOAD*
    (*PM:LOAD p)
    (setq count (1+ count))
  )
  (if (> count 0)
    (princ (strcat "\n[PM] 自动加载完成，共拉取嵌套子夹插件 " (itoa count) " 个。"))
  )
  (princ)
)

;; DCL 界面

(defun *PM:GEN-DCL ( / f)
  (setq f (open *PM:DCL* "w"))
  (write-line "pm_dialog : dialog {" f)
  (write-line "  label = \"AutoCAD 插件管理器  v1.0.0\";" f)
  
  (write-line "  : list_box {" f)
  (write-line "    key = \"lst\";" f)
  (write-line "    label = \"插件列表:\";" f)
  (write-line "    height = 19;" f)
  (write-line "    width = 75;" f)
  (write-line "    multiple_select = true;" f)
  (write-line "    fixed_width = t;" f)
  (write-line "    fixed_height = t;" f)
  (write-line "  }" f)
  
  (write-line "  : boxed_column { label = \"插件操作\";" f)
  (write-line "    : row {" f)
  (write-line "      : button { key = \"load\"; label = \"加载选中\"; width = 12; fixed_width = t; }" f)
  (write-line "      : button { key = \"unload\"; label = \"卸载选中\"; width = 12; fixed_width = t; }" f)
  (write-line "    }" f)
  (write-line "  }" f)
  
  (write-line "  : boxed_column { label = \"批量设置与同步\";" f)
  (write-line "    : row {" f)
  (write-line "      : button { key = \"allauto\"; label = \"全部自动\"; width = 12; fixed_width = t; }" f)
  (write-line "      : button { key = \"toggle\"; label = \"切换自动/手动\"; width = 16; fixed_width = t; }" f)
  (write-line "    }" f)
  (write-line "  }" f)
  
  (write-line "  : boxed_column { label = \"根路径管理 (弹窗选择)\";" f)
  (write-line "    : row {" f)
  (write-line "      : button { key = \"addpath\"; label = \"+ 添加路径\"; width = 12; fixed_width = t; }" f)
  (write-line "      : button { key = \"delpath\"; label = \"- 删除路径\"; width = 12; fixed_width = t; }" f)
  (write-line "    }" f)
  (write-line "    : list_box {" f)
  (write-line "      key = \"pathlst\";" f)
  (write-line "      label = \"监视的根目录列表 (自动穿透所有深层子文件夹):\";" f)
  (write-line "      height = 4;" f)
  (write-line "      width = 75;" f)
  (write-line "      fixed_width = t;" f)
  (write-line "      fixed_height = t;" f)
  (write-line "    }" f)
  (write-line "    : button { key = \"hide_cancel\"; is_cancel = true; is_default = true; label = \"\"; width = 0; height = 0; fixed_width = t; fixed_height = t; }" f)
  (write-line "  }" f)
  
  (write-line "  : text {" f)
  (write-line "    key = \"info\";" f)
  (write-line "    label = \"数据已同步\";" f)
  (write-line "    width = 75;" f)
  (write-line "    alignment = centered;" f)
  (write-line "  }" f)
  (write-line "}" f)
  (close f)
  *PM:DCL*
)

;; UI 数据

(defun *PM:FILL-LIST ( / dir filename pair)
  (setq *PM:UI-ITEMS* nil)
  (start_list "lst")
  (foreach dir *PM:ALL-DIRS*
    (add_list (strcat "【文件夹】" dir))
    (setq *PM:UI-ITEMS* (append *PM:UI-ITEMS* (list (cons 'DIR dir))))
    (foreach pair *PM:FILES*
      (if (= (cdr pair) dir)
        (progn
          (setq filename (car pair))
          (setq *PM:UI-ITEMS* (append *PM:UI-ITEMS* (list (cons 'FILE filename))))
          (add_list (strcat "    " 
                            (if (member filename *PM:LOADED*) "[已载入]" "[未载入]")
                            (if (member filename *PM:AUTOLOAD*) "[自动]" "[手动]")
                            "  " filename))
        )
      )
    )
  )
  (end_list)
)

(defun *PM:FILL-PATHS ()
  (start_list "pathlst")
  (foreach d *PM:DIRS* (add_list d))
  (end_list)
)

(defun *PM:UPDATE-INFO ()
  (set_tile "info"
    (strcat "根路径: " (itoa (length *PM:DIRS*))
            " | 子目录: " (itoa (length *PM:ALL-DIRS*))
            " | 发现插件: " (itoa (length *PM:FILES*))
            " [配置实时保存]"))
)

(defun *PM:GET-SEL (key / str indices i)
  (setq str (get_tile key))
  (setq indices nil)
  (if (and str (/= str ""))
    (progn
      (foreach i (read (strcat "(" str ")"))
        (setq indices (cons i indices))
      )
      (setq indices (reverse indices))
    )
  )
  indices
)

;; 主循环

(defun *PM:OPEN ( / dcl_id result loop active-sel active-psel item name path-str)
  (*PM:READ-CFG)
  (*PM:SCAN)
  (*PM:GEN-DCL)

  (setq dcl_id (load_dialog *PM:DCL*))
  (if (< dcl_id 0) (exit))

  (setq loop t)
  (setq active-sel nil active-psel nil)

  (while loop
    (if (not (new_dialog "pm_dialog" dcl_id))
      (setq loop nil)
      (progn
        (*PM:FILL-LIST)
        (*PM:FILL-PATHS)
        (*PM:UPDATE-INFO)

        (if active-sel
          (set_tile "lst" (vl-string-trim "()" (vl-prin1-to-string active-sel)))
        )
        (if active-psel
          (set_tile "pathlst" (vl-string-trim "()" (vl-prin1-to-string active-psel)))
        )

        (action_tile "lst" "(setq active-sel (*PM:GET-SEL \"lst\"))")

        (action_tile "load" "(setq active-sel (*PM:GET-SEL \"lst\")) (done_dialog 10)")
        (action_tile "unload" "(setq active-sel (*PM:GET-SEL \"lst\")) (done_dialog 20)")
        (action_tile "toggle" "(setq active-sel (*PM:GET-SEL \"lst\")) (done_dialog 30)")
        (action_tile "allauto" "(done_dialog 40)")
        (action_tile "addpath" "(setq active-sel (*PM:GET-SEL \"lst\") active-psel (*PM:GET-SEL \"pathlst\")) (done_dialog 70)")
        (action_tile "delpath" "(setq active-sel (*PM:GET-SEL \"lst\") active-psel (*PM:GET-SEL \"pathlst\")) (done_dialog 80)")

        (action_tile "hide_cancel" "(done_dialog 0)")

        (setq result (start_dialog))
        
        (if (not (member result '(10 20 30 70 80)))
          (progn
            (setq active-sel (*PM:GET-SEL "lst"))
            (setq active-psel (*PM:GET-SEL "pathlst"))
          )
        )

        (cond
          ((= result 0) 
            (*PM:WRITE-CFG) 
            (setq loop nil)
          )
          
          ((= result 10) 
            (if active-sel
              (progn
                (foreach i active-sel
                  (setq item (nth i *PM:UI-ITEMS*))
                  (if (= (car item) 'FILE)
                    (*PM:LOAD (cdr item))
                    (foreach pair *PM:FILES*
                      (if (= (cdr pair) (cdr item)) (*PM:LOAD (car pair)))
                    )
                  )
                )
                (*PM:WRITE-CFG)
              )
              (alert "请先选中需要载入的插件行！")
            )
          )
          
          ((= result 20) 
            (if active-sel
              (progn
                (foreach i active-sel
                  (setq item (nth i *PM:UI-ITEMS*))
                  (if (= (car item) 'FILE)
                    (setq *PM:LOADED* (vl-remove (cdr item) *PM:LOADED*))
                    (foreach pair *PM:FILES*
                      (if (= (cdr pair) (cdr item))
                        (setq *PM:LOADED* (vl-remove (car pair) *PM:LOADED*))
                      )
                    )
                  )
                )
                (*PM:WRITE-CFG)
              )
            )
          )
          
          ((= result 30) 
            (if active-sel
              (progn
                (foreach i active-sel
                  (setq item (nth i *PM:UI-ITEMS*))
                  (if (= (car item) 'FILE)
                    (progn
                      (setq name (cdr item))
                      (if (member name *PM:AUTOLOAD*)
                        (setq *PM:AUTOLOAD* (vl-remove name *PM:AUTOLOAD*))
                        (setq *PM:AUTOLOAD* (cons name *PM:AUTOLOAD*))
                      )
                    )
                    (foreach pair *PM:FILES*
                      (if (= (cdr pair) (cdr item))
                        (progn
                          (setq name (car pair))
                          (if (member name *PM:AUTOLOAD*)
                            (setq *PM:AUTOLOAD* (vl-remove name *PM:AUTOLOAD*))
                            (setq *PM:AUTOLOAD* (cons name *PM:AUTOLOAD*))
                          )
                        )
                      )
                    )
                  )
                )
                (*PM:WRITE-CFG) 
              )
            )
          )
          
          ((= result 40) 
            (foreach pair *PM:FILES*
              (if (null (member (car pair) *PM:AUTOLOAD*))
                (setq *PM:AUTOLOAD* (cons (car pair) *PM:AUTOLOAD*))
              )
            )
            (*PM:WRITE-CFG)
          )
          
          ((= result 70) 
            (setq path-str (*PM:BROWSE-FOLDER "添加主监视文件夹（将全自动穿透扫描其下所有嵌套子夹）:"))
            (if path-str
              (progn
                (if (null (member path-str *PM:DIRS*))
                  (setq *PM:DIRS* (append *PM:DIRS* (list path-str)))
                )
                (*PM:WRITE-CFG) 
                (*PM:SCAN)      
              )
            )
          )
          ((= result 80) 
            (if active-psel
              (progn
                (foreach i (reverse active-psel)
                  (if (< i (length *PM:DIRS*))
                    (setq *PM:DIRS* (vl-remove (nth i *PM:DIRS*) *PM:DIRS*))
                  )
                )
                (if (null *PM:DIRS*)
                  (setq *PM:DIRS* (list (strcat (getenv "USERPROFILE") "\\lisp")))
                )
                (setq active-psel nil) 
                (*PM:WRITE-CFG) 
                (*PM:SCAN)      
              )
            )
          )
        )
      )
    )
  )

  (unload_dialog dcl_id)
  (princ)
)

;; 启动

(defun C:PM () (*PM:OPEN))
(defun C:PM_AUTOLOAD () (*PM:LOAD-ALL-AUTO))

(if (null *PM:LOADED-ONCE*)
  (progn
    (setq *PM:LOADED-ONCE* t)
    (*PM:LOAD-ALL-AUTO)
  )
)

(princ (strcat "\n[PM] 插件管理器 v" *PM:VER* "。输入 PM 打开。"))
(princ)