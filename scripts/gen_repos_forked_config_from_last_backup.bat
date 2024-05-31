@echo off

setlocal

call "%%~dp0__init__\__init__.bat" || exit /b

call "%%~dp0gen_repos_config_from_last_backup.bat" -filter-forked %%*
