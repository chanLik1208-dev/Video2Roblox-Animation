@echo off
:: 修复第2步aria2安装问题
setlocal enabledelayedexpansion

:: 1. 检查是否已安装
where aria2c >nul 2>&1
if !errorlevel! equ 0 (
    echo aria2 already installed at:
    where aria2c
    goto :success
)

:: 2. 创建临时目录
set TEMP_DIR=%cd%\aria2_temp
mkdir "!TEMP_DIR!" 2>nul

:: 3. 多源下载（自动回退）
set DL_SOURCES=(
    "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
    "https://mirrors.tuna.tsinghua.edu.cn/github-release/aria2/aria2/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
    "https://download.fastgit.org/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
)

for %%i in (!DL_SOURCES!) do (
    echo Trying download from: %%i
    curl -L -o "!TEMP_DIR!\aria2.zip" "%%i"
    if exist "!TEMP_DIR!\aria2.zip" (
        echo Download succeeded
        goto :unzip
    )
)
echo ERROR: All download sources failed
goto :cleanup

:unzip
:: 4. 解压并安装
powershell -Command "Expand-Archive -Path '!TEMP_DIR!\aria2.zip' -DestinationPath '!TEMP_DIR!'"
if not exist "!TEMP_DIR!\aria2-1.37.0-win-64bit\aria2c.exe" (
    echo ERROR: File structure mismatch
    goto :cleanup
)

:: 5. 尝试系统目录安装
copy "!TEMP_DIR!\aria2-1.37.0-win-64bit\aria2c.exe" "%SystemRoot%\system32\" >nul 2>&1
if !errorlevel! neq 0 (
    echo WARNING: System install failed, using local install
    copy "!TEMP_DIR!\aria2-1.37.0-win-64bit\aria2c.exe" .\
    set PATH=%PATH%;%cd%
)

:success
echo aria2c successfully installed at:
where aria2c
aria2c --version

:cleanup
rd /s /q "!TEMP_DIR!" 2>nul
pause
