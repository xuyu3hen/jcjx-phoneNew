# 机车离段确认 Spec

## Why
总成接车组需要对待离段机车进行离段拍照确认并留痕，减少漏确认与重复沟通。

## What Changes
- 新增“机车离段确认”功能模块（页面+路由+入口）。
- 从“总成待离段车号列表”选择车号后自动带出车型车号信息。
- 支持离段拍照上传（多张），保存时将上传结果拼装为 JSON 字符串写入 `attachment` 字段。
- 提交时间使用提交时刻（无需手工选择日期时间）。
- 增加入口可见权限：仅“总成车间接车组”可见/可操作。

## Impact
- Affected specs: 页面入口权限控制｜待离段列表选择｜多图上传｜提交与成功退出
- Affected code: 首页功能入口（NormalMainPage）｜离段确认页面（新增）｜ProductApi（新增接口方法）

## ADDED Requirements
### Requirement: 机车离段确认模块
系统 SHALL 提供“机车离段确认”模块，供总成车间接车组对机车离段进行拍照确认并提交。

#### Scenario: 进入页面（有权限）
- **WHEN** 用户属于“总成车间接车组”并点击首页入口
- **THEN** 系统展示“机车离段确认”页面
- **AND** 系统加载“总成待离段车号列表”用于选择

#### Scenario: 进入页面（无权限）
- **WHEN** 用户不属于“总成车间接车组”
- **THEN** 首页不展示入口（或进入时提示无权限并返回）

### Requirement: 待离段车号选择
系统 SHALL 从后端“总成待离段车号列表”接口加载可选列表。

#### Scenario: 选择车号
- **WHEN** 用户从列表选择车号
- **THEN** 页面自动展示车型车号（来自列表项的字段映射）
- **AND** 页面进入可拍照与提交状态

### Requirement: 离段拍照上传与 attachment 拼装
系统 SHALL 支持上传多张离段确认照片，并在保存时将上传结果拼装为字符串写入 `attachment`。

#### Scenario: 多图上传
- **WHEN** 用户选择/拍摄多张照片（数量不做业务限制，受组件/后端限制影响）
- **THEN** 系统使用 `/file/upload` 支持多文件上传
- **AND** 对每个上传结果提取 `{name,url,fileId}` 并组成数组
- **AND** 将数组以 JSON 字符串形式写入保存接口的 `attachment` 字段

### Requirement: 提交与时间
系统 SHALL 在用户点击提交时写入提交时间（提交时刻），无需手工选择日期时间。

#### Scenario: 提交成功
- **WHEN** 用户点击提交且后端返回成功
- **THEN** 弹窗提示“离段确认成功”
- **AND** 用户点击确定后返回上一页

#### Scenario: 提交失败
- **WHEN** 后端返回业务失败或网络异常/超时
- **THEN** 系统提示失败原因（优先展示后端 `msg/message`）
- **AND** 不退出页面，允许用户重试

## MODIFIED Requirements
无

## REMOVED Requirements
无

## Notes / Open Items
- 需与后端确认“总成待离段车号列表”接口路径与字段：建议至少返回 `typeName/typeCode/trainNum/trainNumCode/trainEntryCode(或 code)`。
- 需与后端确认“离段确认保存”接口路径与入参字段（至少：车型车号、trainEntryCode、attachment、提交人信息；提交时间由后端落库或前端传 `submitTime`）。
