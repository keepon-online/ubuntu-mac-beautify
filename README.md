# Ubuntu Mac Beautify

Ubuntu 24.04 GNOME 的 macOS 风格美化项目。

这个项目把原本的单文件脚本整理成了可维护的目录结构：

- `install.sh`: 完整安装并应用 macOS 风格主题
- `reapply.sh`: 不重新下载主题，只重新应用外观设置
- `reset.sh`: 只重置 GNOME 外观设置
- `uninstall.sh`: 卸载本项目装到用户目录里的主题、光标、扩展和壁纸
- `check.sh`: 校验脚本语法，若已安装 `shellcheck` 会自动执行
- `Makefile`: 提供统一入口
- `lib/common.sh`: 公共函数和 GNOME 设置逻辑

## 功能

- 安装 `WhiteSur` GTK / Shell / Icon 主题
- 安装 `McMojave-cursors`
- 安装并启用 `Blur my Shell`
- 配置底部 Dock、左侧窗口按钮、字体和壁纸
- 可选美化 GDM 登录界面
- 兼容 Ubuntu 24.04 默认的 `Ubuntu Dock`

## 使用

完整安装：

```bash
bash /home/top/ubuntu-mac-beautify/install.sh
```

常用选项：

```bash
bash /home/top/ubuntu-mac-beautify/install.sh --light
bash /home/top/ubuntu-mac-beautify/install.sh --skip-gdm
bash /home/top/ubuntu-mac-beautify/install.sh --wallpaper=sonoma
bash /home/top/ubuntu-mac-beautify/install.sh --show-apps-button
```

只重新应用外观，不重新下载：

```bash
bash /home/top/ubuntu-mac-beautify/reapply.sh
```

例如重新显示应用列表按钮：

```bash
bash /home/top/ubuntu-mac-beautify/reapply.sh --show-apps-button
```

重置当前 GNOME 外观设置：

```bash
bash /home/top/ubuntu-mac-beautify/reset.sh
```

卸载项目安装到用户目录的内容：

```bash
bash /home/top/ubuntu-mac-beautify/uninstall.sh
```

做静态检查：

```bash
bash /home/top/ubuntu-mac-beautify/check.sh
make -C /home/top/ubuntu-mac-beautify check
```

也可以直接用 `make`：

```bash
make -C /home/top/ubuntu-mac-beautify install
make -C /home/top/ubuntu-mac-beautify reapply
make -C /home/top/ubuntu-mac-beautify reset
```

## 说明

- 请用普通用户执行脚本，不要直接用 `sudo bash ...`
- `install.sh` 会在需要时自行调用 `sudo`
- 如果主题或模糊效果没有立即完全生效，注销后重新登录一次
- 重复执行 `install.sh` 通常是安全的，但会重新下载上游仓库，并覆盖当前外观设置
- `uninstall.sh` 默认不会自动恢复 GDM 登录界面

## 上游项目

- https://github.com/vinceliuice/WhiteSur-gtk-theme
- https://github.com/vinceliuice/WhiteSur-icon-theme
- https://github.com/vinceliuice/McMojave-cursors
- https://github.com/vinceliuice/WhiteSur-wallpapers
- https://github.com/aunetx/blur-my-shell
