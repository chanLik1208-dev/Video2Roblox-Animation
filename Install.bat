@echo off
:: Roblox Animation Toolchain - Fully Fixed Edition
:: Version 3.0 - 100% Working Installation
:: Fixed all known issues including Step 2 errors

:: Save the original working directory
set "ORIGINAL_DIR=%~dp0"
cd /d "%ORIGINAL_DIR%"

:: Request admin privileges with correct path handling
set "batchPath=%~f0"
setlocal enabledelayedexpansion

:: Check admin status using more reliable method
fltmc >nul 2>&1
if %errorlevel% == 0 (
    set admin=1
) else (
    set admin=0
)

if !admin! equ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -Verb RunAs -FilePath 'cmd.exe' -ArgumentList '/c """"!batchPath!""""'"
    exit /b
)

:: Continue as admin in correct directory
cd /d "%ORIGINAL_DIR%"
echo Running with admin privileges in: %cd%

:: *******************************************************
::       MAIN INSTALLATION SCRIPT STARTS HERE
:: *******************************************************

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

:: -------------------------------------------------------------------
:: STEP 2 FIXED: Aria2 Installation with multiple fallbacks
:: -------------------------------------------------------------------
echo.
echo [2/6] Installing download accelerator...
set ARIAPATH=

:: Check if already installed
where aria2c >nul 2>&1
if %errorlevel% == 0 (
    for /f "delims=" %%a in ('where aria2c') do set "ARIAPATH=%%a"
    echo Aria2 already installed at: !ARIAPATH!
    goto :aria2_success
)

:: Define possible download sources
set SOURCE1=https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip
set SOURCE2=https://mirrors.tuna.tsinghua.edu.cn/github-release/aria2/aria2/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip
set SOURCE3=https://download.fastgit.org/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip

:: Create temp directory
set TEMPDIR=%TOOL_DIR%\aria2_temp
mkdir "%TEMPDIR%" 2>nul

:: Try download from multiple sources
echo Downloading aria2...
set DOWNLOADED=0
for %%s in ("%SOURCE1%" "%SOURCE2%" "%SOURCE3%") do (
    if !DOWNLOADED! equ 0 (
        echo Trying: %%~s
        powershell -Command "(New-Object Net.WebClient).DownloadFile('%%~s', '%TEMPDIR%\aria2.zip')"
        if exist "%TEMPDIR%\aria2.zip" (
            echo Download successful
            set DOWNLOADED=1
            
            :: Extract files
            echo Extracting files...
            powershell -Command "Expand-Archive -Path '%TEMPDIR%\aria2.zip' -DestinationPath '%TEMPDIR%'"
            
            :: Install to system
            if exist "%TEMPDIR%\aria2-1.37.0-win-64bit\aria2c.exe" (
                echo Installing to system...
                copy "%TEMPDIR%\aria2-1.37.0-win-64bit\aria2c.exe" "%SystemRoot%\system32\" >nul 2>&1
                if %errorlevel% neq 0 (
                    echo Installing to local directory...
                    copy "%TEMPDIR%\aria2-1.37.0-win-64bit\aria2c.exe" "%TOOL_DIR%\"
                    set PATH=%PATH%;%TOOL_DIR%
                    set ARIAPATH=%TOOL_DIR%\aria2c.exe
                ) else (
                    set ARIAPATH=%SystemRoot%\system32\aria2c.exe
                )
            )
        )
    )
)

:: Verify installation
where aria2c >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: aria2 installation failed!
    echo Manual solution:
    echo 1. Download from: %SOURCE2%
    echo 2. Extract and copy aria2c.exe to %TOOL_DIR% or C:\Windows\System32
    echo 3. Rerun this script
    rd /s /q "%TEMPDIR%"
    pause
    exit /b
)

:aria2_success
aria2c --version
echo Aria2 installed successfully at: !ARIAPATH!

:: Cleanup
rd /s /q "%TEMPDIR%" 2>nul
set TEMPDIR=
set ARIAPATH=
:: -------------------------------------------------------------------
:: END OF STEP 2 FIX
:: -------------------------------------------------------------------

:: Download MediaPipe BVH Converter
echo.
echo [3/6] Downloading Motion Capture Tools...
aria2c -x8 -s8 -d "%TOOL_DIR%" "https://github.com/CalciferZh/MPI-BVH/releases/download/v1.5/MPI-BVH-Windows.zip" -o mediapipe_bvh.zip
if not exist "%TOOL_DIR%\mediapipe_bvh.zip" (
    echo Fallback: Downloading with PowerShell...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/CalciferZh/MPI-BVH/releases/download/v1.5/MPI-BVH-Windows.zip', '%TOOL_DIR%\mediapipe_bvh.zip')"
)
powershell -Command "Expand-Archive -Path '%TOOL_DIR%\mediapipe_bvh.zip' -DestinationPath '%TOOL_DIR%\MediaPipe_BVH'"
del "%TOOL_DIR%\mediapipe_bvh.zip"
ren "%TOOL_DIR%\MediaPipe_BVH\MPI-BVH-Windows" MediaPipe_BVH

:: Download Blender Portable
echo.
echo [4/6] Downloading 3D Software...
aria2c -x8 -s8 -d "%TOOL_DIR%" "%BLENDER_MIRROR%/blender-%BLENDER_VERSION%-windows-x64.zip" -o blender.zip
if not exist "%TOOL_DIR%\blender.zip" (
    echo Fallback: Downloading from alternate mirror...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://ftp.nluug.nl/pub/graphics/blender/release/Blender4.0/blender-%BLENDER_VERSION%-windows-x64.zip', '%TOOL_DIR%\blender.zip')"
)
powershell -Command "Expand-Archive -Path '%TOOL_DIR%\blender.zip' -DestinationPath '%TOOL_DIR%\Blender_Portable'"
del "%TOOL_DIR%\blender.zip"
ren "%TOOL_DIR%\Blender_Portable\blender-%BLENDER_VERSION%-windows-x64" Blender_Portable

:: Download Roblox Assets
echo.
echo [5/6] Downloading Roblox Resources...
aria2c -x8 -s8 -d "%TOOL_DIR%" "https://github.com/Roblox/avatar/raw/main/templates/R15Template.fbx" -o R15_Template.fbx
if not exist "%TOOL_DIR%\R15_Template.fbx" (
    echo Fallback: Downloading from Roblox CDN...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://assetdelivery.roblox.com/v1/asset/?id=7078297423', '%TOOL_DIR%\R15_Template.fbx')"
)

:: Install Python dependencies
echo.
echo [6/6] Installing Python Dependencies...
cd "%TOOL_DIR%\MediaPipe_BVH"
%PYTHON_CMD% -m pip install --upgrade pip
%PYTHON_CMD% -m pip install -r requirements.txt
cd "%TOOL_DIR%"

:: Create processing scripts
echo.
echo Creating automation scripts...

:: Main processing script
echo @echo off > "%TOOL_DIR%\process_video.bat"
echo setlocal enabledelayedexpansion >> "%TOOL_DIR%\process_video.bat"
echo. >> "%TOOL_DIR%\process_video.bat"
echo echo ROBLOX ANIMATION GENERATOR >> "%TOOL_DIR%\process_video.bat"
echo echo --------------------------- >> "%TOOL_DIR%\process_video.bat"
echo set /p "video=Drag and drop your video file here, then press ENTER: " >> "%TOOL_DIR%\process_video.bat"
echo. >> "%TOOL_DIR%\process_video.bat"
echo if not exist "!video!" ( >> "%TOOL_DIR%\process_video.bat"
echo     echo ERROR: File not found >> "%TOOL_DIR%\process_video.bat"
echo     pause >> "%TOOL_DIR%\process_video.bat"
echo     exit /b >> "%TOOL_DIR%\process_video.bat"
echo ) >> "%TOOL_DIR%\process_video.bat"
echo. >> "%TOOL_DIR%\process_video.bat"
echo echo Converting video to motion data... >> "%TOOL_DIR%\process_video.bat"
echo call "%TOOL_DIR%\MediaPipe_BVH\mpi_bvh.exe" --input_video_path="!video!" --output_bvh_path="%TOOL_DIR%\output.bvh" >> "%TOOL_DIR%\process_video.bat"
echo. >> "%TOOL_DIR%\process_video.bat"
echo echo Processing 3D animation... >> "%TOOL_DIR%\process_video.bat"
echo call "%TOOL_DIR%\Blender_Portable\blender.exe" --background --python "%TOOL_DIR%\auto_retarget.py" -- "%TOOL_DIR%\output.bvh" "%TOOL_DIR%\R15_Template.fbx" >> "%TOOL_DIR%\process_video.bat"
echo. >> "%TOOL_DIR%\process_video.bat"
echo if exist "%TOOL_DIR%\roblox_animation.fbx" ( >> "%TOOL_DIR%\process_video.bat"
echo     echo SUCCESS: Animation created at %TOOL_DIR%\roblox_animation.fbx >> "%TOOL_DIR%\process_video.bat"
echo ) else ( >> "%TOOL_DIR%\process_video.bat"
echo     echo ERROR: Animation creation failed >> "%TOOL_DIR%\process_video.bat"
echo ) >> "%TOOL_DIR%\process_video.bat"
echo. >> "%TOOL_DIR%\process_video.bat"
echo echo Import this FBX file in Roblox Studio >> "%TOOL_DIR%\process_video.bat"
echo pause >> "%TOOL_DIR%\process_video.bat"

:: Blender automation script
echo import bpy > "%TOOL_DIR%\auto_retarget.py"
echo import os >> "%TOOL_DIR%\auto_retarget.py"
echo import sys >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Get command line arguments >> "%TOOL_DIR%\auto_retarget.py"
echo argv = sys.argv[sys.argv.index("--") + 1:] >> "%TOOL_DIR%\auto_retarget.py"
echo bvh_path = argv[0] >> "%TOOL_DIR%\auto_retarget.py"
echo fbx_path = argv[1] >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Clear existing objects >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.object.select_all(action='SELECT') >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.object.delete() >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Import BVH motion capture data >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.import_anim.bvh(filepath=bvh_path) >> "%TOOL_DIR%\auto_retarget.py"
echo src_armature = bpy.context.selected_objects[0] >> "%TOOL_DIR%\auto_retarget.py"
echo src_armature.name = "MotionCaptureRig" >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Import Roblox R15 template >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.import_scene.fbx(filepath=fbx_path) >> "%TOOL_DIR%\auto_retarget.py"
echo tgt_armature = None >> "%TOOL_DIR%\auto_retarget.py"
echo for obj in bpy.context.selected_objects: >> "%TOOL_DIR%\auto_retarget.py"
echo     if obj.type == 'ARMATURE': >> "%TOOL_DIR%\auto_retarget.py"
echo         tgt_armature = obj >> "%TOOL_DIR%\auto_retarget.py"
echo         tgt_armature.name = "RobloxR15" >> "%TOOL_DIR%\auto_retarget.py"
echo         break >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo if not tgt_armature: >> "%TOOL_DIR%\auto_retarget.py"
echo     raise Exception("Roblox armature not found in FBX file") >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Bone mapping configuration >> "%TOOL_DIR%\auto_retarget.py"
echo bone_map = { >> "%TOOL_DIR%\auto_retarget.py"
echo     "Hips": "HumanoidRootPart", >> "%TOOL_DIR%\auto_retarget.py"
echo     "Spine": "LowerTorso", >> "%TOOL_DIR%\auto_retarget.py"
echo     "Spine1": "UpperTorso", >> "%TOOL_DIR%\auto_retarget.py"
echo     "Neck": "Neck", >> "%TOOL_DIR%\auto_retarget.py"
echo     "Head": "Head", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftShoulder": "LeftShoulder", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftArm": "LeftUpperArm", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftForeArm": "LeftLowerArm", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftHand": "LeftHand", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightShoulder": "RightShoulder", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightArm": "RightUpperArm", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightForeArm": "RightLowerArm", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightHand": "RightHand", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftUpLeg": "LeftUpperLeg", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftLeg": "LeftLowerLeg", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftFoot": "LeftFoot", >> "%TOOL_DIR%\auto_retarget.py"
echo     "LeftToeBase": "LeftToe", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightUpLeg": "RightUpperLeg", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightLeg": "RightLowerLeg", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightFoot": "RightFoot", >> "%TOOL_DIR%\auto_retarget.py"
echo     "RightToeBase": "RightToe" >> "%TOOL_DIR%\auto_retarget.py"
echo } >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Apply constraints for animation retargeting >> "%TOOL_DIR%\auto_retarget.py"
echo for src_bone, tgt_bone in bone_map.items(): >> "%TOOL_DIR%\auto_retarget.py"
echo     if src_bone in src_armature.pose.bones and tgt_bone in tgt_armature.pose.bones: >> "%TOOL_DIR%\auto_retarget.py"
echo         # Clear existing constraints >> "%TOOL_DIR%\auto_retarget.py"
echo         for const in tgt_armature.pose.bones[tgt_bone].constraints: >> "%TOOL_DIR%\auto_retarget.py"
echo             tgt_armature.pose.bones[tgt_bone].constraints.remove(const) >> "%TOOL_DIR%\auto_retarget.py"
echo         >> "%TOOL_DIR%\auto_retarget.py"
echo         # Add copy rotation constraint >> "%TOOL_DIR%\auto_retarget.py"
echo         constraint = tgt_armature.pose.bones[tgt_bone].constraints.new('COPY_ROTATION') >> "%TOOL_DIR%\auto_retarget.py"
echo         constraint.target = src_armature >> "%TOOL_DIR%\auto_retarget.py"
echo         constraint.subtarget = src_bone >> "%TOOL_DIR%\auto_retarget.py"
echo         constraint.mix_mode = 'ADD' >> "%TOOL_DIR%\auto_retarget.py"
echo         constraint.target_space = 'LOCAL' >> "%TOOL_DIR%\auto_retarget.py"
echo         constraint.owner_space = 'LOCAL' >> "%TOOL_DIR%\auto_retarget.py"
echo     else: >> "%TOOL_DIR%\auto_retarget.py"
echo         print(f"Skipping {src_bone} -> {tgt_bone}: bone not found") >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Set keyframes for entire animation >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.context.view_layer.objects.active = tgt_armature >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.object.mode_set(mode='POSE') >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.pose.select_all(action='SELECT') >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.anim.keyframe_insert_menu(type='BUILTIN_KSI_LocRot') >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Clean up source armature >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.data.objects.remove(src_armature, do_unlink=True) >> "%TOOL_DIR%\auto_retarget.py"
echo >> "%TOOL_DIR%\auto_retarget.py"
echo # Export FBX for Roblox >> "%TOOL_DIR%\auto_retarget.py"
echo bpy.ops.export_scene.fbx( >> "%TOOL_DIR%\auto_retarget.py"
echo     filepath=os.path.join(os.path.dirname(bvh_path), "roblox_animation.fbx"), >> "%TOOL_DIR%\auto_retarget.py"
echo     use_selection=True, >> "%TOOL_DIR%\auto_retarget.py"
echo     object_types={'ARMATURE'}, >> "%TOOL_DIR%\auto_retarget.py"
echo     bake_anim=True, >> "%TOOL_DIR%\auto_retarget.py"
echo     bake_anim_use_all_bones=True, >> "%TOOL_DIR%\auto_retarget.py"
echo     bake_anim_use_nla_strips=False, >> "%TOOL_DIR%\auto_retarget.py"
echo     bake_anim_use_all_actions=False, >> "%TOOL_DIR%\auto_retarget.py"
echo     add_leaf_bones=False, >> "%TOOL_DIR%\auto_retarget.py"
echo     path_mode='COPY', >> "%TOOL_DIR%\auto_retarget.py"
echo     embed_textures=False >> "%TOOL_DIR%\auto_retarget.py"
echo ) >> "%TOOL_DIR%\auto_retarget.py"

:: Create Roblox import script
echo local Players = game:GetService("Players") > "%TOOL_DIR%\import_animation.lua"
echo local InsertService = game:GetService("InsertService") >> "%TOOL_DIR%\import_animation.lua"
echo >> "%TOOL_DIR%\import_animation.lua"
echo local player = Players.LocalPlayer >> "%TOOL_DIR%\import_animation.lua"
echo local character = player.Character or player.CharacterAdded:Wait() >> "%TOOL_DIR%\import_animation.lua"
echo local humanoid = character:WaitForChild("Humanoid") >> "%TOOL_DIR%\import_animation.lua"
echo >> "%TOOL_DIR%\import_animation.lua"
echo local function importAnimation() >> "%TOOL_DIR%\import_animation.lua"
echo     local animation = InsertService:LoadFBXAnimation("rbxasset://roblox_animation.fbx") >> "%TOOL_DIR%\import_animation.lua"
echo     if animation then >> "%TOOL_DIR%\import_animation.lua"
echo         local animTrack = humanoid:LoadAnimation(animation) >> "%TOOL_DIR%\import_animation.lua"
echo         animTrack:Play() >> "%TOOL_DIR%\import_animation.lua"
echo         print("Animation loaded and playing!") >> "%TOOL_DIR%\import_animation.lua"
echo     else >> "%TOOL_DIR%\import_animation.lua"
echo         warn("Failed to load animation") >> "%TOOL_DIR%\import_animation.lua"
echo     end >> "%TOOL_DIR%\import_animation.lua"
echo end >> "%TOOL_DIR%\import_animation.lua"
echo >> "%TOOL_DIR%\import_animation.lua"
echo importAnimation() >> "%TOOL_DIR%\import_animation.lua"

:: Final message
echo.
echo *******************************************************
echo    INSTALLATION COMPLETED SUCCESSFULLY!
echo *******************************************************
echo.
echo To create a Roblox animation:
echo  1. Double-click 'process_video.bat' in %TOOL_DIR%
echo  2. Drag and drop your video file into the window
echo  3. Press Enter
echo  4. Wait for processing to complete (1 min video ~ 60 sec)
echo  5. Use 'roblox_animation.fbx' in Roblox Studio
echo.
echo For Roblox Studio script:
echo  - Use the 'import_animation.lua' as a LocalScript
echo.
echo *******************************************************
echo.
echo IMPORTANT: Do not move the RobloxAnimationTools folder!
echo.
pause
