# GDM Login Minimal Redesign Design

## Summary

在不改变现有 GDM 安装、修复、回滚链路的前提下，重新设计项目内 `prussiangreen` 登录资源的视觉层，让 Ubuntu 24.04 的 GDM 登录页更接近 macOS 的极简深色风格。

## Problem

当前项目的 GDM 自定义资源已经正确挂载到 `gdm-theme.gresource`，但视觉变化不够明显。登录页虽然不是默认系统链路问题，却仍然容易被用户感知为“没有美化”，说明现有资源在卡片、按钮、输入框、背景氛围上的风格偏弱，无法形成清晰的 macOS 极简识别。

## Goals

- 保留现有 GDM 安装与回滚脚本，不改 `update-alternatives` 链路。
- 把登录页视觉方向改为“深色、中性、轻冷调、极简”。
- 明显提升登录卡片、输入框、按钮和背景聚焦感。
- 保持变更可回滚，仍通过当前项目脚本安装。
- 增加内容级测试，避免“资源已挂载但视觉特征不明显”再次难以判断。

## Non-Goals

- 不修改 KDE 逻辑。
- 不重写 `install.sh` / `reapply.sh` / `reset.sh` / `uninstall.sh` 主流程。
- 不改变 GDM alternatives 管理方式。
- 不追求完全复刻 macOS 登录页布局。

## Approved Direction

- 风格：macOS 登录页式的极简深色方案
- 色彩：深色为主，允许很轻的冷色调，不保留明显绿色主调
- 改动强度：中等，允许重做背景遮罩和登录卡片结构感，但不大改安装体系

## User Experience

用户重新应用项目 GDM 主题后，登录页应该出现这些更容易感知的变化：

- 登录卡片更像一块轻薄的深色玻璃面板，而不是普通深灰块
- 输入框与按钮更干净、更克制，边界更细，层级更明确
- 背景暗化和聚焦更明显，登录区域更突出
- 整体颜色趋向中性黑灰，只有轻微冷色高光，不再突出绿色

## Architecture

本次改动集中在项目已有的 GDM 资源内容，而不是系统接入链路：

1. 提取并修改 `gnome-shell-theme.gresource` 中与 GDM 登录页相关的 CSS 资源。
2. 重新生成项目内 `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource`。
3. 新增基于资源内容的测试，验证关键视觉标记和样式片段存在。
4. 更新文档，明确这版登录页的预期视觉变化。

## Files

- Modify: `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource`
- Modify: `docs/gdm-login-beautify.md`
- Modify: `check.sh`
- Modify: `tests/gdm_theme_scripts_test.sh` if needed for resource assertions
- Create: `tests/gdm_theme_resource_style_test.sh`
- Create: `docs/superpowers/plans/2026-04-02-gdm-login-minimal-redesign.md`

## Safety Rules

- 不改动现有 GDM 安装、修复、回滚脚本的接口和职责。
- 只在已识别的登录页相关 CSS 规则上做最小必要修改。
- 保留回滚路径，任何视觉变更都必须仍可通过当前 rollback 脚本恢复。
- 增加资源内容测试，避免仅凭人工肉眼判断是否生效。

## Verification

- 资源内容测试能证明新的极简深色样式片段存在。
- 现有 GDM 链路测试继续通过。
- `bash ./check.sh` 继续通过。
- 文档明确说明这次改版后登录页应有哪些可见变化。

## Risks

- `gnome-shell-theme.gresource` 为二进制资源，重新打包时容易引入结构性错误。
- GDM CSS 依赖 Ubuntu 24.04 当前资源结构，后续系统升级后可能仍需再适配。
- 若视觉调整过重，可能影响 Ubuntu 原生控件可读性，因此需要内容级测试兜底。
