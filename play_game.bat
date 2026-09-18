@echo off
chcp 65001 >nul
title 暗影机械城 - 重铸余烬
if exist "%~dp0build\Reforged\ShadowMechCityReforged.exe" (
    start "" "%~dp0build\Reforged\ShadowMechCityReforged.exe"
    exit /b
)
"e:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.exe" --path "%~dp0."
