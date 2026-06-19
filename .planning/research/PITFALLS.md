# Pitfalls Research

**Domain:** Flutter desktop + Android local app with on-device LLM parsing of exam question banks (`.docx`/`.pdf`)
**Researched:** 2025-01
**Confidence:** HIGH (specific to RedClass tech stack and three-mode ledger design; reflects known pain points in on-device LLM apps and Flutter cross-platform file handling)

## Critical Pitfalls

### Pitfall 1: LLM输出JSON格式漂移导致静默解析失败

**What goes wrong:**
小模型（Qwen2.5-1.5B / Phi-3-mini / Gemma 2 2B）对同一份题目文本多次推理，可能返回字段名时而为`"answer"`时而为`"Answer"`、选项数组有时是`["A. xxx", "B. yyy"]`有时是`{"A":"xxx","B":"yyy"}`、多选答案可能给`"AB"`、`"A,B"`、`"A和B"`、`["A","B"]`等多种形式。更糟的是模型偶尔会"在JSON外加一句解释"或在某个字段里塞入整段题干。导入100道题看似成功，实际20道入库数据残缺，后续做题判分出现"答案永远是B"或"多选永远0分"。

**Why it happens:**
- 1-3B参数指令遵循能力有限，对严格schema的输出约束不可靠
- prompt中若要求"先输出JSON再解释"，模型倾向于加尾巴
- temperature若>0，多样性放大漂移
- 没做schema的输出约束（JSON Schema / grammar-guided decoding / function calling）

**How to avoid:**
1. **使用约束解码**：llama.cpp启用`--grammar-file`传JSON语法（`llama-cpp` Dart binding + `gbnf`），从根上禁止非法输出
2. **多层兜底解析**：先尝试`jsonDecode`严格解析 → 失败则正则提取第一个`{...}`或`[...]` → 再失败则按行/字段名启发式拆分
3. **schema校验中间件**：解析后跑一遍validator——字段缺失填空、枚举值归一化（`"AB" → ["A","B"]`）、选项数量与题型不符则标`parse_status=incomplete`而非入库
4. **temperature=0** + 固定seed解析同一段文本，多次结果应当完全一致；不一致则说明prompt需重写
5. **prompt模板末尾硬性收口**："Output ONLY the JSON. No prose. End with `}`." 并测试对不同模型的鲁棒性

**Warning signs:**
- 同题多次导入出现不同字段名
- "导入成功"提示后题目数远小于原文行数
- 多选题用户报告"明明选对了却判错"且集中在某些doc
- DB中`questions.answer_raw`字段出现`"A. 因为..."`而非`"A"`

**Phase to address:**
阶段1（题库导入与LLM解析）——必须在MVP前解决，是整个产品的核心瓶颈。P2的功能（统计、收藏）依赖`questions`表数据干净。

---

### Pitfall 2: 错题本状态机非原子导致"已答对又出现在错题抽查里"

**What goes wrong:**
三模式联动（乱序→错题本→错题复习→已掌握→从抽查移除）的关键转换全部是数据库写操作。如果"标记答对"和"从错题本移除"分两次写、或没有事务包裹、或抽查的查询条件只过滤了`status='wrong'`而忘了过滤`mastered=true`，会出现：
- 答对的题10秒后又出现在错题抽查里
- 多选题"部分对"被判错后无法再次以"错题"身份复习
- 应用闪退/中途杀进程后状态丢失，下次打开题被"答对"但仍在错题本

**Why it happens:**
- 状态机建模时把"是否掌握"和"是否在错题本"当作两个独立bool字段，没用显式状态机
- 抽查SQL用`WHERE status='wrong'`而非`WHERE in_wrong_ledger=1 AND NOT mastered`
- 写操作没放在SQLite事务里，`await db.insert`之间崩了
- 没区分"答错入错题本"和"答题记录写入"两个动作的幂等性边界

**How to avoid:**
1. **显式状态枚举**：`questions`表用`status IN ('new','answered','wrong','mastered','favorited')`，避免bool字段组合爆炸
2. **每次状态变更走单一事务**：`BEGIN; UPDATE attempts SET correct=1; UPDATE questions SET status='mastered' WHERE id=?; DELETE FROM wrong_ledger WHERE question_id=?; COMMIT;`
3. **抽查查询硬约束**：`SELECT ... FROM wrong_ledger wl JOIN questions q ON q.id=wl.question_id WHERE wl.removed_at IS NULL AND q.status != 'mastered'`
4. **多选题半对惩罚**：抽题模式下漏选/多选直接判错入错题本（业务规则已定）；但要在`attempts`表存`selected_options`原始值，方便回溯"为什么判错"
5. **幂等键**：每次答题用`(question_id, session_id, attempt_no)`做唯一约束，重复提交不产生脏数据

**Warning signs:**
- 同一题答对后再答一次，状态变成`wrong`（来回抖动）
- 应用在写入中途杀进程，重启后错题本条数与上次session不一致
- 抽查模式出现"已答对"的题（QA测试中常见）
- 多选题答ABC被判错后，数据库只记录`correct=0`没有`selected='AC'`无法复盘

**Phase to address:**
阶段3（错题本联动）——但数据库schema和事务边界必须在阶段1设计时就敲定，后期改schema代价极高。

---

### Pitfall 3: SQLite FFI在Windows与Android路径/编码差异导致"数据库不见了"

**What goes wrong:**
- Windows下`path_provider`返回`C:\Users\xxx\AppData\Roaming\RedClass\`，Android返回`/data/data/com.xxx.redclass/app_flutter/`；硬编码`/`分隔符在Windows崩
- 中文路径/题库文件名含emoji/空格在Windows的SQLite FFI `.so`加载失败（早期`sqlite3_flutter_libs`曾有UTF-8 BOM问题）
- `getApplicationDocumentsDirectory()`在Windows上等价于`%APPDATA%`，权限OK；但Android 11+ scoped storage下选文件后路径变成`content://` URI而非`/storage/...`，如果直接传给`File(path).readAsBytes()`会失败
- 多窗口/多实例启动两个Flutter进程同时写SQLite，`database is locked`

**Why it happens:**
- Dart对路径分隔符做了`/`统一处理，但SQLite native层或JVM/native binding不总是宽容
- Android scoped storage的`file_picker`返回的是URI，要先`getApplicationDocumentsDirectory()`拷一份再用`File`
- Windows desktop应用允许多开（不像Android默认单实例），多实例同写会破坏sqlite3

**How to avoid:**
1. **永远用`path`包**：`p.join(docDir.path, 'redclass.db')`而非字符串拼接
2. **file_picker拿到的路径先拷贝**：`FilePicker.platform.pickFiles()` → 用`XFile.fromData`或`File(uri.toFilePath()).copy(destPath)`，别假设可以直接打开
3. **单实例锁**：Windows用`win32` package的`CreateMutex`，启动时检测已有实例则聚焦或退出；Android本身单实例不用管
4. **WAL模式**：`PRAGMA journal_mode=WAL;` 提高并发读取容忍度，但仍需应用层mutex
5. **DB路径做健壮性测试**：首次启动写入带中文/空格/emoji的文件名，验证读写正常

**Warning signs:**
- Windows打包后第一次启动报"cannot open database file"
- Android 11+设备选完文件后闪退或提示权限错误
- 开发时直接跑没问题，打release包崩溃
- 同一时间开两个exe，第二个打开后写数据导致第一个崩

**Phase to address:**
阶段1（题库导入与数据库搭建）——基础设施层，与业务逻辑无关但全项目依赖。

---

### Pitfall 4: Android端本地LLM内存峰值超限导致OOM或应用被杀

**What goes wrong:**
Qwen2.5-1.5B-Instruct Q4_K_M量化约1.1GB模型文件，运行时峰值内存约2-2.5GB（含KV cache + native heap）。中低端Android机（4-6GB RAM）空闲时仅1-2GB可用：
- 应用进入`Application`时直接加载模型 → onCreate阶段就OOM
- 解析大题库（500题）连续推理导致内存逐步上涨，2分钟后被Low Memory Killer杀掉
- 推理线程没限速，CPU跑满电钻发热，用户切到后台回来发现进程没了

**Why it happens:**
- llama.cpp默认会预留最大上下文长度（4K tokens）的KV cache，无论实际多长
- 没有显式调用`llama_kv_cache_clear`或`llama_free`及时释放
- 解析任务在UI线程跑，主isolate阻塞，Flutter显示"无响应"
- ncnn/vLLM-mobile没用对backends（如`gpu`后端比`cpu`省内存但要确保Vulkan可用）

**How to avoid:**
1. **延迟加载 + 显式卸载**：模型仅在用户点击"开始导入"时加载，导入完成后（或超时/取消）立即`llama_model_free`
2. **上下文长度压紧**：解析prompt的`n_ctx=1024`足以，避免4096浪费
3. **batch_size=1** + 单线程推理，内存峰值可控
4. **进度粒度**：每解析10题就释放一次KV cache、或分批送入
5. **守卫UI**：用`compute()`或`Isolate.run()`跑推理，UI可以取消/显示进度/响应返回键
6. **能力探测**：首次启动跑一个"30秒加载+生成一段文字"的自检，失败则提示"本机内存不足以运行本地LLM"

**Warning signs:**
- Android启动时白屏5秒以上 → 可能正在加载模型
- 解析大文件时`adb shell dumpsys meminfo com.xxx.redclass`显示PSS超过600MB
- logcat出现`Low Memory Killer`或`onTrimMemory`触发
- 用户报告"导入中途应用消失"

**Phase to address:**
阶段1（LLM解析），尤其是Android APK构建后必须做真机压测。模拟器跑得动不代表真机能跑。

---

### Pitfall 5: 答案字段设计为字符串导致多选判分永远错

**What goes wrong:**
数据库设计时把`answer`字段定义为`TEXT`，直接存LLM返回的原始字符串（`"AB"`或`"A,B"`或`"["A","B"]"`）。判分逻辑写`if (selected == answer)`：
- 用户选AC，答案是ABC → 字面不等被判错（但实际是正确的"包含"判断）
- LLM返回`"AB"`，用户选A、B → 字面不等
- LLM返回`"A和B"`，用户选A、B → 字面不等
- 大小写/空格差异：`"A,B"` vs `"A, B"` vs `"a,b"`

**Why it happens:**
- 没把"答案"建模成"有序/无序集合"而是标量字符串
- 多选的判分规则需要先定义（"全部选对才得分"已确认，但实现时简化成字符串比对）
- 没有"canonicalization"层把LLM输出归一化为统一格式

**How to avoid:**
1. **DB层存归一化集合**：`correct_answer TEXT` 存JSON数组如`["A","B"]`，永远是排序后的小写无空格形式
2. **判分时再做规范化**：用户选择`["A","B","C"]` → 排序 → 与`correct_answer`数组等值比较
3. **写入前parse层做canonicalization**：所有"AB"/"A,B"/"A和B"/"A B"输入都先正则归一化为`["A","B"]`
4. **schema校验**：解析完成后若多选题`correct_answer.length < 2`则标`parse_status=incomplete`，让用户手动确认而非入库

**Warning signs:**
- QA用同一组多选题100%正确率，但实际用户正确率仅30%
- 改一道多选的答案后（DB里直接改）判分仍然对/错
- 解析日志显示`correct_answer="A,B"`入库但UI显示为`["A","B"]`——已经在做隐式转换，迟早出错

**Phase to方向:**
阶段1（DB schema设计）+ 阶段2（做题判分逻辑）双向夹击。schema错一次，后期迁移代价高。

---

### Pitfall 6: 题库文件被LLM切碎后题干/选项错位

**What goes wrong:**
`.docx`或`.pdf`原文形如：
```
1. 以下哪项是TCP协议的特点？
A. 面向连接
B. 无连接
C. ...
D. ...
答案：AB
```
LLM解析返回：
```json
{"stem":"以下哪项是TCP协议的特点？","options":["A. 面向连接","B. 无连接","C.","D."],"answer":"AB"}
```
或更糟：把"答案：AB"也并入了题干。把"2."开始的下一题的选项A接到本题选项末尾。

**Why it happens:**
- prompt没明确"每个题号一段"的分段规则
- 选项以字母+句点开头的格式不统一（有的用`A、`有的用`(A)`有的用`A.`，LLM匹配混乱）
- 题目之间没有空行分隔，docx段落连续
- 答案行`答案：AB`被当作题干的一部分

**How to avoid:**
1. **解析前预处理**：用正则先按`^\d+[.、]`把原文切成题块，再分块送LLM（每块独立、上下文小、漂移少）
2. **prompt显式分块指令**："Each question starts with a number followed by `.` or `、`. Options follow. Answer line begins with `答案` or `Answer`. Output one JSON per question."
3. **二次校验**：解析完成后遍历`questions`，按`order_index`排序，模拟UI展示给用户做"人工校阅一页"，让用户快速翻一遍确认错位
4. **保留原文`raw_text`**：每题存原始片段，方便定位错位后回溯重解析
5. **显式题型字段**：`type IN ('single','multi','unknown')`，未知题型不直接入库，让用户标注

**Warning signs:**
- 用户报告"第3题的选项里有第4题的题干"
- 解析后题目数量比原文行号最大值还多（说明被切碎）
- 抽题模式下出现"题干完全不知所云"的题目
- 答案行`答案：AB`出现在`stem`字段里

**Phase to address:**
阶段1（解析pipeline），必须在端到端测试集（含真实老师docx）上跑通后再进入下一阶段。

---

### Pitfall 7: 桌面端生命周期与Android不一致，复习中途状态丢失

**What goes wrong:**
- Windows桌面端：用户最小化窗口→3小时后回来，应用仍在；中间没有任何"恢复"信号
- Android端：用户做题做到一半被来电打断→返回应用→某些场景下Flutter重新`main()`入口，复习session和当前题号丢失
- Windows允许多窗口：如果用户从主窗口打开"收藏夹"独立窗口，两个窗口共享同一SQLite连接，其中一个写入后另一个视图缓存陈旧

**Why it happens:**
- 桌面端没有`onPause`/`onResume`等价物，状态完全靠应用主动保存
- Android的`onTrimMemory`、`onPause`时机不确定，应用无"自动存档"机制
- Flutter的`WidgetsBindingObserver.didChangeAppLifecycleState`在桌面端不可靠

**How to avoid:**
1. **答题状态实时落盘**：每答一题就立即写DB而非"退出时再保存"，崩溃/被杀也不丢
2. **session表**：维护`current_session(question_id, started_at, elapsed_ms)`表，应用启动时检查是否有未结束的session，提示"继续上次"
3. **窗口焦点事件订阅**：Windows用`WidgetsBindingObserver.didChangeAppMetrics`或`focus_manager`，在窗口失焦时自动存档
4. **多窗口互斥**：v1禁止开多个窗口，UI层直接disable"新窗口"入口
5. **定期checkpoint**：每答5题或30秒做一次"完整session快照"，落盘到`checkpoints`表

**Warning signs:**
- 用户报告"做完10题退出，再打开全没了"
- Android端切到后台5分钟回来，题号跳回1
- Windows窗口缩放后UI错位（不是本次主题但顺手能发现）

**Phase to address:**
阶段2（做题界面）+ 阶段3（错题联动）。从一开始就建立"实时落盘"约定，不要等出bug再改。

---

### Pitfall 8: 闭源+离线+无遥测，Bug无法复现

**What goes wrong:**
"导入失败"、"题库解析错了"这类bug，用户描述模糊（"好像不太对"），开发者本地无法复现：
- 用户用的是哪个版本的`.exe`？无法知道
- 用户导入的docx是哪个？涉及隐私不能索取
- LLM解析时实际prompt是什么？应用内日志怎么开？
- 用户机型/Android版本？LLM内存够不够？

**Why it happens:**
- 闭源、无遥测设计导致"用户遇到问题→开发者拿到信息"链路断了
- LLM输出天然随机，同样的输入下次不一定复现
- 题库文件涉及隐私，用户不愿意发

**How to avoid:**
1. **应用内"导出诊断包"功能**：打包当前DB（脱敏后）+ 最近50条解析日志 + 系统信息（OS版本、内存、模型版本）→ zip → 用户自己决定是否发送
2. **解析日志本地留痕**：每次LLM调用保留`{prompt_hash, raw_response, parsed_result, status}`至少最近50条到`parse_log`表
3. **解析可重放**：每道题存`raw_text`和`parse_seed`，用户报告某题出错时，开发者可拿`raw_text`本地重放
4. **版本号显式展示**：主界面角落显示`v0.3.2 (commit xxx)`，方便对齐
5. **可选本地调试开关**：开发者构建版带`kDebugMode=true`显示原始LLM输入输出，普通用户构建默认关闭

**Warning signs:**
- 用户bug报告缺失关键信息（"就那个解析不对的"）
- 重启后用户无法复现自己上次的bug
- 开发者想"在我的机器上跑一下那个文件"，但文件路径不可知

**Phase to address:**
阶段1（解析基建阶段）就把诊断功能埋好，事后补代价高。诊断包功能可以放到阶段4（统计/收藏）一起做UI。

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| 把LLM原始输出直接存DB（不规范化） | 解析快、不用写canonicalization | 多选判分永远要靠字符串魔法；后续做"按知识点筛选"等需要正确字段 | 从不——schema设计阶段就归一化 |
| 用`bool is_wrong`而非状态枚举 | 简单、好懂 | 多选题半对无法表达；错题本/抽查/已掌握三态无法共存 | 仅在MVP原型期，最终必须重构 |
| 题库导入用同步`await db.insert`逐条写入 | 代码简单 | 500题导入时UI卡死5秒 | 仅当题库<50题；否则必须批量+事务 |
| LLM推理放主isolate | 不用写Isolate通信 | UI冻结、无法取消、ANR | 仅本地开发调试 |
| 解析错误直接丢弃原题不告知用户 | 不需要错误处理UI | 用户发现"我的500题变480题"毫无线索 | 从不——必须至少在导入结果页显示跳过题列表 |
| 用`DateTime.now().toString()`存时间戳 | 简单 | 时区错乱、跨日统计不准确 | 用`DateTime.now().millisecondsSinceEpoch`存int |
| Windows路径硬编码`\` | 不用引path包 | Android上崩溃 | 从不 |
| 模型文件放在APK assets里 | 离线即用 | APK体积+1GB，用户无法更新模型版本 | 仅当模型不可热更且<500MB；否则走"启动时下载到本地" |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `file_picker` (Windows) | 拿到绝对路径直接`File(path).readAsBytes()`——多数情况可行但遇到中文/空格路径UTF-8解码问题 | 用`pickFiles()`返回的`XFile`，Dart层统一处理编码 |
| `file_picker` (Android 11+) | 拿到的是`content://` URI，期望File path | 用`XFile.saveTo(path)`先拷贝到app dir再用File操作 |
| `path_provider` (Windows) | 假设返回的是`~/Documents`等可读路径 | Windows返回的是`%APPDATA%/Roaming/<app>`，写权限OK但要确认目录存在 |
| `sqlite3_flutter_libs` (Windows) | 仅在debug跑通就发布 | Windows release需要确保`.dll`被`flutter build windows`正确打包进`data/`目录 |
| `sqlite3` package | 直接`openDatabase('redclass.db')`，多实例时冲突 | 加应用层Mutex（Windows Named Mutex / Android单实例天然） |
| `llama.cpp` Dart binding | 默认下载CPU binary到Android | 验证模型文件路径与native lib同包，否则运行报"model file not found" |
| ONNX Runtime Mobile | 用CPU EP而不知GPU EP可用 | 跑profile对比CPU vs NNAPI/GPU，选耗电/速度平衡 |
| `pdfx` / `pdf_render` package | 用纯文本提取但PDF是扫描件 | 先`getText()` → 空内容则提示用户"PDF为图片，需OCR"（v1不支持，明确告知） |
| `docx` parsing (e.g. `archive` + XML) | 直接读XML但docx里有图片/表格 | 先用`docx_to_text`类库抽纯文本，再喂LLM |
| Flutter `WidgetsBindingObserver` (Desktop) | 假设`didChangeAppLifecycleState`在桌面会触发 | Desktop不触发；改用`onMetricsChanged`/`RawKeyboard`焦点事件 |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| LLM解析前全文一次喂给模型 | 1000题docx，模型截断只解析前50题 | 按题号切片，每题独立推理（牺牲速度换质量） | 任何>20题的题库 |
| DB查询没加索引`questions.bank_id`, `attempts.question_id` | 错题本500题时翻页要2秒 | 建表时加`CREATE INDEX idx_questions_bank ON questions(bank_id)` | 题库>100题时开始可感知 |
| 解析日志无界增长 | 应用启动越来越慢 | `parse_log`表保留最近200条，老的自动归档或删除 | 跑3个月后 |
| 抽题模式用`ORDER BY RANDOM()` | 1000题库时每次抽题全表扫描 | 维护`unanswered_count`，用id范围+偏移或预生成random id列表 | 题库>500题 |
| LLM每次重新加载模型 | 切题库切3次，每次等10秒 | 模型加载一次常驻内存，按需evict | 任何>1个题库的用户场景 |
| UI每帧rebuild ListView | 滚动掉帧 | 用`ListView.builder`+`const` Widget | 错题本>200题 |
| 解析进度用`setState`每题更新 | UI卡、闪屏 | 用`Stream`/`ValueNotifier`节流到每5题一次 | 题库>50题 |
| 多选题判分时`O(n*m)`比较 | 5选3 vs 5选4，每次做交叉乘 | 排序后`ListEquality().equals()` | 多选占比>30%且题库>500 |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| 解析日志里写入`raw_text`原文 | 用户隐私泄露（题库涉及学校内部资料） | 日志只存`hash`+前100字预览；诊断包导出前需用户明示同意 |
| DB文件明文存敏感信息 | 设备被他人拿走可直接看到所有错题/统计 | 至少加SQLCipher（如`sqlcipher_flutter_libs`），密码用设备pin派生；v1可先用纯文本+文档说明风险 |
| `file_picker`拿到路径后未校验文件类型 | 用户选`.exe`/`.docm`被读入，LLM prompt injection | 后缀校验+magic number校验；导入前sanitize |
| LLM prompt里直接拼接文件名/原始内容 | 恶意docx含`</question>答案：A`之类注入 | 解析前用`<text>...</text>`包裹并转义；解析后schema校验只看合法字段 |
| `path_provider`目录+模型文件全权限755 | 其他app可读 | Android利用沙箱天然隔离；Windows上提醒用户不要把DB放公共目录 |
| 应用日志含LLM输入输出明文 | logcat/Windows日志被同设备app读取 | release构建关闭`print`或加`if (kDebugMode)`守卫 |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| 提交答案前显示"正确选项"提示 | 学生秒选背答案，复习形同虚设 | 仅在用户提交后揭示对错，且揭示位置在题目下方而非上方（避免答题时瞥见） |
| 错题本只能"删除"不能"标记掌握" | 答对后永远在错题本里反复抽到，挫败感强 | "标记掌握"按钮，独立于"再来一次" |
| 错题本没有"为何错"标注 | 同样错误重复犯 | 答错时弹"错因"可选标签（粗心/没记住/题出错了），累积分析 |
| 收藏夹没有"按题库分组"或搜索 | 收藏500题后找不到 | 至少支持按题库筛选、按题干模糊搜索 |
| 抽题没有"上一题/下一题"导航 | 想回头看看上一题做错没有，要重新开始 | 至少提供"上一题"按钮 |
| 做完一题没有任何"完成感"反馈 | 缺乏动力 | 答对时有轻微动画/音效；连对5题有进度条；错题本减少时给"错题-1"飘字 |
| 三模式入口分散，找不到入口 | 用户找不到错题复习 | 主界面固定三个并列大按钮，遵循F-pattern左上优先 |
| 解析进度显示为"正在解析……"无具体数字 | 用户以为卡死强杀应用 | "解析中 47/120（约3分钟）"带百分比与剩余时间估算 |
| 多选漏选/多选与全错判分一致（都是0分） | 学生分不清"我接近对"还是"完全错" | 至少在结果页给"答对了2/3个选项"的明细反馈 |
| 错题复习用顺序而非乱序 | 用户背位置而非背题 | 永远用Fisher-Yates或库内置随机 |
| 导入完成无总结页（多少题成功/多少失败/失败原因） | 用户不知道发生了什么 | 导入完成页："✓ 解析成功 98 题，⚠ 2 题无法识别：第47题（题干缺失）、第83题（答案格式异常）→ 进入校对" |

## "Looks Done But Isn't" Checklist

- [ ] **题库解析：** 容易漏掉"schema校验"——不只是`jsonDecode`成功，还要校验`type`合法、`options`数量合理、`correct_answer`非空。验证：故意喂入畸形JSON和合法但语义错的JSON，断言解析层拒绝后者并打`parse_status=incomplete`
- [ ] **错题本状态机：** 容易漏掉"原子事务"和"幂等"。验证：模拟"答对→立刻杀进程→重启"，错题本条目数应等于-1
- [ ] **抽题模式去重：** 容易漏掉"同一session不重复抽同一题"。验证：连续抽10题断言id不重复
- [ ] **错题抽查排除已掌握：** 容易漏掉抽查的SQL过滤`mastered=true`。验证：QA测试，人为标3题为已掌握，抽查50次断言它们从未出现
- [ ] **多选题判分：** 容易漏掉"部分对也判错"业务规则的实现。验证：题答案AB，选AC应判错；选ABCDEFG应判错；选AB应判对
- [ ] **文件导入：** 容易漏掉"文件被占用/损坏/0字节"的处理。验证：用`File.lock`/`fsutil`让文件被Word打开时触发导入，断言给出友好错误而非崩溃
- [ ] **DB迁移：** 容易漏掉"schema升级路径"。验证：故意用旧DB启动新版本应用，断言自动迁移成功而非崩溃
- [ ] **LLM模型不存在：** 容易漏掉"模型文件丢失/路径错误"分支。验证：删掉模型文件后启动应用，断言提示"请下载模型"而非`null pointer`
- [ ] **窗口尺寸变化：** 容易漏掉"Windows窗口从1366×768拉到1920×1080"时UI布局。验证：实测窗口缩放不破版
- [ ] **Android后台被杀：** 容易漏掉"session恢复"。验证：进入做题界面→home键→等5分钟→回来，断言停在原题
- [ ] **错题复习做完一轮：** 容易漏掉"全部答对后给出完成反馈"。验证：错题本1题，答对，断言弹出"已掌握本轮全部错题"
- [ ] **时间戳：** 容易漏掉"时区一致性"。验证：用户改系统时区后老数据时间显示正常

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| LLM解析某题失败 | LOW | 单道题标`parse_status=incomplete`，导入完成页列出，用户可点击重解析该题（仅喂raw_text） |
| 解析过程中途崩溃（应用被杀） | MEDIUM | DB事务包裹整批导入，崩溃时`ROLLBACK`；下次启动检测`import_session.status='in_progress'`的孤儿记录并清理 |
| 解析出大量错位题 | MEDIUM | 保留`raw_text`和`parse_seed`，提供"批量重新解析"按钮，仅重跑`parse_status=incomplete`或`parse_status=suspect`（与上次结果diff差异大）的题 |
| DB损坏 | HIGH | 启动时跑`PRAGMA integrity_check`，失败则提示"数据库损坏，是否从备份恢复？"；自动每24h备份到`<docDir>/backups/redclass-YYYYMMDD.db`，保留最近7份 |
| LLM对同一题给不一致答案 | MEDIUM | 同一题多seed解析→投票；或仅采纳与历史一致的答案；首次解析时保留`parse_seed`便于回滚 |
| 用户误删错题本 | LOW | 错题本变更记录`wrong_ledger_history`表，标记+时间+session；提供"恢复最近删除"操作（保留7天） |
| 模型文件损坏/版本不匹配 | LOW | 启动时校验模型SHA256，不匹配则提示重新下载；提供"模型管理"页让用户手动校验 |
| Android OOM被LMK杀 | MEDIUM | 检测到`onTrimMemory(TRIM_MEMORY_RUNNING_CRITICAL)`时立即`llama_model_free`并中断当前任务；保留已完成解析的题目，下次启动可续解析 |
| 解析出的题目数量异常（<原文题号最大值） | LOW | 导入完成页显示对比"原文检测到约120题，实际解析98题"，列出跳过的题号，让用户决定是"重新解析"还是"接受现状" |
| DB迁移失败 | MEDIUM | v1→v2迁移前自动备份；失败时回滚到备份并提示；提供"导出全部题目为JSON"功能作为最后兜底 |
| 同一题被两个错题本条目录入 | LOW | `wrong_ledger(question_id, session_id)`设UNIQUE约束，重复insert触发`ON CONFLICT IGNORE` |
| 用户选错文件类型 | LOW | `file_picker`过滤器只允许`.docx/.pdf`；选其他类型直接Toast提示 |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Pitfall 1: LLM输出JSON漂移 | 阶段1 — 解析基建 | 同一raw_text跑10次断言schema完全一致；故意注入畸形prompt断言被拒绝 |
| Pitfall 2: 错题本状态机非原子 | 阶段1 (schema) + 阶段3 (联动) | 模拟事务中途崩溃，重启后DB一致；QA跑100次错题循环断言无幽灵条目 |
| Pitfall 3: 平台路径/编码 | 阶段1 — 基础设施 | Windows中文路径/Android 11+ scoped storage各跑10次导入断言成功 |
| Pitfall 4: Android LLM OOM | 阶段1 (真机压测) + 阶段1后段 (APK发布) | 真机（4GB/6GB RAM各1台）跑500题解析，断言不出现LowMemoryKiller日志 |
| Pitfall 5: 答案字段字符串化 | 阶段1 (schema) + 阶段2 (判分) | 单元测试覆盖所有"AB"/"A,B"/"a和b"归一化；QA实测多选判分100% |
| Pitfall 6: 题干切碎错位 | 阶段1 — 解析pipeline | 用真实老师docx×3个跑解析，QA人工对比"原文 vs 入库"错位率<5% |
| Pitfall 7: 桌面/Android生命周期 | 阶段2 (做题session) | Android真机home键测试、Windows最小化3小时测试 |
| Pitfall 8: 无遥测无法复现 | 阶段1 (日志基建) + 阶段4 (诊断包导出) | 触发bug后能从DB读出`parse_log`复现LLM输入输出 |
| Tech debt: 解析日志无界 | 阶段1 即埋点 | 跑模拟1年日志量断言LRU清理生效 |
| Perf: ORDER BY RANDOM() | 阶段3 — 抽查模式 | 题库1000题时抽题响应<100ms |
| UX: 揭示答案在提交前 | 阶段2 — 做题UI | QA走查做题流程，断言任何场景下提交前不可见正确答案 |
| UX: 导入无总结页 | 阶段1 — 导入完成页 | 跑一次混合（成功+失败）导入断言总结页内容完整 |

## Sources

- RedClass PROJECT.md / `.planning/config.json` — 项目核心需求、约束、技术决策
- `ui-ux-pro-max` skill 视觉规范参考（用户指定的UI设计输入）
- 通用知识：Flutter跨平台文件处理实践（`file_picker`+`path_provider`+`sqlite3_flutter_libs`已知陷阱）
- 通用知识：llama.cpp / on-device LLM在Android的内存峰值与生命周期管理（参考MobileLLM、MediaPipe LLM Inference的公开issue讨论）
- 通用知识：错题本/复习类应用（SRS间隔重复算法、Anki、Quizlet）的UX设计常见反模式
- 通用知识：SQLite FFI binding在Windows MSVC与Android NDK的链接差异，Chinese path编码（GBK vs UTF-8）历史问题

---

*Pitfalls research for: RedClass (红课复习) — Flutter desktop+Android local exam review tool with on-device LLM parsing*
*Researched: 2025-01*