#!/usr/bin/env bash
# nmd skill 一键安装：自动探测 agent 技能目录并安装 nmd-mp4
set -euo pipefail

REPO="https://github.com/ZMKC404/nmd.git"
SKILL_NAME="nmd-mp4"

# 按优先级探测技能目录
SKILLS_DIR=""
for d in "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.config/opencode/skills"; do
  if [ -d "$d" ]; then SKILLS_DIR="$d"; break; fi
done
if [ -z "$SKILLS_DIR" ]; then
  SKILLS_DIR="$HOME/.agents/skills"
  mkdir -p "$SKILLS_DIR"
  echo "未发现既有技能目录，已创建 $SKILLS_DIR"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ 拉取 $REPO ..."
git clone --depth 1 --quiet "$REPO" "$TMP/nmd"

echo "→ 安装 $SKILL_NAME 到 $SKILLS_DIR ..."
rm -rf "$SKILLS_DIR/$SKILL_NAME"
cp -r "$TMP/nmd/skills/$SKILL_NAME" "$SKILLS_DIR/$SKILL_NAME"

if [ -f "$SKILLS_DIR/$SKILL_NAME/SKILL.md" ]; then
  echo "✓ 安装完成：$SKILLS_DIR/$SKILL_NAME"
  echo "  对 agent 说「nmd-mp4，把 <视频目录> 转成语料包」即可使用"
else
  echo "✗ 安装失败：SKILL.md 未找到" >&2
  exit 1
fi
