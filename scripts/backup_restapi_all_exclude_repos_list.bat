@echo off

setlocal

call "%%~dp0__init__\__init__.bat" || exit /b

call "%%~dp0backup_restapi_all.bat" -skip-auth-repo-list -skip-account-lists %%*
