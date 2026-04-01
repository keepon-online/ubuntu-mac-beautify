# Ubuntu Mac Beautify

Ubuntu 24.04 的 macOS 风格美化项目，支持根据用户选择对 `GNOME` 或 `KDE Plasma` 应用不同的美化流程。

这个项目把原本的单文件脚本整理成了可维护的目录结构：

- `install.sh`: 完整安装并应用 macOS 风格主题
- `reapply.sh`: 不重新下载主题，只重新应用外观设置
- `reset.sh`: 重置当前桌面环境的外观设置
- `uninstall.sh`: 卸载本项目装到用户目录里的主题、光标、扩展和壁纸
- `fix-desktop-icons.sh`: 修复用户本地隐藏 `.desktop` 条目导致的 GNOME 任务栏图标错乱
- `check.sh`: 校验脚本语法，若已安装 `shellcheck` 会自动执行
- `Makefile`: 提供统一入口
- `lib/common.sh`: 公共函数、桌面环境检测和桌面环境专属设置逻辑

## 功能

- 统一支持 `--desktop=auto|gnome|kde`
- GNOME:
  - 安装 `WhiteSur` GTK / Shell / Icon 主题
  - 安装 `McMojave-cursors`
  - 安装并启用 `Blur my Shell`
  - 配置底部 Dock、左侧窗口按钮、字体和壁纸
  - 可选美化 GDM 登录界面
  - 提供项目内 GDM 自定义资源与安装/修复/回滚脚本
  - 兼容 Ubuntu 24.04 默认的 `Ubuntu Dock`
- KDE:
  - 安装 `WhiteSur-gtk-theme` 作为 GTK 应用主题
  - 根据壁纸系列安装对应的 KDE 全局主题仓库
  - 默认支持 `WhiteSur-kde`，`ventura` / `sonoma` / `sequoia` 会自动切到对应的 macOS 风格 KDE 仓库
  - 安装 `WhiteSur-icon-theme` 和 `McMojave-cursors`
  - 尝试自动应用 KDE 全局主题、壁纸、光标、图标、颜色方案、字体和 Kvantum
  - 同步 GTK 2 / 3 / 4 主题配置，减少 KDE 下 GTK 应用风格割裂
  - 把窗口按钮布局调整为 macOS 风格的左侧 `关闭 / 最小化 / 最大化`
  - 对 `ventura` / `sonoma` / `sequoia` 默认优先使用圆角窗口装饰变体
  - 尝试把 Plasma 面板调整为底部、浮动、居中的 Dock 风格
  - 尝试为 Plasma 任务管理器预钉常用应用，例如文件管理器、浏览器、终端、截图和系统设置

## 使用

默认完整安装：

```bash
cd ubuntu-mac-beautify
bash ./install.sh
```

显式选择 GNOME：

```bash
bash ./install.sh --desktop=gnome
```

显式选择 KDE：

```bash
bash ./install.sh --desktop=kde
```

常用选项：

```bash
bash ./install.sh --desktop=gnome --light
bash ./install.sh --desktop=gnome --skip-gdm
bash ./install.sh --desktop=gnome --skip-blur
bash ./install.sh --desktop=kde --wallpaper=sonoma
bash ./install.sh --desktop=kde --light
bash ./install.sh --desktop=kde --kde-round
bash ./install.sh --desktop=kde --kde-no-round
bash ./install.sh --desktop=kde --skip-kde-panel
bash ./install.sh --desktop=kde --skip-kde-launchers
```

只重新应用外观，不重新下载：

```bash
bash ./reapply.sh --desktop=gnome
bash ./reapply.sh --desktop=gnome --skip-gdm
bash ./reapply.sh --desktop=kde
bash ./reapply.sh --desktop=kde --kde-round
bash ./reapply.sh --desktop=kde --skip-kde-panel
bash ./reapply.sh --desktop=kde --skip-kde-launchers
```

重置当前桌面外观设置：

```bash
bash ./reset.sh --desktop=gnome
bash ./reset.sh --desktop=gnome --keep-gdm
bash ./reset.sh --desktop=kde
```

卸载项目安装到用户目录的内容：

```bash
bash ./uninstall.sh --desktop=gnome
bash ./uninstall.sh --desktop=gnome --keep-gdm
bash ./uninstall.sh --desktop=kde
```

修复 GNOME 任务栏图标错乱：

```bash
bash ./fix-desktop-icons.sh
make fix-desktop-icons
```

做静态检查：

```bash
bash ./check.sh
make check
```

GDM 登录界面美化：

```bash
bash ./install.sh --desktop=gnome
bash ./install.sh --desktop=gnome --skip-gdm
sudo bash ./scripts/install-custom-gdm-prussiangreen.sh
sudo bash ./scripts/repair-gdm-theme-alternative.sh
sudo bash ./scripts/rollback-custom-gdm-prussiangreen.sh
```

详细说明见：

```text
docs/gdm-login-beautify.md
```

也可以直接用 `make`：

```bash
make install
make install DESKTOP=gnome
make install DESKTOP=kde
make install-kde
make reapply
make reapply DESKTOP=kde
make reset
make reset-kde
make fix-desktop-icons
make uninstall-kde
```

## KDE 说明

- `--desktop=auto` 会优先根据当前会话环境变量判断，如果判断失败，默认回退到 `gnome`
- KDE 的自动应用依赖当前系统里存在 `plasma-apply-lookandfeel`、`plasma-apply-wallpaperimage`、`kwriteconfig5/6` 等命令
- `bash ./install.sh --desktop=kde` 会先检查系统里是否已安装 KDE Plasma 会话；如果未安装，会直接报错并提示先装 `kde-standard`
- 面板 Dock 风格依赖 `qdbus` / `qdbus6` 与当前 Plasma DBus 会话可用
- 如果你在非 Plasma 会话里执行 `--desktop=kde`，主题文件仍会安装，但自动应用可能不完整
- KDE 路线会额外同步 `~/.config/gtk-3.0/settings.ini`、`~/.config/gtk-4.0/settings.ini` 和 `~/.gtkrc-2.0`
- 默认预钉应用会按系统已安装的 `.desktop` 文件自动挑选；如果你不想改任务栏固定项，可加 `--skip-kde-launchers`
- `ventura` / `sonoma` / `sequoia` 默认会优先选择圆角窗口装饰；如果你更喜欢默认变体，可加 `--kde-no-round`
- KDE 的 light/dark 细节取决于上游全局主题变体；必要时在“系统设置 -> 全局主题 / 图标 / 光标 / Kvantum”中手动确认一次
- 面板布局是 best-effort；如果你不想改面板，可加 `--skip-kde-panel`

## 说明

- 请用普通用户执行脚本，不要直接用 `sudo bash ...`
- `install.sh` 会在需要时自行调用 `sudo`
- 在 `GNOME` 路线下，`install.sh` 默认会自动尝试应用项目内 GDM 自定义主题；如果不想改登录界面，可加 `--skip-gdm`
- 在 `GNOME` 路线下，`reapply.sh` 也会默认尝试重新应用项目内 GDM 自定义主题；如果不想改登录界面，可加 `--skip-gdm`
- 在 `GNOME` 路线下，`reset.sh` 和 `uninstall.sh` 默认会自动把项目自定义 GDM 主题回滚到系统默认 `Yaru`；如果想保留当前登录界面，可加 `--keep-gdm`
- `scripts/install-custom-gdm-prussiangreen.sh` 等 GDM 脚本仍可单独手动执行，并且需要 `sudo`
- `fix-desktop-icons.sh` 只修复 `~/.local/share/applications` 下高置信度命中的隐藏 handler 条目，不会改系统 desktop 文件
- 如果主题没有立即完全生效，注销后重新登录一次
- 重复执行 `install.sh` 通常是安全的，但会重新下载上游仓库，并覆盖当前外观设置
- `uninstall.sh` 默认会回滚项目自定义 GDM 主题，但不会完整恢复上游 WhiteSur 的历史 GDM tweak
- GDM 登录界面进一步美化的背景、原理和回滚方式见 [docs/gdm-login-beautify.md](docs/gdm-login-beautify.md)

## 上游项目

- https://github.com/vinceliuice/WhiteSur-gtk-theme
- https://github.com/vinceliuice/WhiteSur-kde
- https://github.com/vinceliuice/MacVentura-kde
- https://github.com/vinceliuice/MacSonoma-kde
- https://github.com/vinceliuice/MacSequoia-kde
- https://github.com/vinceliuice/WhiteSur-icon-theme
- https://github.com/vinceliuice/McMojave-cursors
- https://github.com/vinceliuice/WhiteSur-wallpapers
- https://github.com/aunetx/blur-my-shell
