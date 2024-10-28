@echo off

rem USAGE:
rem   gen_workflows_config_from_last_backup.bat [<Flags>]

rem Description:
rem   Script generates `workflows*.lst` config file into `gen` subdirectory of
rem   the output config directory from the all latest backed up RestAPI JSON
rem   files using `repos-auth-with-workflows.lst` and
rem   `repos-with-workflows.lst` config files.
rem   The user can later compare the new `workflows*.lst` config file with the
rem   basic `workflows*.lst` config file to merge the difference into the
rem   latter.

rem <Flags>:
rem   -skip-sort
rem     Skip repository workflows list alphabetic sort and print as is from the
rem     json file.
rem   -no-path-prefix-remove
rem     Don't remove path prefix (`.github/workflows/`) from the output.
rem   -filter-inactive
rem     Filter only not "active" workflows.

setlocal

call "%%~dp0../__init__/script_init.bat" print . %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set FLAG_SKIP_SORT=0
set FLAG_NO_PATH_PREFIX_REMOVE=0
set FLAG_FILTER_INACTIVE=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-skip-sort" (
    set FLAG_SKIP_SORT=1
    set BARE_FLAGS=%BARE_FLAGS% -skip-sort
  ) else if "%FLAG%" == "-no-path-prefix-remove" (
    set FLAG_NO_PATH_PREFIX_REMOVE=1
    set BARE_FLAGS=%BARE_FLAGS% -no-path-prefix-remove
  ) else if "%FLAG%" == "-filter-inactive" (
    set FLAG_FILTER_INACTIVE=1
    set BARE_FLAGS=%BARE_FLAGS% -filter-inactive
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%%/gen" || exit /b

if %FLAG_FILTER_INACTIVE% EQU 0 (
  set "GEN_FILE_NAME_SUFFIX="
  set "GEN_FILE_COMMENT_LINE=# list of workflows in format: <owner>/<repo>:<workflow-id>"
) else (
  set "GEN_FILE_NAME_SUFFIX=-inactive"
  set "GEN_FILE_COMMENT_LINE=# list of inactive workflows in format: <owner>/<repo>:<workflow-id>"
)

(
  for /F "tokens=* delims="eol^= %%i in ("%GEN_FILE_COMMENT_LINE%") do echo.%%i
  echo.

  call "%%?~dp0%%print_repo_workflows_from_last_backup_by_config.bat"%%BARE_FLAGS%% -print-owner-repo-prefix -- "repos-auth-with-workflows.lst"
  echo.

  call "%%?~dp0%%print_repo_workflows_from_last_backup_by_config.bat"%%BARE_FLAGS%% -print-owner-repo-prefix -- "repos-with-workflows.lst"
) > "%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%/gen/workflows%GEN_FILE_NAME_SUFFIX%.lst"
