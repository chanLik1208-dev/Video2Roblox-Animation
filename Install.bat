@echo off
:: ==============================================
:: Roblox动画工具链安装脚本（终极修复版）
:: 特点：
:: 1. 完全不用aria2，使用PowerShell原生下载
:: 2. 每个步骤都有错误检测和重试机制
:: 3. 实时显示操作进度和状态
:: ==============================================

:: 初始化配置
setlocal enabledelayedexpansion
set "VERSION=3.1"
set "TOOL_DIR=%cd%\RobloxAnimationTools"
set "PYTHON=python"
set "ERROR_FLAG=0"

:: 检查管理员权限
:check_admin
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    echo [权限检测] 正在请求管理员权限...
    powershell -Command "Start-Process -Verb RunAs -FilePath 'cmd.exe' -ArgumentList '/c cd /d \"%~dp0\" & \"%~f0\"'"
    exit /b
)

:: 创建工具目录
:create_dir
echo [目录准备] 正在创建工作目录...
if not exist "%TOOL_DIR%" (
    mkdir "%TOOL_DIR%" 2>nul || (
        echo [错误] 无法创建目录 "%TOOL_DIR%"
        echo 可能原因：
        echo 1. 路径权限不足
        echo 2. 磁盘已满
        set "ERROR_FLAG=1"
        goto :error_handling
    )
)
cd /d "%TOOL_DIR%"

:: 下载MediaPipe工具
:download_mediapipe
echo [1/4] 正在下载动作捕捉工具...
if not exist "MediaPipe_BVH\mpi_bvh.exe" (
    echo 尝试从GitHub下载...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; $url='https://github.com/CalciferZh/MPI-BVH/releases/download/v1.5/MPI-BVH-Windows.zip'; $out='%TOOL_DIR%\mediapipe.zip'; try { (New-Object Net.WebClient).DownloadFile($url, $out); if (Test-Path $out) { Expand-Archive -Path $out -DestinationPath '%TOOL_DIR%'; Rename-Item '%TOOL_DIR%\MPI-BVH-Windows' 'MediaPipe_BVH'; Remove-Item $out } else { exit 1 } } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo [重试] 正在使用备用镜像...
        powershell -Command "$ProgressPreference = 'SilentlyContinue'; $url='https://ghproxy.com/https://github.com/CalciferZh/MPI-BVH/releases/download/v1.5/MPI-BVH-Windows.zip'; $out='%TOOL_DIR%\mediapipe.zip'; try { (New-Object Net.WebClient).DownloadFile($url, $out); if (Test-Path $out) { Expand-Archive -Path $out -DestinationPath '%TOOL_DIR%'; Rename-Item '%TOOL_DIR%\MPI-BVH-Windows' 'MediaPipe_BVH'; Remove-Item $out } else { exit 1 } } catch { exit 1 }"
        if %errorlevel% neq 0 (
            set "ERROR_FLAG=1"
            echo [错误] MediaPipe下载失败
            echo 请手动下载解压：
            echo https://github.com/CalciferZh/MPI-BVH/releases
            echo 解压到 %TOOL_DIR%\MediaPipe_BVH
            goto :error_handling
        )
    )
)

:: 安装Python依赖
:install_deps
echo [2/4] 正在安装Python依赖...
cd MediaPipe_BVH
%PYTHON% -c "import mediapipe" 2>nul
if %errorlevel% neq 0 (
    echo 正在检查Python版本...
    %PYTHON% --version || (
        echo [错误] Python未安装或未添加到PATH
        echo 从 https://www.python.org/downloads/ 安装并勾选"Add to PATH"
        set "ERROR_FLAG=1"
        goto :error_handling
    )
    
    echo 正在安装依赖...
    %PYTHON% -m pip install --upgrade pip || (
        echo [错误] pip升级失败
        set "ERROR_FLAG=1"
        goto :error_handling
    )
    
    %PYTHON% -m pip install -r requirements.txt || (
        echo [错误] 依赖安装失败
        echo 尝试使用国内镜像...
        %PYTHON% -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple || (
            set "ERROR_FLAG=1"
            goto :error_handling
        )
    )
)
cd ..

:: 下载Blender便携版
:download_blender
echo [3/4] 正在下载Blender...
if not exist "Blender_Portable\blender.exe" (
    echo 尝试从官方镜像下载...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; $url='http://download.blender.org/release/Blender4.0/blender-4.0.2-windows-x64.zip'; $out='%TOOL_DIR%\blender.zip'; try { (New-Object Net.WebClient).DownloadFile($url, $out); if (Test-Path $out) { Expand-Archive -Path $out -DestinationPath '%TOOL_DIR%'; Rename-Item '%TOOL_DIR%\blender-4.0.2-windows-x64' 'Blender_Portable'; Remove-Item $out } else { exit 1 } } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo [重试] 正在使用荷兰镜像...
        powershell -Command "$ProgressPreference = 'SilentlyContinue'; $url='https://ftp.nluug.nl/pub/graphics/blender/release/Blender4.0/blender-4.0.2-windows-x64.zip'; $out='%TOOL_DIR%\blender.zip'; try { (New-Object Net.WebClient).DownloadFile($url, $out); if (Test-Path $out) { Expand-Archive -Path $out -DestinationPath '%TOOL_DIR%'; Rename-Item '%TOOL_DIR%\blender-4.0.2-windows-x64' 'Blender_Portable'; Remove-Item $out } else { exit 1 } } catch { exit 1 }"
        if %errorlevel% neq 0 (
            set "ERROR_FLAG=1"
            echo [错误] Blender下载失败
            echo 请手动下载解压：
            echo https://www.blender.org/download/
            echo 解压到 %TOOL_DIR%\Blender_Portable
            goto :error_handling
        )
    )
)

:: 下载Roblox模板
:download_template
echo [4/4] 正在下载Roblox模板...
if not exist "R15_Template.fbx" (
    echo 尝试从Roblox CDN下载...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; $url='https://assetdelivery.roblox.com/v1/asset/?id=7078297423'; $out='%TOOL_DIR%\R15_Template.fbx'; try { (New-Object Net.WebClient).DownloadFile($url, $out) } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo [重试] 正在使用GitHub源...
        powershell -Command "$ProgressPreference = 'SilentlyContinue'; $url='https://github.com/Roblox/avatar/raw/main/templates/R15Template.fbx'; $out='%TOOL_DIR%\R15_Template.fbx'; try { (New-Object Net.WebClient).DownloadFile($url, $out) } catch { exit 1 }"
        if %errorlevel% neq 0 (
            set "ERROR_FLAG=1"
            echo [警告] 模板下载失败（不影响基础功能）
            echo 后续需要手动放置R15_Template.fbx到工具目录
        )
    )
)

:: 创建处理脚本
:create_scripts
echo 正在创建处理脚本...
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo echo 视频转Roblox动画工具
    echo set /p "video=请拖入视频文件后按回车: "
    echo if not exist "!video!" (
    echo     echo 错误：文件不存在
    echo     pause
    echo     exit /b
    echo )
    echo echo 正在提取骨骼动作...
    echo "%TOOL_DIR%\MediaPipe_BVH\mpi_bvh.exe" --input_video_path="!video!" --output_bvh_path="%TOOL_DIR%\output.bvh" || (
    echo     echo 错误：动作提取失败
    echo     pause
    echo     exit /b
    echo )
    echo echo 正在转换到Roblox骨骼...
    echo "%TOOL_DIR%\Blender_Portable\blender.exe" --background --python "%TOOL_DIR%\auto_retarget.py" -- "%TOOL_DIR%\output.bvh" "%TOOL_DIR%\R15_Template.fbx" || (
    echo     echo 错误：骨骼转换失败
    echo     pause
    echo     exit /b
    echo )
    echo if exist "%TOOL_DIR%\roblox_animation.fbx" (
    echo     echo 转换成功！文件已保存到:
    echo     echo %TOOL_DIR%\roblox_animation.fbx
    echo ) else (
    echo     echo 错误：未生成输出文件
    echo )
    echo pause
) > "%TOOL_DIR%\process_video.bat"

(
    echo import bpy
    echo import sys
    echo argv = sys.argv[sys.argv.index("--")+1:]
    echo bpy.ops.import_anim.bvh(filepath=argv[0])
    echo bpy.ops.import_scene.fbx(filepath=argv[1])
    echo bone_map = {
    echo     "Hips":"HumanoidRootPart",
    echo     "LeftUpLeg":"LeftUpperLeg", 
    echo     "RightArm":"RightUpperArm",
    echo     "LeftArm":"LeftUpperArm",
    echo     "RightUpLeg":"RightUpperLeg"
    echo }
    echo for src, tgt in bone_map.items():
    echo     if src in bpy.data.objects['Armature'].pose.bones and tgt in bpy.data.objects['R15_Avatar'].pose.bones:
    echo         constraint = bpy.data.objects['R15_Avatar'].pose.bones[tgt].constraints.new('COPY_ROTATION')
    echo         constraint.target = bpy.data.objects['Armature']
    echo         constraint.subtarget = src
    echo bpy.ops.export_scene.fbx(
    echo     filepath=argv[0].replace('output.bvh','roblox_animation.fbx'),
    echo     use_selection=True,
    echo     bake_anim=True,
    echo     add_leaf_bones=False
    echo )
) > "%TOOL_DIR%\auto_retarget.py"

:: 完成检查
:verify
echo 正在验证安装...
if not exist "%TOOL_DIR%\MediaPipe_BVH\mpi_bvh.exe" (
    echo [错误] MediaPipe工具缺失
    set "ERROR_FLAG=1"
)
if not exist "%TOOL_DIR%\Blender_Portable\blender.exe" (
    echo [错误] Blender缺失
    set "ERROR_FLAG=1"
)
%PYTHON% -c "import mediapipe" 2>nul || (
    echo [错误] Python依赖未正确安装
    set "ERROR_FLAG=1"
)

:: 错误处理
:error_handling
if %ERROR_FLAG% equ 0 (
    echo ==============================================
    echo 安装成功完成！
    echo 使用方法：
    echo 1. 双击 %TOOL_DIR%\process_video.bat
    echo 2. 拖入视频文件
    echo 3. 等待处理完成
    echo ==============================================
) else (
    echo ==============================================
    echo 安装过程中出现错误！
    echo 已尝试自动修复但未完全解决
    echo 请根据上方提示手动处理
    echo ==============================================
)
pause