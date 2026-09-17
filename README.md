# DSH Desktop for Ubuntu

> 基于 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) 插件生态的开源桌面客户端 - **Ubuntu Linux 社区构建版本**

![DSH Desktop](https://raw.githubusercontent.com/anywhere-labs/dsh-desktop/master/assets/desktop-hero-zh.png)

## 这是什么？

DSH Desktop 将 DeepSeek Harness 的本地 Web UI、Host 服务和插件系统集成到原生桌面应用中。本仓库提供官方未发布的 **Ubuntu Linux 社区构建版本**，由社区独立编译打包。

**⚠️ 本项目与 DeepSeek 不存在隶属、合作、授权或背书关系，仅为社区爱好者自发维护的开源编译项目。**

## 项目背景

官方 [dsh-desktop](https://github.com/anywhere-labs/dsh-desktop) 目前仅提供 Windows 和 macOS 版本。由于 Linux 用户数量庞大且官方暂无 Linux 支持计划，本项目基于官方开源源码独立编译了 Ubuntu 版本，方便 Linux 用户体验 DSH Desktop。

## 下载与安装

### 方式一：DEB 安装包（推荐）

```bash
# 1. 下载 deb 包
wget https://github.com/klzone/dsh-desktop-ubuntu/releases/download/dsh-desktop-linux-v2.0.11/dsh-plugin-desktop_2.0.11_amd64.deb

# 2. 安装
sudo dpkg -i dsh-plugin-desktop_2.0.11_amd64.deb
sudo apt install -f  # 自动修复依赖

# 3. 运行
dsh-plugin-desktop
```

### 方式二：直接运行目录版本

```bash
# 1. 下载并解压目录版本
wget https://github.com/klzone/dsh-desktop-ubuntu/releases/download/dsh-desktop-linux-v2.0.11/dsh-plugin-desktop_2.0.11_amd64-linux-unpacked.tar.xz
tar xf dsh-plugin-desktop_2.0.11_amd64-linux-unpacked.tar.xz

# 2. 运行
cd dsh-plugin-desktop_2.0.11_amd64-linux-unpacked
./dsh-plugin-desktop
```

### 桌面集成

deb 包自动创建：
- 📋 **应用菜单**：`/usr/share/applications/dsh-plugin-desktop.desktop`
- 🎨 **应用图标**：`/usr/share/icons/hicolor/1024x1024/apps/dsh-plugin-desktop.png`
- 📁 **安装目录**：`/opt/DSH Desktop/`

手动创建桌面快捷方式（目录版本用户）：
```bash
cp dsh-desktop.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Ubuntu 22.04+ / 24.04 / 26.04 LTS（AMD64 架构） |
| 内存 | 8GB+（推荐 16GB） |
| 磁盘 | 500MB+ 安装空间 |
| 依赖 | 自动通过 deb 包安装 |

## 功能特性

### ✅ 支持的功能
- 完整 Web UI（官方兼容性模式）
- 系统托盘
- 插件系统
- 会话管理
- 本地模型配置
- 终端集成
- 自动更新检测（仅检查，不自动下载）

### ❌ Linux 版限制
- 仅支持 **Compatibility 模式**（无 Extended/Enhanced 模式）
- 无自定义窗口材质（Acrylic/Mica 效果）
- 无桌面终端命令（`Open DSH Terminal` 功能不可用）
- 无自动更新功能（需手动下载新版本）
- 无 Windows PowerShell 沙箱

## 与官方版本对比

| 特性 | Windows | macOS | Ubuntu（本项目） |
|------|---------|-------|-----------------|
| 兼容性模式 | ✅ | ✅ | ✅ |
| 扩展模式 | ✅ | ✅ | ❌ |
| 增强模式 | ✅ | ✅ | ❌ |
| 系统托盘 | ✅ | ✅ | ✅ |
| 桌面终端 | ✅ | ✅ | ❌ |
| 自动更新 | ✅ | ✅ | ❌ |
| 窗口材质 | ✅ | ✅ | ❌ |

## 构建说明

本版本由 [Yvan](https://github.com/klzone) 基于官方 [dsh-desktop v2.0.11](https://github.com/anywhere-labs/dsh-desktop/releases) 源码独立编译：

```bash
# 构建环境
- Node.js 24.x
- Yarn 4.18.0 (Corepack)
- Electron Builder 26.15.7
- 目标：Linux x64 (Ubuntu 26.04.1 LTS)
```

构建过程中主要修改：
1. 在 `package.json` 中添加了 Linux 构建配置
2. 创建 `package-linux.ts` 打包脚本
3. 配置 deb 包元数据（依赖、图标、.desktop 文件）

## 常见问题

### 启动时提示 `libva` 错误
这是正常的 GPU 初始化警告，不影响使用。如需消除可添加 `--disable-gpu` 参数：
```bash
dsh-plugin-desktop --disable-gpu
```

### 沙箱相关错误
部分环境需要禁用沙箱：
```bash
dsh-plugin-desktop --no-sandbox
```

### 安装后找不到命令
确认已安装依赖：
```bash
sudo apt install -f
which dsh-plugin-desktop
```

## 许可证

本项目遵循 [MIT License](https://github.com/anywhere-labs/dsh-desktop/blob/master/LICENSE)，与上游项目保持一致。

## 联系方式

- 项目维护者：[Yvan](https://github.com/klzone)
- 原始项目：[anywhere-labs/dsh-desktop](https://github.com/anywhere-labs/dsh-desktop)
- 上游项目：[deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)

## 致谢

感谢 [DSH Desktop 社区团队](https://github.com/anywhere-labs) 提供的优秀开源项目。
