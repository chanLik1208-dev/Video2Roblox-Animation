#!/bin/bash
# Roblox舞蹈动画转换工具 (macOS全自动版)
# 功能: 自动安装依赖 + 视频转Roblox动画
# 依赖: Homebrew (用于安装ffmpeg/blender), Python3 (可选)

# --- 配置区域 ---
OUTPUT_DIR="$HOME/Desktop/Roblox_Animation_Export"
PYTHON_AI_SCRIPT="https://example.com/your_ai_pose_script.py"  # 替换为你的AI脚本URL

# --- 函数定义 ---
function install_dependencies() {
    echo "[1/4] 检查并安装依赖..."
    
    # 检查Homebrew (macOS包管理器)
    if ! command -v brew &> /dev/null; then
        echo "安装Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    fi

    # 安装ffmpeg
    if ! command -v ffmpeg &> /dev/null; then
        brew install ffmpeg
    fi

    # 安装Blender (通过Homebrew Cask)
    if [ ! -d "/Applications/Blender.app" ]; then
        brew install --cask blender
    fi

    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        brew install python
    fi

    # 安装Python库 (可选)
    if [ -n "$PYTHON_AI_SCRIPT" ]; then
        pip3 install numpy opencv-python tensorflow
    fi
}

function select_video() {
    echo "[2/4] 请选择视频文件..."
    VIDEO_PATH=$(osascript -e 'tell app "System Events" to return POSIX path of (choose file of type {"public.movie", "mp4", "mov"} with prompt "选择舞蹈视频")')
    if [ -z "$VIDEO_PATH" ]; then
        echo "错误: 未选择文件。"
        exit 1
    fi
}

function process_animation() {
    echo "[3/4] 处理视频..."
    mkdir -p "$OUTPUT_DIR/frames"
    
    # 提取视频帧
    ffmpeg -i "$VIDEO_PATH" -vf fps=30 "$OUTPUT_DIR/frames/frame_%04d.png"

    # (可选) 调用AI动作捕捉
    if [ -n "$PYTHON_AI_SCRIPT" ]; then
        echo "正在运行AI动作捕捉..."
        curl -o "$OUTPUT_DIR/ai_pose_script.py" "$PYTHON_AI_SCRIPT"
        python3 "$OUTPUT_DIR/ai_pose_script.py" --input "$OUTPUT_DIR/frames" --output "$OUTPUT_DIR/animation.bvh"
    else
        echo "跳过AI步骤，请手动处理帧。"
    fi

    # 转换BVH到FBX (通过Blender)
    if [ -f "$OUTPUT_DIR/animation.bvh" ]; then
        echo "正在转换格式..."
        /Applications/Blender.app/Contents/MacOS/Blender --background --python-expr '
import bpy
bpy.ops.import_anim.bvh(filepath="'"$OUTPUT_DIR/animation.bvh"'")
bpy.ops.export_scene.fbx(filepath="'"$OUTPUT_DIR/roblox_animation.fbx"'", use_selection=True)'
    fi
}

function cleanup() {
    echo "[4/4] 清理临时文件..."
    rm -rf "$OUTPUT_DIR/frames"
    if [ -f "$OUTPUT_DIR/ai_pose_script.py" ]; then
        rm "$OUTPUT_DIR/ai_pose_script.py"
    fi
}

# --- 主流程 ---
install_dependencies
select_video
process_animation
cleanup

# 完成提示
osascript -e 'display notification "处理完成！FBX文件已保存到桌面。" with title "Roblox动画转换"'
open "$OUTPUT_DIR"