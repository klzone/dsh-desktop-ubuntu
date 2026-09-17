#!/bin/bash
# DSH Desktop Ubuntu 一键构建脚本
# 用法: ./build-ubuntu.sh [版本号]
# 示例: ./build-ubuntu.sh 2.0.12

set -e

# ============ 配置区 ============
SOURCE_REPO="https://github.com/anywhere-labs/dsh-desktop.git"
WORK_DIR="/tmp/dsh-desktop-build-$$"
OUTPUT_DIR="$WORK_DIR/output"
GH_REPO="klzone/dsh-desktop-ubuntu"
GH_TOKEN="${GH_TOKEN:?请设置 GH_TOKEN 环境变量}"
ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"

# 可选：指定版本号，默认从上游 package.json 读取
VERSION="${1:-}"

# ============ 工具检查 ============
check_prerequisites() {
    echo "=== 检查构建环境 ==="
    command -v git &>/dev/null || { echo "错误: 需要 git"; exit 1; }
    command -v node &>/dev/null || { echo "错误: 需要 node (22.19+ 或 24.x)"; exit 1; }
    command -v python3 &>/dev/null || { echo "错误: 需要 python3"; exit 1; }
    command -v dpkg-deb &>/dev/null || { echo "错误: 需要 dpkg-deb (Ubuntu 自带)"; exit 1; }

    local node_major=$(node -v | sed 's/v\([0-9]*\).*/\1/')
    local node_minor=$(node -v | sed 's/v[0-9]*\.\([0-9]*\).*/\1/')
    if [[ "$node_major" -lt 22 ]] || { [[ "$node_major" -eq 22 ]] && [[ "$node_minor" -lt 19 ]]; }; then
        echo "错误: Node.js 版本过低 (当前: $(node -v))，需要 22.19+ 或 24.x"
        exit 1
    fi

    echo "Node.js: $(node -v) ✓"
    echo "Python: $(python3 --version) ✓"
    echo ""
}

# ============ 拉取源码 ============
fetch_source() {
    echo "=== 拉取 DSH Desktop 源码 ==="
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    git clone --depth 1 "$SOURCE_REPO" "$WORK_DIR/source"
    cd "$WORK_DIR/source"
    git submodule update --init --recursive
    echo "源码版本: $(git log -1 --oneline)"

    if [[ -z "$VERSION" ]]; then
        VERSION=$(jq -r '.version' dsh-plugin-desktop/package.json 2>/dev/null || \
                  python3 -c "import json; print(json.load(open('dsh-plugin-desktop/package.json'))['version'])")
    fi
    echo "构建版本: $VERSION"
}

# ============ 安装依赖 ============
install_deps() {
    echo "=== 安装依赖 ==="
    cd "$WORK_DIR/source"
    export ELECTRON_MIRROR
    corepack enable 2>/dev/null || true
    corepack yarn install --immutable 2>&1 | tail -5
}

# ============ 构建代码 ============
build_code() {
    echo "=== 构建项目代码 ==="
    cd "$WORK_DIR/source/dsh-plugin-desktop"
    export ELECTRON_MIRROR

    # 生成图标
    node scripts/generate-windows-app-icon.mjs
    node scripts/generate-mac-app-icon.mjs
    node scripts/generate-tray-icons.mjs

    # 编译 TypeScript
    echo "编译中..."
    corepack yarn build 2>&1 | tail -3

    # 准备 fs-ext（跳过编译，使用预构建）
    echo "准备原生模块..."
    # 复制 fs-ext 预构建文件到正确位置
    mkdir -p node_modules/fs-ext/prebuilds/linux-x64/
    if [[ -f node_modules/fs-ext/build/Release/fs_ext.node ]]; then
        cp node_modules/fs-ext/build/Release/fs_ext.node node_modules/fs-ext/prebuilds/linux-x64/electron.abi148.node
    fi
    echo "原生模块准备完成"
}

# ============ 打包 ============
package() {
    echo "=== 打包 ==="
    cd "$WORK_DIR/source/dsh-plugin-desktop"
    export ELECTRON_MIRROR

    # 跳过 afterAllArtifactBuild 验证（需要真正编译 fs-ext）
    npx electron-builder --linux dir deb --publish never \
        --config.afterAllArtifactBuild="" 2>&1 | grep -E "•|⨯|Error" | head -20

    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"

    # 压缩目录版本
    echo "压缩目录版本..."
    tar cJf "$OUTPUT_DIR/dsh-plugin-desktop_${VERSION}_amd64-linux-unpacked.tar.xz" \
        -C dist linux-unpacked/

    # 复制 deb 包
    cp "dist/dsh-plugin-desktop_${VERSION}_amd64.deb" "$OUTPUT_DIR/"

    echo "产物:"
    ls -lh "$OUTPUT_DIR/"
}

# ============ 上传 GitHub ============
upload_release() {
    echo "=== 上传到 GitHub ==="
    local release_url="https://api.github.com/repos/${GH_REPO}/releases"
    local tag="dsh-desktop-linux-v${VERSION}"

    # 检查 release 是否已存在
    local release_info
    release_info=$(curl -s -H "Authorization: token $GH_TOKEN" \
        "https://api.github.com/repos/${GH_REPO}/releases/tags/${tag}")

    if echo "$release_info" | grep -q '"html_url"'; then
        echo "Release 已存在，删除旧附件..."
        local assets
        assets=$(echo "$release_info" | jq -c '.assets[]')
        while IFS= read -r asset; do
            local asset_id=$(echo "$asset" | jq -r '.id')
            curl -s -X DELETE -H "Authorization: token $GH_TOKEN" \
                "https://api.github.com/repos/${GH_REPO}/releases/assets/${asset_id}" &>/dev/null
        done <<< "$assets"
        # 删除 tag
        curl -s -X DELETE -H "Authorization: token $GH_TOKEN" \
            "https://api.github.com/repos/${GH_REPO}/git/refs/tags/${tag}" &>/dev/null
    fi

    # 创建新 Release
    echo "创建 Release: ${tag}..."
    release_info=$(curl -s -X POST -H "Authorization: token $GH_TOKEN" \
        -H "Content-Type: application/json" \
        "$release_url" \
        -d "{
            \"tag_name\": \"${tag}\",
            \"name\": \"DSH Desktop ${VERSION} for Ubuntu Linux\",
            \"body\": \"## DSH Desktop ${VERSION} for Ubuntu (社区构建)\\n\\n基于 [dsh-desktop](https://github.com/anywhere-labs/dsh-desktop) 为 Ubuntu Linux 编译的版本。\\n\\n### 安装\\n\`\`\`bash\\nwget dsh-plugin-desktop_${VERSION}_amd64.deb\\nsudo dpkg -i dsh-plugin-desktop_${VERSION}_amd64.deb\\nsudo apt install -f\\n\`\`\`\\n\\n### 说明\\n- 仅支持 Compatibility 模式\\n- 无自动更新功能\\n- 适用于 Ubuntu 22.04+ LTS\\n- 构建日期：$(date +%Y-%m-%d)\",
            \"draft\": false,
            \"prerelease\": false
        }")

    local release_id
    release_id=$(echo "$release_info" | jq -r '.id')
    local upload_url
    upload_url=$(echo "$release_info" | jq -r '.upload_url' | sed 's/{?name,label}//')

    # 上传附件
    echo "上传 deb 包..."
    curl -s -X POST -H "Authorization: token $GH_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        "${upload_url}?name=dsh-plugin-desktop_${VERSION}_amd64.deb" \
        --data-binary "@${OUTPUT_DIR}/dsh-plugin-desktop_${VERSION}_amd64.deb" &>/dev/null

    echo "上传目录版本..."
    curl -s -X POST -H "Authorization: token $GH_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        "${upload_url}?name=dsh-plugin-desktop_${VERSION}_amd64-linux-unpacked.tar.xz" \
        --data-binary "@${OUTPUT_DIR}/dsh-plugin-desktop_${VERSION}_amd64-linux-unpacked.tar.xz" &>/dev/null

    echo ""
    echo "=== 构建完成！==="
    echo "Release: https://github.com/${GH_REPO}/releases/tag/${tag}"
    echo ""
    echo "安装命令:"
    echo "  wget https://github.com/${GH_REPO}/releases/download/${tag}/dsh-plugin-desktop_${VERSION}_amd64.deb"
    echo "  sudo dpkg -i dsh-plugin-desktop_${VERSION}_amd64.deb && sudo apt install -f"

    # 清理
    rm -rf "$WORK_DIR"
}

# ============ 主流程 ============
main() {
    echo "╔══════════════════════════════════════╗"
    echo "║  DSH Desktop Ubuntu 一键构建工具     ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
    check_prerequisites
    fetch_source
    install_deps
    build_code
    package
    upload_release
}

main "$@"
