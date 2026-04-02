# GDM 登录界面美化

这份文档整理了 Ubuntu 24.04 上让 `GDM` 登录界面更接近当前锁屏和 `prussiangreen` 风格的做法。

## 适用环境

- Ubuntu 24.04
- `gdm3`
- GNOME 登录管理器
- 已经确认系统原始 GDM 资源位于 `/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource`

## 现象

常见情况是：

- 锁屏界面已经有想要的壁纸、主题和整体气质
- 开机登录界面仍然像默认 Ubuntu/GDM
- 修改 `/etc/gdm3/greeter.dconf-defaults` 后，登录界面看起来几乎没有明显变化

## 根因

`/etc/gdm3/greeter.dconf-defaults` 只能影响 Greeter 会话里的部分 GSettings，例如：

- `gtk-theme`
- `icon-theme`
- `cursor-theme`
- 背景图

但登录界面最显眼的这些元素：

- 登录卡片
- 输入框
- 按钮
- 提示文字
- 部分布局和颜色

主要由 `gdm-theme.gresource` 里的 `gdm.css` 控制。

所以如果目标是“让 GDM 登录界面明显更接近锁屏或当前主题”，单改 dconf 不够，必须切到自定义 `gnome-shell-theme.gresource`。

## 当前项目内包含的内容

- 自定义 GDM 资源：
  - `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource`
- 安装脚本：
  - `scripts/install-custom-gdm-prussiangreen.sh`
- 修复 alternatives 链脚本：
  - `scripts/repair-gdm-theme-alternative.sh`
- 回滚脚本：
  - `scripts/rollback-custom-gdm-prussiangreen.sh`

## 安装

在项目根目录执行：

```bash
bash ./install.sh --desktop=gnome
bash ./reapply.sh --desktop=gnome
```

如果你只想保留桌面主题，不想动登录界面：

```bash
bash ./install.sh --desktop=gnome --skip-gdm
bash ./reapply.sh --desktop=gnome --skip-gdm
```

如果你要把项目自定义 GDM 主题回滚到系统默认 `Yaru`：

```bash
bash ./reset.sh --desktop=gnome
bash ./uninstall.sh --desktop=gnome
```

如果你在 reset 或 uninstall 时想保留当前登录界面：

```bash
bash ./reset.sh --desktop=gnome --keep-gdm
bash ./uninstall.sh --desktop=gnome --keep-gdm
```

也可以单独只处理 GDM：

```bash
sudo bash ./scripts/install-custom-gdm-prussiangreen.sh
```

这个脚本会做这些事：

1. 把项目内自定义资源安装到 `/usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/gnome-shell-theme.gresource`
2. 重新注册 `gdm-theme.gresource` 的 `update-alternatives`
3. 把 GDM 当前主题切换到自定义资源
4. 打印 symlink 链路和资源标记，便于确认是否生效

其中：

- `install.sh --desktop=gnome` 会在 GNOME 主安装流程里自动尝试应用这套 GDM 自定义主题
- `reapply.sh --desktop=gnome` 会在重新应用桌面外观时再次尝试应用这套 GDM 自定义主题
- `install.sh` 和 `reapply.sh` 可以用 `--skip-gdm` 跳过这一步
- `reset.sh --desktop=gnome` 和 `uninstall.sh --desktop=gnome` 默认会把这套项目自定义 GDM 主题回滚到系统默认 `Yaru`
- 回滚场景可以用 `--keep-gdm` 保留当前登录界面

## 修复 alternatives 坏链

如果以前错误地把 `update-alternatives --install` 主链接写成 `/etc/alternatives/gdm-theme.gresource`，可能会出现这种坏状态：

```text
/etc/alternatives/gdm-theme.gresource -> /etc/alternatives/gdm-theme.gresource
```

这会导致“符号链接的层数过多”。

修复命令：

```bash
sudo bash ./scripts/repair-gdm-theme-alternative.sh
```

正确链路应该是：

```text
/usr/share/gnome-shell/gdm-theme.gresource -> /etc/alternatives/gdm-theme.gresource
/etc/alternatives/gdm-theme.gresource -> /usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/gnome-shell-theme.gresource
```

## 回滚到系统默认 Yaru

```bash
sudo bash ./scripts/rollback-custom-gdm-prussiangreen.sh
```

这个脚本只会把 GDM 主题切回 Yaru，不会删除 `/usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/` 下的资源文件。

## 生效方式

切换成功后，需要让 GDM 重新加载：

1. 注销到登录界面
2. 或直接重启

如果你是在当前桌面会话里执行脚本，执行完成后立刻看到的通常还是当前桌面，而不是 GDM 界面本身。

## 这版极简登录页会有哪些可见变化

如果当前项目内的 `prussiangreen` GDM 资源已经正确挂载，这一版登录页应该更容易肉眼识别：

- 登录卡片会更像一块深色玻璃面板，而不是普通深灰块
- 输入框和次级按钮会更薄、更冷静，边界更轻
- 主按钮会变成偏冷色的浅蓝灰高光，而不是绿色主调
- 整体文本和控件层次会更接近 macOS 式的极简深色风格

如果你确认 alternatives 链路已经指向项目自定义资源，但视觉上仍然完全像默认 Ubuntu/GDM，那么才值得继续排查资源内容是否没有更新。

## 验证方法

可以从脚本输出里确认这几件事：

- `gdm-theme.gresource` 的当前值已经指向自定义资源
- symlink 链路没有自循环
- 资源里包含标记：
  - `Codex GDM prussiangreen override`

也可以手动检查：

```bash
update-alternatives --display gdm-theme.gresource
ls -l /usr/share/gnome-shell/gdm-theme.gresource /etc/alternatives/gdm-theme.gresource
strings ./assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource | grep 'Codex GDM prussiangreen override'
```

## 风险说明

- 这是基于 Ubuntu 24.04 当前 GDM/Yaru 资源结构做的覆盖，不保证跨大版本直接兼容。
- 如果未来 GNOME Shell 或 Yaru 更新了 `gdm.css` 结构，这份自定义资源可能需要重新构建。
- 这次项目同步的是已经验证可用的编译产物，不包含重新编译该资源的自动化构建脚本。

## 与 dconf 方案的区别

`dconf` 方案：

- 优点：稳，侵入性低
- 缺点：能调的范围有限，通常不会让登录界面发生明显视觉变化

`gresource` 方案：

- 优点：能直接改到登录卡片、输入框、按钮、文本颜色等核心视觉层
- 缺点：侵入性更高，系统升级后可能需要重新适配

如果需求只是“背景图、GTK 主题、图标、鼠标能同步”，优先用 dconf。

如果需求是“开机登录界面看起来真的像你当前锁屏和主题风格”，就要用这份文档里的 `gresource` 方案。
