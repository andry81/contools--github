@echo off

rem USAGE:
rem   backup_checkouted_auth_repo.bat [<Flags>] [--] <OWNER> <REPO>

rem Description:
rem   Script to backup a repository with credentials.
rem   Backup excludes a bare repository backup and used only NOT bare variant
rem   with submodules recursion.

rem <Flags>:
rem   --
rem     Stop flags parse.

rem <OWNER>:
rem   Owner name of a repository.
rem <REPO>:
rem   Repository name.

setlocal

call "%%~dp0../__init__/script_init.bat" backup checkout %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

if defined GIT_CHECKOUTED_REPO_BACKUP_USE_TIMEOUT_MS call "%%CONTOOLS_ROOT%%/std/sleep.bat" "%%GIT_CHECKOUTED_REPO_BACKUP_USE_TIMEOUT_MS%%"

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

set /A NEST_LVL-=1

exit /b %LAST_ERROR%

:MAIN
rem script flags

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if not "%FLAG%" == "--" (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "OWNER=%~1"
set "REPO=%~2"

if not defined OWNER (
  echo.%?~nx0%: error: OWNER is not defined.
  exit /b 255
) >&2

if not defined REPO (
  echo.%?~nx0%: error: REPO is not defined.
  exit /b 255
) >&2

set "QUERY_TEMP_FILE=%SCRIPT_TEMP_CURRENT_DIR%\query.txt"

set "PROJECT_LOG_TEMP_DIR="

if defined PROJECT_LOG_DIR (
  set "PROJECT_LOG_TEMP_DIR=%PROJECT_LOG_DIR%\tmp"
  if /i "%MAKE_GIT_CLONE_TEMP_DIR_IN%" == "log" set "GH_BACKUP_TEMP_DIR=%PROJECT_LOG_DIR%\tmp\backup\checkouted"
  if /i "%MAKE_7ZIP_WORK_DIR_IN%" == "log" set "_7ZIP_BARE_FLAGS=%_7ZIP_BARE_FLAGS% -w%PROJECT_LOG_DIR%\tmp"
)

if not defined GH_BACKUP_TEMP_DIR set "GH_BACKUP_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%\backup\checkouted"

set "GH_BACKUP_OUTPUT_TEMP_DIR=%GH_BACKUP_TEMP_DIR%/repo/%OWNER%/%REPO%"
set "GH_BACKUP_OUTPUT_DIR=%GH_BACKUP_CHECKOUTED_REPO_DIR%/%OWNER%/%REPO%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%GH_BACKUP_OUTPUT_TEMP_DIR%%" >nul || exit /b 255

set HAS_AUTH_USER=0

if defined GH_AUTH_USER if not "%GH_AUTH_USER%" == "{{USER}}" ^
if defined GH_AUTH_PASS if not "%GH_AUTH_PASS%" == "{{PASS}}" set HAS_AUTH_USER=1

if %HAS_AUTH_USER% EQU 0 (
  echo.%~nx0: error: GH_AUTH_USER or GH_AUTH_PASS is not defined.
  exit /b 255
) >&2

call :GIT clone --config core.longpaths=true -v --recurse-submodules --progress "https://%%GH_AUTH_PASS%%@github.com/%%OWNER%%/%%REPO%%" "%%GH_BACKUP_OUTPUT_TEMP_DIR%%"
set LAST_ERROR=%ERRORLEVEL%

echo.

if exist "%GH_BACKUP_OUTPUT_TEMP_DIR%/db/config" goto ARCHIVE
if exist "%GH_BACKUP_OUTPUT_TEMP_DIR%/wc/.git/config" goto ARCHIVE
goto SKIP_ARCHIVE

:ARCHIVE
call set "GH_BACKUP_CHECKOUTED_AUTH_REPO_FILE=%%GH_BACKUP_CHECKOUTED_AUTH_REPO_FILE_NAME:{{OWNER}}=%OWNER%%%"
call set "GH_BACKUP_CHECKOUTED_AUTH_REPO_FILE=%%GH_BACKUP_CHECKOUTED_AUTH_REPO_FILE:{{REPO}}=%REPO%%%"
call set "GH_BACKUP_CHECKOUTED_AUTH_REPO_FILE=%%GH_BACKUP_CHECKOUTED_AUTH_REPO_FILE:{{DATE_TIME}}=%PROJECT_LOG_FILE_NAME_DATE_TIME%%%"

echo.Archiving backup directory...
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%GH_BACKUP_OUTPUT_DIR%%" && ^
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/add_files_to_archive.bat" "%%GH_BACKUP_TEMP_DIR%%" "*" "%%GH_BACKUP_OUTPUT_DIR%%/%%GH_BACKUP_CHECKOUTED_AUTH_REPO_FILE%%.7z" -sdel%%_7ZIP_BARE_FLAGS%%
set LAST_ERROR=%ERRORLEVEL%

echo.

:SKIP_ARCHIVE
if defined PROJECT_LOG_TEMP_DIR rmdir /S /Q "%PROJECT_LOG_TEMP_DIR%" >nul 2>nul

exit /b %LAST_ERROR%

:GIT
echo.^>git.exe %GIT_BARE_FLAGS% %*
git.exe %GIT_BARE_FLAGS% %*
exit /b
