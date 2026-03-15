# questions.json 使用说明

## 题库元数据结构（推荐）

为了让程序能够检查题库是否支持加载以及是否需要更新，建议在 JSON 文件开头添加元数据信息：

```json
{
  "_meta": {
    "format": "cz002-questions",
    "format_version": "1.0.0",
    "min_reader_version": "1.0.0",
    "created_at": "2025-01-29",
    "updated_at": "2025-01-29",
    "total_questions": 613,
    "categories": [
      "理论知识", "机器学习", "深度学习",
      "自然语言处理", "数据标注", "算法",
      "计算机视觉", "职业道德"
    ]
  },
  "questions": [
    { "id": 1, "question": "...", ... }
  ]
}
```

### 元数据字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `_meta.format` | String | 题库格式标识，固定值 `"cz002-questions"` |
| `_meta.format_version` | String | 格式版本号，遵循语义化版本 (SemVer) |
| `_meta.min_reader_version` | String | 最低支持的读取器版本 |
| `_meta.created_at` | String | 题库创建日期 (YYYY-MM-DD) |
| `_meta.updated_at` | String | 题库最后更新日期 (YYYY-MM-DD) |
| `_meta.total_questions` | Number | 题目总数，用于快速校验 |
| `_meta.categories` | Array | 包含的知识领域列表 |

### 版本兼容性检查

程序加载时可以按以下逻辑检查：

```python
import json
from packaging import version

SUPPORTED_FORMAT_VERSION = "1.0.0"
CURRENT_READER_VERSION = "1.2.0"

def load_questions(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 检查元数据
    if '_meta' not in data:
        print("警告: 题库缺少元数据，可能为旧版本格式")
        # 兼容旧格式：直接返回数组
        if isinstance(data, list):
            return data
        return data.get('questions', [])

    meta = data['_meta']

    # 检查格式类型
    if meta.get('format') != 'cz002-questions':
        raise ValueError(f"不支持的题库格式: {meta.get('format')}")

    # 检查格式版本
    fmt_ver = meta.get('format_version', '1.0.0')
    if version.parse(fmt_ver) > version.parse(SUPPORTED_FORMAT_VERSION):
        print(f"警告: 题库版本 {fmt_ver} 较新，建议更新程序")
        # 可以选择继续加载或拒绝

    # 检查最低读取器版本
    min_ver = meta.get('min_reader_version', '1.0.0')
    if version.parse(CURRENT_READER_VERSION) < version.parse(min_ver):
        raise ValueError(
            f"读取器版本过低，需要至少 {min_ver}，"
            f"当前版本 {CURRENT_READER_VERSION}"
        )

    # 校验题目数量
    questions = data.get('questions', [])
    if meta.get('total_questions') != len(questions):
        print(f"警告: 元数据记录 {meta['total_questions']} 题，"
              f"实际加载 {len(questions)} 题")

    return questions
```

### 更新检查机制

```python
import requests
from datetime import datetime

def check_update(meta):
    """检查题库是否需要更新"""
    # 本地题库日期
    local_date = datetime.strptime(meta['updated_at'], '%Y-%m-%d').date()

    # 从服务器获取最新版本信息
    try:
        response = requests.get(
            'https://example.com/api/questions/latest',
            timeout=5
        )
        remote_meta = response.json()

        remote_date = datetime.strptime(
            remote_meta['updated_at'], '%Y-%m-%d'
        ).date()

        if remote_date > local_date:
            print(f"发现新版本题库 ({remote_meta['updated_at']})")
            print(f"当前版本: {meta['updated_at']}")
            return True, remote_meta
        else:
            print("题库已是最新版本")
            return False, None
    except Exception as e:
        print(f"无法检查更新: {e}")
        return False, None
```

---

## 数据结构概览（单条题目）

```json
{
  "id": 1,
  "question": "题目内容",
  "options": [{"label": "A", "content": "选项内容"}],
  "answer": "A",
  "type": "单选题",
  "category": "理论知识",
  "image": null,
  "source": "理论题试题",
  "explanation": "AI是Artificial Intelligence的缩写..."
}
```

## 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | Number | **全局唯一题目序号**（整个题库中唯一） |
| `question` | String | 题目问题 |
| `options` | Array | 选项列表 |
| `answer` | String/Array | 答案 |
| `type` | String | 题型：单选题/多选题/判断题/简答题 |
| `category` | String/List | **知识领域分类**（智能分类，支持多标签） |
| `image` | String/null | base64图片 |
| `source` | String | 来源文件名 |
| `explanation` | String/null | **答案解析**（AI生成，100字以内） |

---

## 知识领域分类（category）

`category` 字段根据题目内容**自动智能分类**，共8个领域：

| 分类 | 说明 | 自动匹配关键词 |
|------|------|----------------|
| **理论知识** | AI概念、历史、定义 | AI、人工智能、智能体、图灵、图灵测试、专家系统、知识图谱、启发式、状态空间、问题归约 |
| **机器学习** | ML相关 | 机器学习、训练、模型、预测、分类、聚类、回归、监督、无监督、决策树、随机森林、贝叶斯、SVM、K近邻、朴素贝叶斯、集成学习 |
| **深度学习** | DL相关 | 神经网络、深度学习、卷积、激活函数、BP、反向传播、CNN、RNN、LSTM、Transformer、梯度下降、损失函数、权重、偏置 |
| **自然语言处理** | NLP相关 | 自然语言、文本、语料、分词、BERT、语音、词向量、语言模型、命名实体、句法、语义、NLP、word2vec、注意力机制 |
| **数据标注** | 数据相关 | 数据标注、标注、数据集、样本、标签、标注员、众包、采集、清洗 |
| **算法** | 算法相关 | 算法、搜索、排序、图、树、遍历、动态规划、贪心、递归、链表、栈、队列、哈希、排序算法、查找、复杂度 |
| **计算机视觉** | CV相关 | 图像、视频、视觉、目标检测、分割、边缘、特征提取、识别、矩形框、关键点、标注、CV、OpenCV |
| **职业道德** | 职业相关 | 职业道德、爱岗敬业、诚实守信、责任、义务、纪律、奉献、服务、法律、法规、劳动法、合同法、保密、知识产权 |

### 分类统计

| 知识领域 | 题目数量 |
|----------|----------|
| 数据标注 | 321 道 |
| 算法 | 76 道 |
| 自然语言处理 | 49 道 |
| 计算机视觉 | 43 道 |
| 机器学习 | 42 道 |
| 职业道德 | 39 道 |
| 理论知识 | 30 道 |
| 深度学习 | 13 道 |

> 统计时间：2025-01-29（AI 重新分类后）

---

## 各题型数据格式

### 1. 单选题

```json
{
  "id": 1,
  "question": "AI的英文缩写是（）",
  "options": [
    {"label": "A", "content": "Automatic Intelligence"},
    {"label": "B", "content": "Artificial Intelligence"},
    {"label": "C", "content": "Automatic Information"},
    {"label": "D", "content": "Artificial Information"}
  ],
  "answer": "B",
  "type": "单选题",
  "category": "理论知识",
  "image": null,
  "source": "人工智能训练师 复习题",
  "explanation": "AI是Artificial Intelligence的缩写，中文意为人工智能。"
}
```

**answer**: 字符串 `"A"` / `"B"` / `"C"` / `"D"`

---

### 2. 多选题

```json
{
  "id": 1,
  "question": "数据质量评估标准包括()。",
  "options": [
    {"label": "A", "content": "完整性"},
    {"label": "B", "content": "准确性"},
    {"label": "C", "content": "经济性"},
    {"label": "D", "content": "一致性"}
  ],
  "answer": ["A", "B", "C", "D"],
  "type": "多选题",
  "category": "数据标注",
  "image": null,
  "source": "理论题模拟题",
  "explanation": "数据质量评估标准包括完整性、准确性、经济性和一致性四个方面。"
}
```

**answer**: 数组 `["A", "B"]` 或 `["A", "B", "C", "D"]`

---

### 3. 判断题

```json
{
  "id": 1,
  "question": "语音交互仅仅包括语音采集。",
  "options": [
    {"label": "A", "content": "正确"},
    {"label": "B", "content": "错误"}
  ],
  "answer": "B",
  "type": "判断题",
  "category": "自然语言处理",
  "image": null,
  "source": "理论题模拟题",
  "explanation": "语音交互不仅包括语音采集，还包括语音识别、语音合成和语义理解等多个环节。"
}
```

**answer**: 字符串 `"A"` = 正确，`"B"` = 错误

---

### 4. 简答题

```json
{
  "id": 1,
  "question": "智能包含哪些能力?",
  "options": [],
  "answer": "(1)感知能力；(2)记忆和思维能力；(3)学习和自适应能力；(4)行为能力。",
  "type": "简答题",
  "category": "理论知识",
  "image": null,
  "source": "人工智能训练师 复习题",
  "explanation": "智能的四个核心能力：感知能力获取外部信息，记忆和思维能力存储与处理信息，学习和自适应能力提升智能水平，行为能力将智能转化为实际行动。"
}
```

**options**: 空数组 `[]`
**answer**: 文字答案字符串

---

### 5. 带图片的题目

```json
{
  "id": 62,
  "question": "下图标注属于（）标注。",
  "options": [
    {"label": "A", "content": "矩形框标注"},
    {"label": "B", "content": "关键点标注"},
    {"label": "C", "content": "语音标注"},
    {"label": "D", "content": "文本标注"}
  ],
  "answer": "A",
  "type": "单选题",
  "category": "计算机视觉",
  "image": "data:image/png;base64,iVBORw0KGgoAAAA",
  "source": "理论题模拟题",
  "explanation": "矩形框标注是最常见的目标检测标注方式，用矩形框框选图像中的目标物体。"
}
```

**image**: Data URI格式，可直接用于HTML `<img src="...">`

---

## Python 使用示例

### 读取文件（兼容新旧格式）

```python
import json

def load_questions(file_path):
    """加载题库，兼容新旧格式"""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 新格式：包含 _meta 和 questions
    if isinstance(data, dict) and '_meta' in data:
        meta = data['_meta']
        questions = data['questions']
        print(f"题库格式: {meta.get('format')}")
        print(f"格式版本: {meta.get('format_version')}")
        print(f"更新日期: {meta.get('updated_at')}")
        return questions

    # 旧格式：直接是数组
    elif isinstance(data, list):
        return data

    return []

questions = load_questions('questions.json')
print(f"总题数: {len(questions)}")
```

### 按知识领域筛选

```python
# 获取机器学习相关题目
ml_questions = [q for q in questions if q['category'] == '机器学习']
print(f"机器学习题目: {len(ml_questions)} 道")

# 获取数据标注相关题目
data_questions = [q for q in questions if q['category'] == '数据标注']
print(f"数据标注题目: {len(data_questions)} 道")

# 获取职业道德相关题目
ethics_questions = [q for q in questions if q['category'] == '职业道德']
print(f"职业道德题目: {len(ethics_questions)} 道")
```

### 按题型筛选

```python
# 单选题
single = [q for q in questions if q['type'] == '单选题']

# 多选题
multi = [q for q in questions if q['type'] == '多选题']

# 判断题
judge = [q for q in questions if q['type'] == '判断题']

# 简答题
short = [q for q in questions if q['type'] == '简答题']
```

### 组合筛选

```python
# 获取机器学习的单选题
ml_single = [q for q in questions
            if q['category'] == '机器学习' and q['type'] == '单选题']
print(f"机器学习单选题: {len(ml_single)} 道")

# 获取数据标注相关的多选题
data_multi = [q for q in questions
              if q['category'] == '数据标注' and q['type'] == '多选题']
print(f"数据标注多选题: {len(data_multi)} 道")
```

### 随机抽题

```python
import random

# 从每个知识领域各抽5道题
paper = []
for category in ['机器学习', '数据标注', '算法', '理论知识']:
    cat_questions = [q for q in questions if q['category'] == category]
    paper.extend(random.sample(cat_questions, 5))

print(f"试卷共 {len(paper)} 题")
```

### 按分类统计

```python
from collections import Counter

# 统计各知识领域题目数量
category_stats = Counter(q['category'] for q in questions)
for cat, count in category_stats.most_common():
    print(f"{cat}: {count} 道")
```

---

## JavaScript 使用示例

### 读取文件

```javascript
const questions = require('./questions.json');
console.log(`总题数: ${questions.length}`);
```

### 按知识领域筛选

```javascript
// 获取机器学习题目
const mlQuestions = questions.filter(q => q.category === '机器学习');

// 获取数据标注题目
const dataQuestions = questions.filter(q => q.category === '数据标注');

// 获取算法题目
const algoQuestions = questions.filter(q => q.category === '算法');

// 获取职业道德题目
const ethicsQuestions = questions.filter(q => q.category === '职业道德');
```

### 组合筛选

```javascript
// 机器学习单选题
const mlSingle = questions.filter(q =>
    q.category === '机器学习' && q.type === '单选题'
);

// 数据标注多选题
const dataMulti = questions.filter(q =>
    q.category === '数据标注' && q.type === '多选题'
);
```

---

## 答案格式对照表

| 题型 | answer 类型 | 示例 |
|------|-------------|------|
| 单选题 | String | `"A"` |
| 多选题 | Array | `["A", "B", "C"]` |
| 判断题 | String | `"A"` (正确) / `"B"` (错误) |
| 简答题 | String | `"文字答案"` |

---

## 知识领域分类列表

| 代码 | 名称 | 关键词 |
|------|------|--------|
| - | 理论知识 | AI、人工智能、图灵、专家系统 |
| - | 机器学习 | 模型、训练、分类、聚类、回归、监督 |
| - | 深度学习 | 神经网络、CNN、RNN、Transformer |
| - | 自然语言处理 | 文本、语音、BERT、分词、NLP |
| - | 数据标注 | 标注、数据集、样本、标签 |
| - | 算法 | 搜索、排序、图、树、动态规划 |
| - | 计算机视觉 | 图像、视频、目标检测、CV |
| - | 职业道德 | 职业道德、爱岗敬业、诚实守信 |

---

## 注意事项

1. **编码**: 文件使用 UTF-8 编码
2. **序号**: `id` 按来源文件独立编号
3. **分类**: `category` 根据题目内容自动分类
4. **图片**: 以 Data URI 格式存储
5. **简答题**: `options` 为空数组 `[]`
