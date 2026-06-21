# RedClass · 红课复习

本地化大学课程复习工具 — Flutter Windows 桌面 App。

> **平台支持**：目前**仅 Windows** 平台经过实际测试与可用验证。
> Android / iOS / macOS / Linux 仅完成基础编译通过，未做端到端测试。

## 已实现功能

- **题库导入**
  - PDF 文字题提取（pdfrx / PDFium）
  - DOCX 文字题提取
  - 启发式解析器自动识别单选 / 多选 / 判断 / 简答
  - 解析结果可手动调整后入库
- **刷题**
  - 题目导航、进度条、上一题 / 下一题
  - 多选题多选与取消选择
  - 键盘快捷键（A-H 选项、Space 确认、左右切题）
  - 错题标记
- **错题本**：自动收录错题，支持专项重做
- **收藏**：题目收藏夹
- **统计**：正确率、按题型 / 模式分布
- **题库详情**：题库元信息、题目列表
- **导出**：题库导出为 JSON
- **主题**：Material 3 浅色 / 暗色完整支持
- **本地优先**：所有数据存 SQLite（drift），无后端依赖

## 项目结构

```
lib/
├── core/              # 主题、路径
├── data/              # 数据库、LLM 客户端、仓储
├── features/
│   ├── home/          #   首页
│   ├── import/        #   PDF/DOCX 导入 + 启发式解析
│   ├── quiz/          #   刷题、答题、错题
│   ├── bank_detail/   #   题库详情
│   ├── bookmarks/     #   收藏
│   ├── stats/         #   统计
│   ├── models/        #   本地 LLM 模型管理（实验性，未测试）
│   └── export/        #   导出
└── routing/           # 路由配置
```

## 开发

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 生成 .g.dart
flutter run -d windows
```

## 测试

```bash
flutter test
dart run tools/parse_real_bank.dart   # 真实题库端到端解析验证
```

## 数据隐私

- 题目数据、错题、收藏等全部存储在本地 SQLite（用户目录下）
- `doc/example/` 包含真实试卷，**已通过 .gitignore 排除，不会被推送到仓库**
- 不收集任何遥测或使用数据

## 许可证

私有项目，保留所有权利。
