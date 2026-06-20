#!/bin/bash
# RedClass 项目环境初始化脚本
# 每次打开新终端时运行: source tools/setup.sh

export FLUTTER_ROOT=/d/flutter
export ANDROID_HOME=/d/Android/Sdk
export GRADLE_USER_HOME=/d/gradle-home
export PUB_CACHE=/d/RedClass/pub-cache
export JAVA_HOME=/d/Java/jdk-21

export PATH="$FLUTTER_ROOT/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"

# 确保 build/ 是 junction 指向 D 盘 (Flutter 硬编码 build/ 路径,只能用 junction 重定向)
if [ ! -L "build" ] && [ -d "build" ]; then
    echo "[setup] 移除 C 盘 build/ 残留..."
    cmd //c "rmdir /S /Q $(cygpath -w build)" 2>/dev/null
fi
if [ ! -d "build" ] && [ ! -L "build" ]; then
    echo "[setup] 创建 build/ → D:\\RedClass\\build junction..."
    cmd //c "mklink /J $(cygpath -w build) D:\\RedClass\\build" 2>/dev/null
fi

# 确保 .dart_tool/ 是 junction
if [ ! -L ".dart_tool" ] && [ -d ".dart_tool" ]; then
    cmd //c "rmdir /S /Q $(cygpath -w .dart_tool)" 2>/dev/null
fi
if [ ! -d ".dart_tool" ] && [ ! -L ".dart_tool" ]; then
    cmd //c "mklink /J $(cygpath -w .dart_tool) D:\\RedClass\\dart_tool" 2>/dev/null
fi

echo "[setup] 环境就绪 — Flutter SDK, Android SDK, Gradle 缓存均指向 D 盘"
