@echo off
chcp 65001 >nul
title 暗影机械城 - 启动中...
rem 一键启动游戏: 双击本文件即可运行(无需打开编辑器)
"e:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.exe" --path "%~dp0."
