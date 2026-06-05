# Tasks
- [x] Task 1: 确认后端接口与字段映射
  - [x] 确认“总成待离段车号列表”接口路径、分页/筛选参数、返回字段（当前实现：GET /dispatch/trainDepartureConfirm/pendingList）
  - [x] 确认“离段确认保存”接口路径、请求体字段、成功/失败返回结构（当前实现：POST /dispatch/trainDepartureConfirm/save）

- [x] Task 2: 接口层补齐（ProductApi）
  - [x] 新增“总成待离段车号列表”查询方法（返回 List<Map>）
  - [x] 新增“离段确认保存”方法（POST，返回 Map）
  - [x] 复用 `/file/upload` 多文件上传与 `attachment` JSON 字符串拼装（如需调整字段名按后端为准）

- [x] Task 3: 新增机车离段确认页面
  - [x] 页面展示：车型、车号（从待离段列表选择后带出）
  - [x] 上传组件：支持多图选择/拍摄、预览、删除
  - [x] 提交：提交时显示 Loading；成功弹窗确认后返回；失败展示后端 msg/message

- [x] Task 4: 增加入口与权限控制
  - [x] 首页增加“离段确认”入口（NormalMainPage）
  - [x] 仅“总成车间接车组”可见/可进入（按 dept/roleKey 规则实现，可配置）
  - [x] main_page 路由表注册新路由

- [x] Task 5: 验证
  - [x] 真机/模拟器手工验证：无权限不可见；有权限可进入
  - [x] 验证：选择车号→上传多图→提交成功弹窗并退出
  - [x] 验证：弱网/超时/重复提交等失败场景有明确提示

# Task Dependencies
- Task 2/3/4 依赖 Task 1 的接口确认
