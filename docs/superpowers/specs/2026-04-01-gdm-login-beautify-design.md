# GDM Login Beautify Design

## Summary

把这次 Ubuntu 24.04 上针对 GDM 登录界面的美化方案收敛进 `ubuntu-mac-beautify` 项目，形成可复用的文档、资源文件和安装/修复/回滚脚本。项目内版本必须自包含，不能再依赖 `/home/top/.local/...` 这类机器局部路径。

## Problem

当前用户锁屏界面已经接近目标风格，但 GDM 登录界面在默认实现下与锁屏存在明显差异。仅通过 `/etc/gdm3/greeter.dconf-defaults` 设置 GTK 主题、图标主题、鼠标主题和背景图，只能影响 Greeter 会话的部分设置，无法明显改变登录卡片、按钮、输入框等核心视觉元素。

进一步诊断表明，可见登录 UI 主要受 `gdm-theme.gresource` 中的 `gdm.css` 控制。因此如果要让登录界面更接近锁屏或当前 prussiangreen 风格，需要提供自定义 `gnome-shell-theme.gresource`，并通过 `update-alternatives` 把 `/usr/share/gnome-shell/gdm-theme.gresource` 切到自定义资源。

## Goals

- 在项目中保留这次 GDM 登录界面美化的完整背景、原理、安装方式和回滚方式。
- 将当前已验证可用的自定义 `gnome-shell-theme.gresource` 收进仓库。
- 提供项目内正式维护的 3 个脚本：安装、修复 alternatives、回滚。
- 脚本必须使用项目相对路径定位资源文件，而不是依赖家目录临时构建产物。
- 在 `README.md` 中给出入口，便于后续查找和复用。

## Non-Goals

- 本次不把自定义 GDM 资源自动接入 `install.sh` 主流程。
- 本次不提供重新编译 `gnome-shell-theme.gresource` 的构建脚本。
- 本次不处理 RustDesk 相关逻辑。
- 本次不覆盖 KDE 路线。

## User Experience

用户在项目目录内执行：

- `sudo bash ./scripts/install-custom-gdm-prussiangreen.sh`
- 如果 alternatives 链损坏，可执行 `sudo bash ./scripts/repair-gdm-theme-alternative.sh`
- 若需恢复默认 Yaru GDM，可执行 `sudo bash ./scripts/rollback-custom-gdm-prussiangreen.sh`

执行完成后，用户通过注销或重启回到 GDM 登录界面观察效果。

## Architecture

项目新增 3 类内容：

1. `assets/gdm/`：保存经过验证的自定义 `gnome-shell-theme.gresource` 二进制资源。
2. `scripts/`：保存正式维护的安装、修复、回滚脚本。脚本通过自身位置推导项目根目录，再定位 `assets/gdm/...`。
3. `docs/`：保存一篇面向使用者的 GDM 登录界面美化说明文档。

安装脚本的核心流程：

- 校验项目内资源文件和系统原始 Yaru 资源文件存在。
- 把项目内自定义资源安装到 `/usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/gnome-shell-theme.gresource`。
- 清理坏掉的 `gdm-theme.gresource` alternatives 状态。
- 用正确的 master link `/usr/share/gnome-shell/gdm-theme.gresource` 重新注册 alternatives。
- 切换到自定义资源并打印链路状态。

## Safety Rules

- 不直接覆盖 `/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource`。
- 不把 `/etc/alternatives/gdm-theme.gresource` 误写成 `update-alternatives --install` 的主链接。
- 回滚脚本只把 GDM 切回 Yaru，不删除用户系统上的自定义资源目录。
- 文档中明确说明需要 `sudo` 且建议先记住回滚命令。

## Files

- Create: `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource`
- Create: `scripts/install-custom-gdm-prussiangreen.sh`
- Create: `scripts/repair-gdm-theme-alternative.sh`
- Create: `scripts/rollback-custom-gdm-prussiangreen.sh`
- Create: `docs/gdm-login-beautify.md`
- Modify: `README.md`
- Modify: `check.sh`

## Verification

- `bash -n` 检查新增脚本语法。
- `bash ./check.sh` 确认项目静态检查通过。
- 校验文档中引用的脚本路径真实存在。
- 校验项目内资源文件包含 `Codex GDM prussiangreen override` 标记。

## Risks

- 自定义 GDM 资源是二进制文件，后续若系统升级 GNOME Shell 资源结构，可能需要重新构建。
- 不同 Ubuntu/GNOME 版本的 GDM CSS 结构可能变化，文档需要说明当前验证环境是 Ubuntu 24.04。
- 把二进制资源收进仓库会增大仓库体积，但能换来可复现性；本次选择可复现性优先。
