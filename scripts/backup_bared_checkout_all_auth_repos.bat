@echo off

setlocal

call "%%~dp0__init__\__init__.bat" || exit /b

call "%%~dp0backup_bare_all_auth_repos.bat" -checkout %%*
