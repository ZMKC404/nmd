# nmd — 万物转 Markdown 技能库

**一个使命：任何格式 → 结构化 Markdown 语料。**

当前已发布：

| Skill | 输入 | 状态 |
|---|---|---|
| `nmd-mp4` | 音视频（mp4/m4a/wav/mov…） | ✅ 已实证（62 视频 / 16G 全程跑通） |
| `nmd-pdf` | PDF / Word | 🚧 规划中 |
| `nmd-img` | 图片 / 截图 | 🚧 规划中 |

## nmd-mp4：音视频 → 语料包

```
源视频 → ffmpeg 提音频 → 通义听悟网页版批量转写 → 内部API抓稿
       → LLM精校 → LLM精华 → 场景索引
```

- **零 API 费用**：用通义听悟网页版会员时长，不碰付费 OpenAPI
- **全实证流程**：上传/抓稿的每个接口、每个坑都来自真实跑通的批量任务
- **产出五层语料**：音频 → 原始转写 → 精校稿 → 精华稿 → 实战场景索引

## 安装

一行命令（自动探测技能目录）：

```bash
curl -fsSL https://raw.githubusercontent.com/ZMKC404/nmd/main/install.sh | bash
```

备选方式：

```bash
# skills.sh 生态
npx skills add ZMKC404/nmd

# 手动
git clone --depth 1 https://github.com/ZMKC404/nmd.git
cp -r nmd/skills/nmd-mp4 ~/.agents/skills/   # 或你的 agent 技能目录
```

## 使用

安装后对你的 agent 说人话即可触发：

> 「nmd-mp4，把 ~/下载/某某课程 转成语料包」
> 「批量转写这个目录的视频，输出精校稿 md」

## 前置依赖

- `ffmpeg`、`google-chrome`、`agent-browser`（npm i -g agent-browser）
- 通义听悟网页版账号（首次使用需在弹出的调试浏览器里扫码登录一次）

## 仓库结构

```
skills/nmd-mp4/
├── SKILL.md          # 全流程 + 已验证的坑清单
└── prompts/          # S4 精校 / S5 精华 / S6 索引 的精简提示词模板
```

## License

MIT
