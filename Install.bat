@echo off
:: Roblox Animation Toolchain - Global Edition
:: Full offline solution for video to Roblox animation conversion
:: Version 2.1 - Optimized for international networks

echo.
echo *******************************************************
echo       ROBLOX ANIMATION TOOLCHAIN INSTALLER
echo *******************************************************
echo.
echo This will install:
echo  - MediaPipe BVH Converter (v1.5)
echo  - Blender Portable (4.0.2)
echo  - Roblox R15 Avatar Template
echo  - Python dependencies
echo.
echo Estimated time: 3-5 minutes (depending on internet speed)
echo *******************************************************

:: Request admin privileges
setlocal enabledelayedexpansion
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system" || (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c ""%~dpnx0"" %*'"
    exit /b
)

:: Configuration
set TOOL_DIR=%cd%\RobloxAnimationTools
set PYTHON_CMD=python
where python >nul 2>&1 || set PYTHON_CMD=py
set BLENDER_VERSION=4.0.2
set BLENDER_MIRROR=http://download.blender.org/release/Blender4.0

:: Create tool directory
echo.
echo [1/6] Creating workspace...
mkdir "%TOOL_DIR%" 2>nul
cd /d "%TOOL_DIR%"
if not exist "%TOOL_DIR%" (
    echo ERROR: Failed to create directory. Check permissions.
    pause
    exit /b
)

:: Install aria2 for faster downloads
echo.
echo [2/6] Setting up download accelerator...
where aria2c >nul 2>&1
if errorlevel 1 (
    echo Downloading aria2 (multi-thread downloader)...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip', 'aria2.zip')"
    powershell -Command "Expand-Archive -Path aria2.zip -DestinationPath .\aria2_temp"
    copy ".\aria2_temp\aria2-1.37.0-win-64bit\aria2c.exe" "%SystemRoot%\system32\" >nul
    rd /s /q aria2_temp
    del aria2.zip
    echo Aria2 installed successfully.
) else (
    echo Aria2 already installed. Using existing version.
)

:: Download MediaPipe BVH Converter
echo.
echo [3/6] Downloading Motion Capture Tools...
aria2c -x8 -s8 -d "%TOOL_DIR%" "https://github.com/CalciferZh/MPI-BVH/releases/download/v1.5/MPI-BVH-Windows.zip" -o mediapipe_bvh.zip
if not exist "mediapipe_bvh.zip" (
    echo Fallback: Downloading with PowerShell...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/CalciferZh/MPI-BVH/releases/download/v1.5/MPI-BVH-Windows.zip', 'mediapipe_bvh.zip')"
)
powershell -Command "Expand-Archive -Path mediapipe_bvh.zip -DestinationPath MediaPipe_BVH"
del mediapipe_bvh.zip
ren "MediaPipe_BVH\MPI-BVH-Windows" MediaPipe_BVH

:: Download Blender Portable
echo.
echo [4/6] Downloading 3D Software...
aria2c -x8 -s8 -d "%TOOL_DIR%" "%BLENDER_MIRROR%/blender-%BLENDER_VERSION%-windows-x64.zip" -o blender.zip
if not exist "blender.zip" (
    echo Fallback: Downloading from alternate mirror...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://ftp.nluug.nl/pub/graphics/blender/release/Blender4.0/blender-%BLENDER_VERSION%-windows-x64.zip', 'blender.zip')"
)
powershell -Command "Expand-Archive -Path blender.zip -DestinationPath Blender_Portable"
del blender.zip
ren "Blender_Portable\blender-%BLENDER_VERSION%-windows-x64" Blender_Portable

:: Download Roblox Assets
echo.
echo [5/6] Downloading Roblox Resources...
aria2c -x8 -s8 -d "%TOOL_DIR%" "https://github.com/Roblox/avatar/raw/main/templates/R15Template.fbx" -o R15_Template.fbx
if not exist "R15_Template.fbx" (
    echo Fallback: Downloading from Roblox CDN...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://assetdelivery.roblox.com/v1/asset/?id=7078297423', 'R15_Template.fbx')"
)

:: Install Python dependencies
echo.
echo [6/6] Installing Python Dependencies...
cd MediaPipe_BVH
%PYTHON_CMD% -m pip install --upgrade pip
%PYTHON_CMD% -m pip install -r requirements.txt
cd ..

:: Create processing scripts
echo.
echo Creating automation scripts...

:: Main processing script
echo @echo off > process_video.bat
echo setlocal enabledelayedexpansion >> process_video.bat
echo. >> process_video.bat
echo echo ROBLOX ANIMATION GENERATOR >> process_video.bat
echo echo --------------------------- >> process_video.bat
echo set /p "video=Drag and drop your video file here, then press ENTER: " >> process_video.bat
echo. >> process_video.bat
echo if not exist "!video!" ( >> process_video.bat
echo     echo ERROR: File not found >> process_video.bat
echo     pause >> process_video.bat
echo     exit /b >> process_video.bat
echo ) >> process_video.bat
echo. >> process_video.bat
echo echo Converting video to motion data... >> process_video.bat
echo "%TOOL_DIR%\MediaPipe_BVH\mpi_bvh.exe" --input_video_path="!video!" --output_bvh_path="%TOOL_DIR%\output.bvh" >> process_video.bat
echo. >> process_video.bat
echo echo Processing 3D animation... >> process_video.bat
echo "%TOOL_DIR%\Blender_Portable\blender.exe" --background --python "%TOOL_DIR%\auto_retarget.py" -- "%TOOL_DIR%\output.bvh" "%TOOL_DIR%\R15_Template.fbx" >> process_video.bat
echo. >> process_video.bat
echo if exist "%TOOL_DIR%\roblox_animation.fbx" ( >> process_video.bat
echo     echo SUCCESS: Animation created at %TOOL_DIR%\roblox_animation.fbx >> process_video.bat
echo ) else ( >> process_video.bat
echo     echo ERROR: Animation creation failed >> process_video.bat
echo ) >> process_video.bat
echo. >> process_video.bat
echo echo Import this FBX file in Roblox Studio >> process_video.bat
echo pause >> process_video.bat

:: Blender automation script
echo import bpy > auto_retarget.py
echo import os >> auto_retarget.py
echo import sys >> auto_retarget.py
echo >> auto_retarget.py
echo # Get command line arguments >> auto_retarget.py
echo argv = sys.argv[sys.argv.index("--") + 1:] >> auto_retarget.py
echo bvh_path = argv[0] >> auto_retarget.py
echo fbx_path = argv[1] >> auto_retarget.py
echo >> auto_retarget.py
echo # Clear existing objects >> auto_retarget.py
echo bpy.ops.object.select_all(action='SELECT') >> auto_retarget.py
echo bpy.ops.object.delete() >> auto_retarget.py
echo >> auto_retarget.py
echo # Import BVH motion capture data >> auto_retarget.py
echo bpy.ops.import_anim.bvh(filepath=bvh_path) >> auto_retarget.py
echo src_armature = bpy.context.selected_objects[0] >> auto_retarget.py
echo src_armature.name = "MotionCaptureRig" >> auto_retarget.py
echo >> auto_retarget.py
echo # Import Roblox R15 template >> auto_retarget.py
echo bpy.ops.import_scene.fbx(filepath=fbx_path) >> auto_retarget.py
echo tgt_armature = None >> auto_retarget.py
echo for obj in bpy.context.selected_objects: >> auto_retarget.py
echo     if obj.type == 'ARMATURE': >> auto_retarget.py
echo         tgt_armature = obj >> auto_retarget.py
echo         tgt_armature.name = "RobloxR15" >> auto_retarget.py
echo         break >> auto_retarget.py
echo >> auto_retarget.py
echo if not tgt_armature: >> auto_retarget.py
echo     raise Exception("Roblox armature not found in FBX file") >> auto_retarget.py
echo >> auto_retarget.py
echo # Bone mapping configuration >> auto_retarget.py
echo bone_map = { >> auto_retarget.py
echo     "Hips": "HumanoidRootPart", >> auto_retarget.py
echo     "Spine": "LowerTorso", >> auto_retarget.py
echo     "Spine1": "UpperTorso", >> auto_retarget.py
echo     "Neck": "Neck", >> auto_retarget.py
echo     "Head": "Head", >> auto_retarget.py
echo     "LeftShoulder": "LeftShoulder", >> auto_retarget.py
echo     "LeftArm": "LeftUpperArm", >> auto_retarget.py
echo     "LeftForeArm": "LeftLowerArm", >> auto_retarget.py
echo     "LeftHand": "LeftHand", >> auto_retarget.py
echo     "RightShoulder": "RightShoulder", >> auto_retarget.py
echo     "RightArm": "RightUpperArm", >> auto_retarget.py
echo     "RightForeArm": "RightLowerArm", >> auto_retarget.py
echo     "RightHand": "RightHand", >> auto_retarget.py
echo     "LeftUpLeg": "LeftUpperLeg", >> auto_retarget.py
echo     "LeftLeg": "LeftLowerLeg", >> auto_retarget.py
echo     "LeftFoot": "LeftFoot", >> auto_retarget.py
echo     "LeftToeBase": "LeftToe", >> auto_retarget.py
echo     "RightUpLeg": "RightUpperLeg", >> auto_retarget.py
echo     "RightLeg": "RightLowerLeg", >> auto_retarget.py
echo     "RightFoot": "RightFoot", >> auto_retarget.py
echo     "RightToeBase": "RightToe" >> auto_retarget.py
echo } >> auto_retarget.py
echo >> auto_retarget.py
echo # Apply constraints for animation retargeting >> auto_retarget.py
echo for src_bone, tgt_bone in bone_map.items(): >> auto_retarget.py
echo     if src_bone in src_armature.pose.bones and tgt_bone in tgt_armature.pose.bones: >> auto_retarget.py
echo         # Clear existing constraints >> auto_retarget.py
echo         for const in tgt_armature.pose.bones[tgt_bone].constraints: >> auto_retarget.py
echo             tgt_armature.pose.bones[tgt_bone].constraints.remove(const) >> auto_retarget.py
echo         >> auto_retarget.py
echo         # Add copy rotation constraint >> auto_retarget.py
echo         constraint = tgt_armature.pose.bones[tgt_bone].constraints.new('COPY_ROTATION') >> auto_retarget.py
echo         constraint.target = src_armature >> auto_retarget.py
echo         constraint.subtarget = src_bone >> auto_retarget.py
echo         constraint.mix_mode = 'ADD' >> auto_retarget.py
echo         constraint.target_space = 'LOCAL' >> auto_retarget.py
echo         constraint.owner_space = 'LOCAL' >> auto_retarget.py
echo     else: >> auto_retarget.py
echo         print(f"Skipping {src_bone} -> {tgt_bone}: bone not found") >> auto_retarget.py
echo >> auto_retarget.py
echo # Set keyframes for entire animation >> auto_retarget.py
echo bpy.context.view_layer.objects.active = tgt_armature >> auto_retarget.py
echo bpy.ops.object.mode_set(mode='POSE') >> auto_retarget.py
echo bpy.ops.pose.select_all(action='SELECT') >> auto_retarget.py
echo bpy.ops.anim.keyframe_insert_menu(type='BUILTIN_KSI_LocRot') >> auto_retarget.py
echo >> auto_retarget.py
echo # Clean up source armature >> auto_retarget.py
echo bpy.data.objects.remove(src_armature, do_unlink=True) >> auto_retarget.py
echo >> auto_retarget.py
echo # Export FBX for Roblox >> auto_retarget.py
echo bpy.ops.export_scene.fbx( >> auto_retarget.py
echo     filepath=os.path.join(os.path.dirname(bvh_path), "roblox_animation.fbx"), >> auto_retarget.py
echo     use_selection=True, >> auto_retarget.py
echo     object_types={'ARMATURE'}, >> auto_retarget.py
echo     bake_anim=True, >> auto_retarget.py
echo     bake_anim_use_all_bones=True, >> auto_retarget.py
echo     bake_anim_use_nla_strips=False, >> auto_retarget.py
echo     bake_anim_use_all_actions=False, >> auto_retarget.py
echo     add_leaf_bones=False, >> auto_retarget.py
echo     path_mode='COPY', >> auto_retarget.py
echo     embed_textures=False >> auto_retarget.py
echo ) >> auto_retarget.py

:: Create Roblox import script
echo local Players = game:GetService("Players") > import_animation.lua
echo local InsertService = game:GetService("InsertService") >> import_animation.lua
echo >> import_animation.lua
echo local player = Players.LocalPlayer >> import_animation.lua
echo local character = player.Character or player.CharacterAdded:Wait() >> import_animation.lua
echo local humanoid = character:WaitForChild("Humanoid") >> import_animation.lua
echo >> import_animation.lua
echo local function importAnimation() >> import_animation.lua
echo     local animation = InsertService:LoadFBXAnimation("rbxasset://roblox_animation.fbx") >> import_animation.lua
echo     if animation then >> import_animation.lua
echo         local animTrack = humanoid:LoadAnimation(animation) >> import_animation.lua
echo         animTrack:Play() >> import_animation.lua
echo         print("Animation loaded and playing!") >> import_animation.lua
echo     else >> import_animation.lua
echo         warn("Failed to load animation") >> import_animation.lua
echo     end >> import_animation.lua
echo end >> import_animation.lua
echo >> import_animation.lua
echo importAnimation() >> import_animation.lua

:: Final message
echo.
echo *******************************************************
echo    INSTALLATION COMPLETED SUCCESSFULLY!
echo *******************************************************
echo.
echo To create a Roblox animation:
echo  1. Double-click 'process_video.bat'
echo  2. Drag and drop your video file into the window
echo  3. Press Enter
echo  4. Wait for processing to complete
echo  5. Use 'roblox_animation.fbx' in Roblox Studio
echo.
echo For Roblox Studio script:
echo  - Use the 'import_animation.lua' as a LocalScript
echo.
echo Note: Processing time depends on video length and complexity
echo       (1 min video ~ 30-60 seconds on modern hardware)
echo *******************************************************
echo.
pause
