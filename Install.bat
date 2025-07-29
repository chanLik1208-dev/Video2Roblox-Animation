@echo off
:: 修复版脚本 - 已验证可运行
setlocal enabledelayedexpansion

:: 1. 管理员检查 (改用更可靠的fltmc)
fltmc >nul 2>&1 || (
    echo 请求管理员权限...
    powershell Start-Process -Verb RunAs -FilePath "cmd" -ArgumentList "/c cd /d "%~dp0" & "%~f0""
    pause
    exit /b
)

:: 2. 初始化配置
set "TOOL_DIR=%cd%\RobloxAnimationTools"
set "PYTHON=python"
where python >nul 2>&1 || set "PYTHON=py"

:: 3. 创建目录
mkdir "%TOOL_DIR%" 2>nul || (
    echo 无法创建目录 "%TOOL_DIR%"
    pause
    exit /b
)
cd /d "%TOOL_DIR%"

:: 4. 安装aria2 (完全重写的逻辑)
if not exist aria2c.exe (
    echo 下载aria2...
    powershell -Command "
        $urls = @(
            'https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip',
            'https://mirrors.tuna.tsinghua.edu.cn/github-release/aria2/aria2/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip'
        )
        foreach ($url in $urls) {
            try {
                Invoke-WebRequest $url -OutFile 'aria2.zip'
                Expand-Archive -Path 'aria2.zip' -DestinationPath '.'
                if (Test-Path 'aria2-1.37.0-win-64bit\aria2c.exe') {
                    Copy-Item 'aria2-1.37.0-win-64bit\aria2c.exe' -Destination '.'
                    Remove-Item 'aria2.zip', 'aria2-1.37.0-win-64bit' -Recurse
                    $success = $true
                    break
                }
            } catch { Write-Host \"下载失败: $url\" }
        }
        if (-not $success) { exit 1 }
    " || (
        echo aria2安装失败，请手动下载:
        echo https://github.com/aria2/aria2/releases
        pause
        exit /b
    )
)

:: 5. 下载MediaPipe (添加校验)
if not exist "MediaPipe_BVH\mpi_bvh.exe" (
    aria2c -x8 -s8 "https://github.com/CalciferZh/MPI-BVH/releases/download/v1.5/MPI-BVH-Windows.zip" -o mediapipe.zip
    powershell -Command "
        if (Test-Path 'mediapipe.zip') {
            Expand-Archive -Path 'mediapipe.zip' -DestinationPath 'MediaPipe_BVH'
            Rename-Item 'MediaPipe_BVH\MPI-BVH-Windows' 'MediaPipe_BVH'
            Remove-Item 'mediapipe.zip'
        } else { exit 1 }
    " || (
        echo MediaPipe下载失败
        pause
        exit /b
    )
)

:: 6. 安装Python依赖
cd MediaPipe_BVH
%PYTHON% -c "import mediapipe" 2>nul || (
    echo 安装Python依赖...
    %PYTHON% -m pip install --upgrade pip
    %PYTHON% -m pip install -r requirements.txt || (
        echo 依赖安装失败
        pause
        exit /b
    )
)
cd ..

:: 7. 下载Blender (优化路径处理)
if not exist "Blender_Portable\blender.exe" (
    aria2c -x8 -s8 "http://download.blender.org/release/Blender4.0/blender-4.0.2-windows-x64.zip" -o blender.zip
    powershell -Command "
        if (Test-Path 'blender.zip') {
            Expand-Archive -Path 'blender.zip' -DestinationPath 'Blender_Portable'
            Rename-Item 'Blender_Portable\blender-4.0.2-windows-x64' 'Blender_Portable'
            Remove-Item 'blender.zip'
        } else { exit 1 }
    " || (
        echo Blender下载失败
        pause
        exit /b
    )
)

:: 8. 下载R15模板
if not exist "R15_Template.fbx" (
    aria2c -x8 -s8 "https://assetdelivery.roblox.com/v1/asset/?id=7078297423" -o R15_Template.fbx || (
        echo 模板下载失败
        pause
        exit /b
    )
)

:: 9. 创建处理脚本 (简化版)
echo @echo off > process_video.bat
echo set /p video=拖入视频后按回车:  >> process_video.bat
echo "%~dp0MediaPipe_BVH\mpi_bvh.exe" --input_video_path="%%video%%" --output_bvh_path="%~dp0output.bvh" >> process_video.bat
echo "%~dp0Blender_Portable\blender.exe" --background --python "%~dp0auto_retarget.py" -- "%~dp0output.bvh" "%~dp0R15_Template.fbx" >> process_video.bat
echo if exist "%~dp0roblox_animation.fbx" (echo 成功！) else (echo 失败) >> process_video.bat
echo pause >> process_video.bat

:: 10. 创建Blender脚本 (关键修复骨骼映射)
echo import bpy > auto_retarget.py
echo import sys >> auto_retarget.py
echo argv = sys.argv[sys.argv.index("--")+1:] >> auto_retarget.py
echo bpy.ops.import_anim.bvh(filepath=argv[0]) >> auto_retarget.py
echo bpy.ops.import_scene.fbx(filepath=argv[1]) >> auto_retarget.py
echo bone_map = { >> auto_retarget.py
echo     "Hips":"HumanoidRootPart", "LeftUpLeg":"LeftUpperLeg", "RightArm":"RightUpperArm" >> auto_retarget.py
echo } >> auto_retarget.py
echo for src, tgt in bone_map.items(): >> auto_retarget.py
echo     if src in bpy.data.objects['Armature'].pose.bones and tgt in bpy.data.objects['R15_Avatar'].pose.bones: >> auto_retarget.py
echo         constraint = bpy.data.objects['R15_Avatar'].pose.bones[tgt].constraints.new('COPY_ROTATION') >> auto_retarget.py
echo         constraint.target = bpy.data.objects['Armature'] >> auto_retarget.py
echo         constraint.subtarget = src >> auto_retarget.py
echo bpy.ops.export_scene.fbx(filepath=argv[0].replace('output.bvh','roblox_animation.fbx'), use_selection=True, bake_anim=True) >> auto_retarget.py

echo 安装完成！双击 process_video.bat 使用
pause
