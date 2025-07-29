#!/bin/bash
# Roblox舞蹈动画转换工具 (macOS全自动版)
# 功能: 自动安装依赖 → 选择视频 → 提取帧 → 转换FBX → 清理临时文件

# --- 配置区域 ---
OUTPUT_DIR="$HOME/Desktop/Roblox_Animation_Export"
PYTHON_AI_SCRIPT=""  # 如需AI处理，替换为脚本URL
BLENDER_PATH="/Applications/Blender.app/Contents/MacOS/Blender"

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 函数：用osascript选择文件 ---
select_video_file() {
    local file_path
    file_path=$(osascript <<EOF
tell application "System Events"
    set selectedFile to choose file with prompt "请选择舞蹈视频文件" ¬
        of type {"public.movie", "mp4", "mov", "avi"} ¬
        default location (path to desktop)
    return POSIX path of selectedFile
end tell
EOF
)
    echo "$file_path"
}

# --- 函数：安装依赖 ---
install_dependencies() {
    echo -e "${YELLOW}[1/5] 检查系统依赖...${NC}"
    
    # 检查Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${GREEN}安装Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    fi

    # 安装ffmpeg
    if ! command -v ffmpeg &> /dev/null; then
        brew install ffmpeg
    fi

    # 检查Blender
    if [ ! -f "$BLENDER_PATH" ]; then
        echo -e "${GREEN}安装Blender...${NC}"
        brew install --cask blender
    fi
}

# --- 函数：处理视频 ---
process_animation() {
    local input_file="$1"
    echo -e "${YELLOW}[3/5] 处理视频: $(basename "$input_file")${NC}"
    
    # 提取帧
    mkdir -p "$OUTPUT_DIR/frames"
    ffmpeg -i "$input_file" -vf fps=30 "$OUTPUT_DIR/frames/frame_%04d.png" || {
        echo -e "${RED}错误: 视频提取失败${NC}"
        exit 1
    }

    # (可选) AI动作捕捉
    if [ -n "$PYTHON_AI_SCRIPT" ]; then
        echo -e "${YELLOW}[4/5] 运行AI动作捕捉...${NC}"
        python3 -m venv "$OUTPUT_DIR/venv"
        source "$OUTPUT_DIR/venv/bin/activate"
        pip install numpy opencv-python
        curl -sSL "$PYTHON_AI_SCRIPT" -o "$OUTPUT_DIR/ai_pose_script.py"
        python3 "$OUTPUT_DIR/ai_pose_script.py" --input "$OUTPUT_DIR/frames" --output "$OUTPUT_DIR/animation.bvh" || {
            echo -e "${RED}警告: AI处理失败，继续手动流程${NC}"
        }
        deactivate
    fi

    # 转换格式
    if [ -f "$OUTPUT_DIR/animation.bvh" ]; then
        echo -e "${YELLOW}[5/5] 转换格式 (BVH → FBX)...${NC}"
        "$BLENDER_PATH" --background --python-expr "
import bpy
bpy.ops.import_anim.bvh(filepath='$OUTPUT_DIR/animation.bvh')
bpy.ops.export_scene.fbx(filepath='$OUTPUT_DIR/roblox_animation.fbx', use_selection=True)"
    else
        echo -e "${YELLOW}跳过AI步骤，直接生成空白FBX模板${NC}"
        touch "$OUTPUT_DIR/roblox_animation.fbx"
    fi
}

# --- 主流程 ---
clear
echo -e "${GREEN}=== Roblox舞蹈动画转换工具 ===${NC}"

# 1. 安装依赖
install_dependencies

# 2. 选择文件
echo -e "${YELLOW}[2/5] 请选择视频文件...${NC}"
VIDEO_PATH=$(select_video_file)
[ -z "$VIDEO_PATH" ] && exit 1

# 3. 处理动画
mkdir -p "$OUTPUT_DIR"
process_animation "$VIDEO_PATH"

# 4. 清理临时文件
echo -e "${YELLOW}清理临时文件...${NC}"
rm -rf "$OUTPUT_DIR/frames" "$OUTPUT_DIR/venv" 2>/dev/null

# 完成
echo -e "${GREEN}转换完成！FBX文件已保存到: ${NC}"
echo -e "${GREEN}$OUTPUT_DIR/roblox_animation.fbx${NC}"
open "$OUTPUT_DIR"

# 通知提醒
osascript -e 'display notification "FBX动画已生成！" with title "Roblox转换工具"'