---
name: nmd-mp4
description: "音视频批量转结构化 Markdown 语料包。mp4/m4a 等 → ffmpeg 提音频 → 通义听悟网页版批量转写 → 内部API抓原始稿 → LLM精校 → LLM精华 → 场景索引。零 API 费用（用听悟网页版额度），全流程已实证（62 视频/16G）。触发词：nmd-mp4、转md、音视频转文字、课程转文字、批量转写、转语料包、语料工厂。"
---

# nmd-mp4 — 音视频 → Markdown 语料包

把批量音视频（课程/会议/访谈）转成可检索的结构化 md 语料。只用通义听悟**网页版额度**，零 API 费用。

## 流水线总览

```
源视频 → [S1] ffmpeg 提音频 → [S2] 听悟网页版批量转写 → [S3] 内部API抓原始稿
       → [S4] LLM精校 → [S5] LLM精华 → [S6] 场景索引
```

## 产出位置与目录结构（固定，别发明新结构）

- **项目文件夹放在用户可接触的位置：除非用户特别指定，一律建在用户桌面**（`~/桌面/<项目名>/`），项目名默认取源视频目录名。
- 源视频在别处时**不要搬动**，用符号链接：`ln -s <源目录> ~/桌面/<项目>/0-mp4视频`。

```
<项目>/
├── 0-mp4视频/          # 源视频（本地或符号链接）
├── 1-ffmpeg转音频/
├── 2-通义转写稿/
├── 3-LLM精校稿/
├── 4-精华提炼/
└── 5-索引/实战场景索引.md
```

## 执行约束（所有阶段通用）

- **清单永远从磁盘生成**（`ls`/`os.listdir`），禁止凭记忆或猜测文件名；每阶段结束 `diff` 双向核对数量。
- 大批量任务用后台任务 + 定时轮询（cron 每 10 分钟左右），不阻塞主会话；中断后按缺失清单续跑。
- S4–S6 用子代理 swarm 并行（一篇一个代理），提示词用本 skill `prompts/` 目录下对应模板，替换 `{{占位符}}` 后下发。

## S1 ffmpeg 提取音频

```bash
cd 0-mp4视频
for f in *.mp4; do
  ffmpeg -nostdin -v error -i "$f" -vn -ac 1 -ar 16000 -b:a 48k "../1-ffmpeg转音频/${f%.mp4}.m4a" -y </dev/null
done
```

- 提取后上传量缩至约 1/25（实测 16G→635M），转写质量无损。**不要视频直传**（未验证，且大文件浏览器上传慢易断）。
- ⚠️ 循环里必须 `-nostdin </dev/null`，否则只处理第一个文件。
- ffmpeg 只出音频不出文字。
- Gate：音频数 = 视频数；抽 2-3 个用 `ffprobe` 验时长与源一致。

## S2 听悟网页版批量转写（CDP 自动化）

**启动独立调试浏览器（绝不动用户日常浏览器）：**

```bash
google-chrome --user-data-dir="$HOME/chrome-debug-profile" \
  --remote-debugging-port=9222 --no-first-run --no-default-browser-check \
  "https://tingwu.aliyun.com" &
```

- 自动化统一用 `agent-browser --cdp 9222 <cmd>`（open/eval/click/snapshot/upload）。
- 无登录态 → 通知用户在该窗口扫码一次。这是唯一人工节点。

**上传步骤（照抄）：**

1. **先建文件夹再上传**（优雅归位，别让记录散落在默认文件夹）：
   - 文件夹名根据视频内容自动命名——取源视频目录名/课程名（如"独孤九剑"），不要叫"新建文件夹"这类废名。
   - 已存在同名文件夹就直接用；没有则建：进"我的记录"（`/folders/0`）→ `button "新 建"` → 菜单选"文件夹" → 输入名称。
   - 然后导航进 `https://tingwu.aliyun.com/folders/{dirId}`（dirId 从 URL 看）。**记录落在当前文件夹**，顺序别反：人在文件夹里上传，记录自动归入该文件夹，事后无需移动。
   - 个别记录落错位置时，在文件夹列表页用"批量"勾选 → 移动到目标文件夹兜底。
2. `snapshot -i` 找 `button "新 建"` 的 ref，`click @ref`。
3. 点开"上传本地音视频文件"——直接 click ref 常无效，用 JS 派发事件：
   ```js
   const el=[...document.querySelectorAll('*')]
     .filter(e=>e.children.length===0&&e.textContent.trim()==='上传本地音视频文件')[0];
   ['mousedown','mouseup','click'].forEach(t=>el.dispatchEvent(new MouseEvent(t,{bubbles:true})));
   ```
4. 等 `input[type=file]` 出现：`agent-browser --cdp 9222 upload "input[type=file]" 文件...`
5. 确认"文件数量：N/50" → 选说话人模式（课程独白=**单人演讲**，访谈=2人对话，会议=多人讨论）→ 语言中文 → 开始转写。

**已验证限制：**
- 单批最多 50 个文件，超了分批。
- ⚠️ 文件名含 `？` 等特殊符号会**静默失败**：每批提交后按文件夹"共 N 条"逐名核对，缺失的单独补传。
- 转写速度约 1–3 分钟/个（10 分钟音频）。

## S3 抓原始稿（内部 API）

⚠️ 别用网页"导出"（只有 docx）；别抓 DOM（虚拟滚动，只渲染约 10 段）。在页面上下文 `fetch` 内部 API（同源自带登录态）：

**列表（transId ↔ 标题）** POST `/api/trans/request?getTransList&c=web`：
```json
{"action":"getTransList","version":"1.0","userId":"",
 "filter":{"status":[0],"fileTypes":[],"beginTime":"","mediaType":"","endTime":"",
           "showName":"","read":"","dirId":文件夹ID,"lang":"","shareUserId":"","searchKey":""},
 "pageNo":1,"pageSize":100}
```
标题在 `tag.showName`，ID 在 `transId`。

**全文** POST `/api/trans/getTransResult?c=web`，body `{"transId":"xxx"}`。
⚠️ `data.result` 双重编码字符串/对象两种形态都会出现：
```js
let res = j.data.result;
while (typeof res === 'string') res = JSON.parse(res);
const text = res.pg.map(p=>p.sc.map(s=>s.tc).join('')).join('\n\n');
```
结构：`pg[]`→`sc[]`（`tc` 文本、`bt/et` 毫秒时间戳、`si` 说话人）。批量每次约 6 个分块 eval。落盘 `2-通义转写稿/{标题}.txt`。
Gate：txt 数 = 记录数，无空文件。

## S4 LLM 精校（→ 3-LLM精校稿/）

swarm 一篇一个子代理，提示词模板：`prompts/polish.md`。
- `{{术语表}}`：先通读若干篇原稿，整理该语料高频误识别词表（示例："第X件/第X届"→"第X剑"、行业专有名词）填入。
- Gate：md 数 = txt 数；每篇含概要和要点总结（`grep -L` 检查）。

## S5 LLM 精华（→ 4-精华提炼/）

swarm 一篇一个子代理，提示词模板：`prompts/essence.md`。
- 原则：价值零丢失优先于长度（话术密度高的材料落在 30–50% 属正常）。
- Gate：精华数 = 精校数。

## S6 场景索引（→ 5-索引/实战场景索引.md）

1. swarm 逐篇生成条目，提示词模板：`prompts/index-entry.md`。
2. 单代理合并为三段式索引（场景反查 + 体系正查 + 术语表），提示词模板：`prompts/index-merge.md`。
3. Gate：索引覆盖 100% 文件名，与磁盘逐一比对。

---

## 已知坑速查（全部实测）

1. ffmpeg 循环必须 `-nostdin </dev/null`
2. 听悟菜单项要 JS 派发 mousedown/mouseup/click
3. 单批 ≤50 个文件
4. 特殊字符文件名静默失败 → 交后逐名核对
5. 转写正文虚拟滚动，DOM 抓不全 → 用内部 API
6. getTransResult 的 result 双重编码/对象两态兼容
7. 清单以磁盘为准，每阶段 diff 核对

> 一句话：**ffmpeg 提音频 → 独立浏览器进文件夹批量上传（50/批、交后核对）→ 内部 API 抓稿 → swarm 精校/精华 → 场景索引。零 API 费用，不碰用户浏览器。**
