@echo off

setlocal

call "%%~dp0__init__\__init__.bat" || exit /b

call "%%~dp0enable_restapi_workflows.bat" -use-inactive %%*
