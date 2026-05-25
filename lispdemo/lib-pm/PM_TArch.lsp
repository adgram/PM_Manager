;; PM_TArch.lsp - 天正工具集成
;; 职责：天正环境检测、读取天正比例
;; 依赖：无

(setq *PM-TArch-Loaded* T)

;; 检测天正是否已加载（检查 IRecord 命名词典是否存在）
(defun PM:TArchLoaded nil
  (dictsearch (namedobjdict) "IRecord")
)

;; 获取天正当前出图比例
;; 返回: 比例分母(如 100 表示 1:100)，未加载天正或失败返回 nil
(defun PM:GetTArchScale (/ scl)
  (setq scl
    (vl-catch-all-apply
      '(lambda ()
        (setvar "cmdecho" 1)
        (command "TChScale")
        (command nil)
        (command "_.COPYHIST")
        (PM:ReadScaleFromClip)
      )
    )
  )
  (if (vl-catch-all-error-p scl) nil scl)
)

;; 从剪贴板读取比例文本，返回比例分母
(defun PM:ReadScaleFromClip (/ html data)
  (setq html (vlax-create-object "htmlfile"))
  (if html
    (progn
      (setq data (vl-catch-all-apply
                   '(lambda ()
                      (vlax-invoke
                        (vlax-get (vlax-get html 'ParentWindow) 'ClipboardData)
                        'GetData "Text"
                      )
                    )
                  )
      )
      (vlax-release-object html)
      (if (and (not (vl-catch-all-error-p data)) data)
        (PM:ParseScale data)
      )
    )
  )
)

;; 从文本中解析 "1:<NNN>" 提取比例分母
(defun PM:ParseScale (data / pos lastpos)
  (setq pos 0)
  (while (setq pos (vl-string-search "1:<" data pos))
    (setq lastpos pos pos (1+ pos))
  )
  (if lastpos
    (atoi (substr data (+ lastpos 4)))
  )
)
