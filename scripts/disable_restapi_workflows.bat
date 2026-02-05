@echo off & goto DOC_END

rem USAGE:
rem   disable_restapi_workflows.bat [-+] [<flags>] [--] [<cmd> [<param0> [<param1>]]]

rem Description:
rem   Script to disable workflows using restapi request.

rem <flags>:
rem   -exit-on-error
rem     Don't continue on error.

rem -+:
rem   Separator to begin flags scope to parse.
rem --:
rem   Separator to end flags scope to parse.
rem   Required if `-+` is used.
rem   If `-+` is used, then must be used the same quantity of times.

rem <cmd> [<param0> [<param1>]]
rem   Continue from specific command with parameters.
rem   Useful to continue after the last error after specific command.
:DOC_END

setlocal

call "%%~dp0../__init__/script_init.bat" workflow restapi %%0 %%* || exit /b
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
set FLAG_FLAGS_SCOPE=0
set FLAG_EXIT_ON_ERROR=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG if "%FLAG%" == "-+" set /A FLAG_FLAGS_SCOPE+=1
if defined FLAG if "%FLAG%" == "--" set /A FLAG_FLAGS_SCOPE-=1

if defined FLAG (
  if "%FLAG%" == "-exit-on-error" (
    set FLAG_EXIT_ON_ERROR=1
  ) else if not "%FLAG%" == "-+" if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP

  if %FLAG_FLAGS_SCOPE% GTR 0 goto FLAGS_LOOP
)

if %FLAG_FLAGS_SCOPE% GTR 0 (
  echo;%?~%: error: not ended flags scope: [%FLAG_FLAGS_SCOPE%]: %FLAG%
  exit /b -255
) >&2

set "FROM_CMD=%~1"
set "FROM_CMD_PARAM0=%~2"
set "FROM_CMD_PARAM1=%~3"

rem must be empty
if defined FROM_CMD (
  if not defined SKIPPING_CMD echo;Skipping commands:
  set SKIPPING_CMD=1
)

set WORKFLOW_LISTS="%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%/workflows.lst"

for /F "usebackq eol=# tokens=1,* delims=:" %%i in (%WORKFLOW_LISTS%) do for /F "eol=# tokens=1,* delims=/" %%k in ("%%i") do (
  set "REPO_OWNER=%%k"
  set "REPO=%%l"
  set "WORKFLOW_ID=%%j"

  call "%%?~dp0%%.impl/update_skip_state.bat" "disable_restapi_repo_workflow.bat" "%%REPO_OWNER%%" "%%REPO%%"

  if not defined SKIPPING_CMD (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/call.bat" "%%?~dp0%%disable_restapi_repo_workflow.bat" "%%REPO_OWNER%%" "%%REPO%%" "%%WORKFLOW_ID%%" || if %FLAG_EXIT_ON_ERROR% NEQ 0 exit /b 255
    echo;---
  ) else call echo;* disable_restapi_repo_workflow.bat "%%REPO_OWNER%%" "%%REPO%%" "%%WORKFLOW_ID%%"
)

exit /b 0
