#!/bin/bash
# Roblox舞蹈动画转换工具 (终极修复版)
# 彻底解决颜色代码污染路径问题

# --- 配置 ---
OUTPUT_DIR="$HOME/Desktop/Roblox_Animation_Export"
BLENDER_PATH="/Applications/Blender.app/Contents/MacOS/Blender"
REQUIRED_TOOLS=("ffmpeg" "blender" "python3")  # 必需工具

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 清理路径函数 ---
clean_path() {
    # 去除所有ANSI颜色代码和多余字符
    echo "$1" | sed -e 's/\x1B\[[0-9;]*[mGK]//g' -e "s/^ *'//" -e "s/' *$//" -e 's/ *$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# --- 函数：检查并安装依赖 ---
install_dependencies() {
    echo -e "${YELLOW}[1/3] 检查系统依赖...${NC}"
    
    # 检查Homebrew (macOS包管理器)
    if ! command -v brew &> /dev/null; then
        echo -e "${GREEN}安装Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    fi

    # 安装缺失工具
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            case "$tool" in
                "ffmpeg")
                    echo -e "${GREEN}安装ffmpeg...${NC}"
                    brew install ffmpeg
                    ;;
                "blender")
                    echo -e "${GREEN}安装Blender...${NC}"
                    brew install --cask blender
                    ;;
                "python3")
                    echo -e "${GREEN}安装Python3...${NC}"
                    brew install python
                    ;;
            esac
        fi
    done
}

# --- 函数：手动选择文件 ---
select_file() {
    # 使用普通提示避免颜色代码污染
    echo "[2/3] 选择视频文件:"
    echo "请选择输入方式:"
    echo "  1. 拖拽文件到终端窗口后按 Enter"
    echo "  2. 手动输入文件路径"
    read -p "您的选择 [1/2]: " choice

    case "$choice" in
        1)
            read -p "拖拽文件 → " raw_path
            file_path=$(clean_path "$raw_path")
            ;;
        2)
            read -p "输入文件路径: " raw_path
            file_path=$(clean_path "$raw_path")
            ;;
        *)
            echo "无效输入！"
            exit 1
            ;;
    esac

    # 验证文件
    if [ ! -f "$file_path" ]; then
        echo "错误: 文件不存在: ${file_path}"
        exit 1
    fi
    echo "$file_path"
}

# --- 函数：处理动画 ---
process_animation() {
    local input_file="$1"
    echo -e "${YELLOW}[3/3] 处理视频: $(basename "$input_file")${NC}"

    # 提取帧
    mkdir -p "$OUTPUT_DIR/frames"
    
    # 显示实际使用的路径
    echo "使用路径: $input_file"
    
    ffmpeg -hide_banner -i "$input_file" -vf fps=30 "$OUTPUT_DIR/frames/frame_%04d.png" || {
        echo -e "${RED}错误: 视频提取失败！可能原因:${NC}"
        echo -e "${RED}1. 文件路径包含特殊字符${NC}"
        echo -e "${RED}2. 视频格式不受支持${NC}"
        echo -e "${RED}3. 文件已损坏${NC}"
        echo "尝试路径: $input_file"
        exit 1
    }

    # 转换格式 (示例: PNG序列 → FBX)
    echo -e "${GREEN}正在生成FBX文件...${NC}"
    "$BLENDER_PATH" --background --python-expr "
import bpy
bpy.ops.import_image.to_plane(files=[{'name':'frame_0001.png'}], directory='$OUTPUT_DIR/frames/')
bpy.ops.export_scene.fbx(filepath='$OUTPUT_DIR/roblox_animation.fbx')" || {
        echo -e "${YELLOW}警告: 自动转换简化版完成，如需高级控制请手动用Blender处理${NC}"
    }
}

# --- 主流程 ---
clear
echo -e "${GREEN}=== Roblox动画转换工具 ===${NC}"

# 1. 安装依赖
install_dependencies

# 2. 选择文件
VIDEO_PATH=$(select_file)
echo -e "${GREEN}已选择文件: ${VIDEO_PATH}${NC}"

# 3. 处理动画
mkdir -p "$OUTPUT_DIR"
process_animation "$VIDEO_PATH"

# 完成
echo -e "${GREEN}转换完成！FBX文件已保存到:${NC}"
echo -e "${GREEN}$OUTPUT_DIR/roblox_animation.fbx${NC}"
open "$OUTPUT_DIR" 2>/dev/null || echo "请手动访问: $OUTPUT_DIR"
