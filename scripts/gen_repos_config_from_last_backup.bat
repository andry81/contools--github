@echo off

rem USAGE:
rem   gen_repos_config_from_last_backup.bat [<Flags>]

rem Description:
rem   Script generates `repos*.lst` and `repos-auth.lst` config files into
rem   `gen` subdirectory of the output config directory from the latest
rem   backed up RestAPI JSON file using `accounts-user.lst` config file.
rem   The user can later compare the new `repos*.lst` and `repos-auth.lst`
rem   config files with the basic `repos*.lst` and `repos-auth.lst`
rem   config files to merge the difference into the latter.

rem <Flags>:
rem   -skip-sort
rem     Skip repository list alphabetic sort and print as is from the
rem     json file.
rem   -filter-forked
rem     Filter only forked repositories.

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
set FLAG_FILTER_FORKED=0
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
  ) else if "%FLAG%" == "-filter-forked" (
    set FLAG_FILTER_FORKED=1
    set BARE_FLAGS=%BARE_FLAGS% -filter-forked
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%%/gen" || exit /b

if %FLAG_FILTER_FORKED% EQU 0 (
  (
    for /F "eol= tokens=* delims=" %%i in ("# list of repositories in format: <owner>/<repo>") do echo.%%i
    echo.

    call "%%?~dp0%%print_repos_from_last_backup_by_config.bat"%%BARE_FLAGS%% -print-full-name -filter-source -- "accounts-user.lst"
  ) > "%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%/gen/repos.lst"

  (
    for /F "eol= tokens=* delims=" %%i in ("# list of required authentication repositories in format: <owner>/<repo>") do echo.%%i
    echo.

    call "%%?~dp0%%print_repos_from_last_backup_by_config.bat"%%BARE_FLAGS%% -print-full-name -filter-source -filter-auth -- "accounts-user.lst"
  ) > "%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%/gen/repos-auth.lst"
) else (
  (
    for /F "eol= tokens=* delims=" %%i in ("# list of forked as child repositories in format: <owner>/<repo>") do echo.%%i
    echo.

    call "%%?~dp0%%print_repos_from_last_backup_by_config.bat"%%BARE_FLAGS%% -print-full-name -filter-forked -- "accounts-user.lst"
  ) > "%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%/gen/repos-forked.lst"
)
