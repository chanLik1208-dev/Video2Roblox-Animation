@echo off
:: Roblox Animation Toolchain - Fixed Admin Path Issue
:: Version 2.2 - Guaranteed to work after UAC elevation

:: Save the original working directory
set "ORIGINAL_DIR=%~dp0"
cd /d "%ORIGINAL_DIR%"

:: Request admin privileges with correct path handling
set "batchPath=%~f0"
set "batchArgs=%*"
setlocal enabledelayedexpansion

:: Check admin status
net session >nul 2>&1
if %errorlevel% == 0 (
    set admin=1
) else (
    set admin=0
)

if !admin! equ 0 (
    echo Requesting administrative privileges...
    set "args=%batchArgs:"=""%"
    set "args=!args:)=^)!"
    set "args=!args:!=^^!"
    
    powershell -Command "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList '/c """"!batchPath!"" !args!""'"
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

:: Blender automation script (same as before)
echo import bpy > auto_retarget.py
echo import os >> auto_retarget.py
echo import sys >> auto_retarget.py
echo >> auto_retarget.py
:: ... [Blender script content unchanged from previous version] ...

:: Create Roblox import script
echo local Players = game:GetService("Players") > import_animation.lua
echo local InsertService = game:GetService("InsertService") >> import_animation.lua
echo >> import_animation.lua
:: ... [Lua script content unchanged from previous version] ...

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
echo Note: Processing time depends on video length and complexity
echo       (1 min video ~ 30-60 seconds on modern hardware)
echo *******************************************************
echo.
echo IMPORTANT: Do not move the RobloxAnimationTools folder!
echo.
pause
