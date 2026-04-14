---
name: "flutter-ui-builder"
description: "Generates Flutter code adhering to project's UI, API, and Media guidelines. MUST be invoked AUTOMATICALLY when user asks to create/modify ANY page, widget, API, or UI component."
---

# Flutter Builder (项目专属开发生成器)

这个技能用于为当前 Flutter 移动端项目（铁路/机车检修相关业务）快速生成符合项目全面规范的代码。**当用户要求编写或修改任何界面、API或业务逻辑时，必须自动遵循以下所有规范！**

## 🎨 核心 UI 设计规范 (UI Design Guidelines)

1. **页面骨架 (Page Structure)**:
   - 默认使用 `Scaffold`。
   - `AppBar` 的背景色通常为 `Colors.white`，且 `elevation` 设为 `1`。
2. **列表与卡片 (Lists & Cards)**:
   - 所有的业务数据列表应尽量支持下拉刷新，包裹在 `RefreshIndicator` 中。
   - 列表项使用 `ListView.separated` 或 `ListView.builder`。
   - 列表数据展示通常使用 `Card`，留有合适的间距（如 `padding: const EdgeInsets.all(12.0)`）。
   - 卡片通常无需过重的阴影（`elevation: 0`），可以增加极淡的边框（如 `BorderSide(color: Colors.grey.withOpacity(0.3), width: 1)`）。
3. **状态展示 (Status Tags)**:
   - 状态（如：未开工、作业中、已完成）需使用圆角矩形包裹。
   - 字体和边框颜色根据状态匹配（例如：已完成 -> `Colors.green`，作业中 -> `Colors.orange`，未开工 -> `Colors.grey`），背景色可以使用对应颜色的 `withOpacity(0.1)`。
4. **文本展示与防止溢出 (Text & Layout)**:
   - 长文本（如车号、描述）需包裹在 `Expanded` 或 `Flexible` 中，并加上 `maxLines: 1` 和 `overflow: TextOverflow.ellipsis`。
   - **车号展示**：如果涉及机车端部信息（A节/B节），统一调用或预留调用 `formatTrainNumWithEnds(trainNum, ends)` 的方法。
   - 多个字段左右对齐时，使用 `Row` 配合 `Expanded` 或者 `MainAxisAlignment.spaceBetween`。
   - 水平罗列不确定个数的组件时，必须使用 `SingleChildScrollView(scrollDirection: Axis.horizontal, ...)` 或 `Wrap` 防止溢出。
5. **交互反馈 (Interaction)**:
   - 按钮点击、卡片点击统一使用 `InkWell` 或 `GestureDetector`。
   - 全局的 Toast 或 Loading 提示统一使用 `SmartDialog`（如 `SmartDialog.showToast('...')` 或 `SmartDialog.showLoading()`）。

## 🔌 API 请求与模型交互规范 (Dio API & Model Integrator)

1. **请求封装**:
   - 网络请求统一在特定的 Api 类（如 `ProductApi`）中进行。
   - 必须使用项目现有的 `AppApi.dio.post` 或 `AppApi.dio.get` 发起请求。
   - GET 接口接收数组时，需将其转为逗号分隔字符串（如 `list.join(',')`）。
2. **异常捕获与日志**:
   - 每个 API 方法必须包裹在 `try-catch` 块中。
   - 发生异常时必须调用 `_handleException(e)`。
   - 成功请求后建议使用 `logger.i(r.data["data"])` 记录日志。
3. **安全的数据提取**:
   - 字典/Map 字段提取时需做好空值保护：如 `(data['key'] ?? '').toString()`，切勿直接强转。

## 📸 媒体文件处理与上传 (Camera & Upload Helper)

1. **图片选择与拍照**:
   - 拍照应调用现有的连拍页面组件（如 `_BurstCameraPage`）并获取 `List<XFile>`。
   - 预览图片调用 `_SlipImagesReviewPage` 或同级别预览组件进行二次确认。
2. **批量处理逻辑**:
   - 上传操作必须在 `SmartDialog.showLoading()` 的保护下进行，并考虑失败和成功的 Toast。
   - 针对批量计划上传相同图片的场景，必须在外部循环每个 plan 计划进行独立的 API 提交，上传完后在 UI 层进行统一的 `mounted` 与 `setState` 刷新。

## ⚙️ 代码结构与生命周期规范 (Code Structure)

1. **组件分类**:
   - 包含网络请求或复杂交互的组件，优先使用 `StatefulWidget`。纯展示则使用 `StatelessWidget`。
2. **生命周期保护**:
   - **绝对红线**：在执行耗时异步操作后（如 `await`）调用 `setState` 时，**务必先检查 `if (mounted)`**，防止报 `setState() called after dispose()` 的内存泄漏错误。

## 💡 模型生成要求 (AI Generation Rules)

- **自动触发**: 当用户要求编写新的 Flutter 页面、UI 组件或 API 时，AI 模型必须**自动遵循**本文件中的所有规定，无需用户显式提醒。
- **输出格式**: 生成的代码应完整、可运行、排版整洁。在提供代码之后，请用一句简短的话说明：“已根据项目规范（如防溢出、mounted检查、API标准等）生成代码。”
