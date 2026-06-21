# RedClass · 红课复习

本地化大学课程复习工具 — Flutter 跨端 App（Android / iOS / Windows / macOS / Linux）。

## 功能

- **题库导入**：PDF / DOCX 文字题一键解析为结构化题目（单选 / 多选 / 判断 / 简答）
- **刷题模式**：题目导航、进度条、错题重做、收藏、键盘快捷键
- **错题本**：自动记录错题，支持专项重做
- **统计**：正确率、模式分布等聚合视图
- **LLM 辅助（可选）**：接入本地 GGUF 模型做题干规范化（默认 stub，无需模型）
- **暗色模式**：完整支持 Material 3 暗色主题
- **本地优先**：所有数据存 SQLite（drift），无需后端

## 技术栈

- **Flutter** 3.35+ / **Dart** 3.12+
- **状态管理**：Riverpod 3
- **路由**：go_router 17
- **数据库**：drift 2（SQLite）
- **PDF 解析**：pdfrx（PDFium）
- **DOCX 解析**：自定义 zip + XML
- **LLM**（可选）：llama.cpp FFI / HTTP OpenAI 兼容
- **字体**：Noto Sans SC（google_fonts）

## 项目结构

```
lib/
├── core/              # 主题、路径
├── data/              # 数据库、LLM 客户端、仓储
├── features/          # 按 feature 切分
│   ├── import/        #   PDF/DOCX 导入 + 启发式解析
│   ├── quiz/          #   刷题、答题、错题
│   ├── bank_detail/   #   题库详情
│   ├── bookmarks/     #   收藏
│   ├── stats/         #   统计
│   ├── home/          #   首页
│   ├── models/        #   本地 LLM 模型管理
│   └── export/        #   导出
└── routing/           # 路由配置
```

## 开发

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 生成 .g.dart
flutter run
```

## 测试

```bash
flutter test
dart run tools/parse_real_bank.dart   # 真实题库端到端解析验证
```

## 数据隐私

- 题目数据全部存储在本地 SQLite
- LLM 调用（若启用）走本地模型或自托管 HTTP 端点
- `doc/example/` 包含真实试卷，**已通过 .gitignore 排除**
- 不收集任何遥测数据

## 许可证

私有项目。
