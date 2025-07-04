@echo off

rem USAGE:
rem   backup_checkouted_all_auth_repos.bat [<Flags>] [--] [<cmd> [<param0> [<param1>]]]

rem Description:
rem   Script to backup all private repositories with credentials.
rem   Backup excludes a bare repository backup and used only NOT bare variant
rem   with submodules recursion.

rem <Flags>:
rem   --
rem     Stop flags parse.
rem   -exit-on-error
rem     Don't continue on error.

rem <cmd> [<param0> [<param1>]]
rem   Continue from specific command with parameters.
rem   Useful to continue after the last error after specific command.

setlocal

call "%%~dp0../__init__/script_init.bat" backup checkout %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

set /A NEST_LVL-=1

exit /b %LAST_ERROR%

:MAIN
pushd "%?~dp0%" && (
  call :MAIN_IMPL %%* || ( popd & goto EXIT )
  popd
)

:EXIT
exit /b

:MAIN_IMPL
rem script flags
set FLAG_EXIT_ON_ERROR=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-exit-on-error" (
    set FLAG_EXIT_ON_ERROR=1
  ) else if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "FROM_CMD=%~1"
set "FROM_CMD_PARAM0=%~2"
set "FROM_CMD_PARAM1=%~3"

set HAS_AUTH_USER=0

if defined GH_AUTH_USER if not "%GH_AUTH_USER%" == "{{USER}}" ^
if defined GH_AUTH_PASS if not "%GH_AUTH_PASS%" == "{{PASS}}" set HAS_AUTH_USER=1

if %HAS_AUTH_USER% EQU 0 (
  echo;%?~%: error: GH_AUTH_USER or GH_AUTH_PASS is not defined.
  exit /b 255
) >&2

rem must be empty
if defined FROM_CMD (
  if not defined SKIPPING_CMD echo;Skipping commands:
  set SKIPPING_CMD=1
)

for /F "usebackq eol=# tokens=1,* delims=/" %%i in ("%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%/repos-auth.lst") do (
  set "REPO_OWNER=%%i"
  set "REPO=%%j"

  call "%%?~dp0%%.impl/update_skip_state.bat" "backup_checkouted_auth_repo.bat" "%%REPO_OWNER%%" "%%REPO%%"

  if not defined SKIPPING_CMD (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%?~dp0%%backup_checkouted_auth_repo.bat" "%%REPO_OWNER%%" "%%REPO%%" || if %FLAG_EXIT_ON_ERROR% NEQ 0 exit /b 255
    echo;---
  ) else call echo;* backup_checkouted_auth_repo.bat "%%REPO_OWNER%%" "%%REPO%%"
)

exit /b 0
