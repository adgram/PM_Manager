;; PM_Entity.lsp - 实体/图元操作函数
;; 职责：实体面积计算、属性读取等
;; 依赖：PM_Core.lsp

(setq *PM-Entity-Loaded* T)

;; 计算圆面积
(defun PM:CircleArea (radius)
  (* pi radius radius)
)

;; 获取填充图案面积
(defun PM:GetHatchArea (hatchEntity / area)
  (if (setq area (cdr (assoc 41 (entget hatchEntity))))
    (abs area)
    0.0
  )
)

;; 获取对象的面积（支持多段线、圆、椭圆、样条曲线、面域）
(defun PM:GetObjectArea (objectEntity / area)
  (if (vl-catch-all-error-p
        (setq area
              (vl-catch-all-apply
                'vlax-curve-getarea
                (list objectEntity))))
    (progn
      (command "._area" "_o" objectEntity)
      (getvar "area")
    )
    area
  )
)

;; 获取曲线对象的长度
(defun PM:GetCurveLength (objectEntity / length end-param)
  (if (or (null objectEntity)
          (vl-catch-all-error-p
            (setq end-param
                  (vl-catch-all-apply 'vlax-curve-getendparam (list objectEntity))))
          (vl-catch-all-error-p
            (setq length
                  (vl-catch-all-apply 'vlax-curve-getdistatparam
                                      (list objectEntity end-param)))))
    nil
    (abs length)
  )
)

;; 提取 LWPolyline 顶点数据列表 - Lee Mac
(defun PM:GetLWVertices (entData)
  (if (setq entData (member (assoc 10 entData) entData))
    (cons
      (list
        (assoc 10 entData)
        (assoc 40 entData)
        (assoc 41 entData)
        (assoc 42 entData)
      )
      (PM:GetLWVertices (cdr entData))
    )
  )
)

;; Z 坐标归零及拍平
(defun PM:FlattenEntity (entity / entData updated item i)
  (setq entData (entget entity))
  (setq updated entData)

  ;; 处理所有点组码 10-18，Z 轴归零
  (setq i 10)
  (while (<= i 18)
    (if (setq item (assoc i updated))
      (setq updated (subst (cons i (list (cadr item) (caddr item) 0.0)) item updated))
    )
    (setq i (1+ i))
  )

  ;; 厚度归零
  (if (setq item (assoc 39 updated))
    (setq updated (subst (cons 39 0.0) item updated))
  )

  ;; 拉伸方向归正
  (if (setq item (assoc 210 updated))
    (setq updated (subst '(210 0.0 0.0 1.0) item updated))
  )

  (entmod updated)
)

;; 读取 DXF 组码值
;; code: 组码号, entity: 图元名或 DXF 关联表
;; 返回: 组码值或 nil
(defun PM:GetDXF (code entity / data)
  (setq data (if (= (type entity) 'ENAME) (entget entity) entity))
  (cdr (assoc code data))
)

;; 写入 DXF 组码值
;; code: 组码号, value: 新值, entity: 图元名或 DXF 关联表
;; 返回: 更新后的 DXF 表（entity 为图元名时自动 entmod）
(defun PM:PutDXF (code value entity / data result)
  (setq data (if (= (type entity) 'ENAME) (entget entity) entity))
  (setq result (subst (cons code value) (assoc code data) data))
  (if (= (type entity) 'ENAME)
    (entmod result)
    result
  )
)
