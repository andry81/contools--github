@echo off

rem USAGE:
rem   backup_bare_repo.bat [<Flags>] [--] <OWNER> <REPO>

rem Description:
rem   Script to backup any repository including private repository with
rem   credentials.
rem   Backup by default includes only a bare repository backup.

rem <Flags>:
rem   --
rem     Stop flags parse.
rem   -checkout
rem     Additionally execute git checkout with recursion to backup submodules.
rem   -temp-dir <temp-dir>
rem     Retarget all temporary directories into <temp-dir>.
rem     Useful in case of clone and/or archive large repositories.

rem <OWNER>:
rem   Owner name of a repository.
rem <REPO>:
rem   Repository name.

setlocal

call "%%~dp0../__init__/script_init.bat" backup bare %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

if defined GIT_BARE_REPO_BACKUP_USE_TIMEOUT_MS call "%%CONTOOLS_ROOT%%/std/sleep.bat" "%%GIT_BARE_REPO_BACKUP_USE_TIMEOUT_MS%%"

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
set FLAG_CHECKOUT=0
set "FLAG_TEMP_DIR="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-checkout" (
    set FLAG_CHECKOUT=1
  ) else if "%FLAG%" == "-temp-dir" (
    set "FLAG_TEMP_DIR=%~2"
    shift
  ) else if not "%FLAG%" == "--" (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

if defined FLAG_TEMP_DIR if not exist "%FLAG_TEMP_DIR%\*" (
  echo.%?~nx0%: error: FLAG_TEMP_DIR directory does not exist: "%FLAG_TEMP_DIR%"
  exit /b 255
) >&2

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

set "TEMP_DIR="
set "GH_BACKUP_TEMP_DIR="

if defined FLAG_TEMP_DIR (
  set "TEMP_DIR=%FLAG_TEMP_DIR%\tmp-%RANDOM%-%RANDOM%"
) else if defined PROJECT_LOG_DIR (
  if /i "%MAKE_GIT_CLONE_TEMP_DIR_IN%" == "log" (
    set "TEMP_DIR=%PROJECT_LOG_DIR%\tmp-%RANDOM%-%RANDOM%"
  ) else if /i "%MAKE_7ZIP_WORK_DIR_IN%" == "log" (
    set "TEMP_DIR=%PROJECT_LOG_DIR%\tmp-%RANDOM%-%RANDOM%"
  )
)

if defined FLAG_TEMP_DIR (
  set "GH_BACKUP_TEMP_DIR=%TEMP_DIR%\backup\bare"
  set _7ZIP_BARE_FLAGS=%_7ZIP_BARE_FLAGS% -w"%TEMP_DIR%"
) else if defined PROJECT_LOG_DIR (
  if /i "%MAKE_GIT_CLONE_TEMP_DIR_IN%" == "log" (
    set "GH_BACKUP_TEMP_DIR=%TEMP_DIR%\backup\bare"
  )
  if /i "%MAKE_7ZIP_WORK_DIR_IN%" == "log" (
    set _7ZIP_BARE_FLAGS=%_7ZIP_BARE_FLAGS% -w"%TEMP_DIR%"
  ) else set _7ZIP_BARE_FLAGS=%_7ZIP_BARE_FLAGS% -w"%SCRIPT_TEMP_CURRENT_DIR%"
) else set _7ZIP_BARE_FLAGS=%_7ZIP_BARE_FLAGS% -w"%SCRIPT_TEMP_CURRENT_DIR%"

if not defined GH_BACKUP_TEMP_DIR set "GH_BACKUP_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%\backup\bare"

set "GH_BACKUP_OUTPUT_TEMP_DIR=%GH_BACKUP_TEMP_DIR%/repo/%OWNER%/%REPO%"
set "GH_BACKUP_OUTPUT_DIR=%GH_BACKUP_BARE_REPO_DIR%/%OWNER%/%REPO%"

if defined TEMP_DIR call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%TEMP_DIR%%" >nul || exit /b 255

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%GH_BACKUP_OUTPUT_TEMP_DIR%%" >nul || exit /b 255

call :GIT clone --config core.longpaths=true -v --bare --mirror --recurse-submodules --progress "https://github.com/%%OWNER%%/%%REPO%%" "%%GH_BACKUP_OUTPUT_TEMP_DIR%%/db"
set LAST_ERROR=%ERRORLEVEL%

echo.

if %FLAG_CHECKOUT% EQU 0 goto SKIP_CHECKOUT

pushd "%GH_BACKUP_OUTPUT_TEMP_DIR%/db" && (
  call :GIT config --bool core.bare false
  echo.

  call :GIT clone --config core.longpaths=true -v --recurse-submodules --progress "%%GH_BACKUP_OUTPUT_TEMP_DIR%%/db" "%%GH_BACKUP_OUTPUT_TEMP_DIR%%/wc" || call set LAST_ERROR=%%ERRORLEVEL%%
  echo.

  rem restore bare repository
  call :GIT config --bool core.bare true
  echo.

  popd
)

:SKIP_CHECKOUT

if exist "%GH_BACKUP_OUTPUT_TEMP_DIR%/db/config" goto ARCHIVE
if exist "%GH_BACKUP_OUTPUT_TEMP_DIR%/wc/.git/config" goto ARCHIVE
goto SKIP_ARCHIVE

:ARCHIVE
if %FLAG_CHECKOUT% NEQ 0 (
  set "GH_BACKUP_BARE_REPO_FILE=%GH_BACKUP_BARED_CHECKOUT_REPO_FILE_NAME%"
) else set "GH_BACKUP_BARE_REPO_FILE=%GH_BACKUP_BARE_REPO_FILE_NAME%"

call set "GH_BACKUP_BARE_REPO_FILE=%%GH_BACKUP_BARE_REPO_FILE:{{OWNER}}=%OWNER%%%"
call set "GH_BACKUP_BARE_REPO_FILE=%%GH_BACKUP_BARE_REPO_FILE:{{REPO}}=%REPO%%%"
call set "GH_BACKUP_BARE_REPO_FILE=%%GH_BACKUP_BARE_REPO_FILE:{{DATE_TIME}}=%PROJECT_LOG_FILE_NAME_DATE_TIME%%%"

echo.Archiving backup directory...
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%GH_BACKUP_OUTPUT_DIR%%" && ^
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/add_files_to_archive.bat" "%%GH_BACKUP_TEMP_DIR%%" "*" "%%GH_BACKUP_OUTPUT_DIR%%/%%GH_BACKUP_BARE_REPO_FILE%%.7z" -sdel%%_7ZIP_BARE_FLAGS%%
set LAST_ERROR=%ERRORLEVEL%

echo.

:SKIP_ARCHIVE
if defined TEMP_DIR rmdir /S /Q "%TEMP_DIR%" >nul 2>nul

exit /b %LAST_ERROR%

:GIT
echo.^>git.exe %GIT_BARE_FLAGS% %*
git.exe %GIT_BARE_FLAGS% %*
exit /b
