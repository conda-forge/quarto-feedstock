SET QUARTO_VENDOR_BINARIES=false
SET QUARTO_NO_SYMLINK=1
SET QUARTO_DENO=%LIBRARY_BIN%\deno.exe
SET DENO_BIN_PATH=%LIBRARY_BIN%\deno.exe
SET QUARTO_PANDOC=%LIBRARY_BIN%\pandoc.exe
SET QUARTO_ESBUILD=%LIBRARY_BIN%\esbuild.exe
SET QUARTO_DART_SASS=%LIBRARY_BIN%\sass.exe

:: This is patched in for conda. This is otherwise set as a constant in `configuration`
SET "QUARTO_VERSION=%PKG_VERSION%"

:: TODO: These should be set here, and they should override values in
::       win_configuration.bat, but batch scripts make that non-trivial.
@REM SET QUARTO_PACKAGE_PATH=%SRC_DIR%\package
@REM SET QUARTO_DIST_PATH=%LIBRARY_PREFIX%
@REM SET QUARTO_SHARE_PATH=%LIBRARY_PREFIX%\share\quarto

call configure.cmd
call package\src\quarto-bld.cmd prepare-dist

MKDIR %PREFIX%\etc\conda\activate.d
(
  :: The slash manipulation is to make sure that we only record one style of slash
  ::    for conda's prefix replacement. It seemed like there was a bug where if you
  ::    had a mix of slashes in different files, then not all of them would be replaced
  ::    correctly.
  echo SET "QUARTO_DENO=%LIBRARY_BIN:\=/%\deno.exe"
  echo SET "QUARTO_DENO_DOM=%DENO_DOM_PLUGIN%"
  :: this one is hacky because pandoc does not conform to the Library convention on windows.
  echo SET "QUARTO_PANDOC=%LIBRARY_BIN:\=/%\pandoc.exe"
  echo SET "QUARTO_ESBUILD=%LIBRARY_BIN:\=/%\esbuild.exe"
  echo SET "QUARTO_DART_SASS=%LIBRARY_BIN:\=/%\sass.bat"
  echo SET "QUARTO_SHARE_PATH=%LIBRARY_PREFIX:\=/%\share\quarto"
  echo SET "QUARTO_CONDA_PREFIX=%LIBRARY_PREFIX:\=/%"
) > %PREFIX%\etc\conda\activate.d\quarto.bat

 MKDIR %PREFIX%\etc\conda\deactivate.d
(
  echo SET QUARTO_DENO=
  echo SET QUARTO_DENO_DOM=
  echo SET QUARTO_PANDOC=
  echo SET QUARTO_ESBUILD=
  echo SET QUARTO_DART_SASS=
  echo SET QUARTO_SHARE_DIR=
  echo set QUARTO_CONDA_PREFIX=
) > %PREFIX%\etc\conda\deactivate.d\quarto.bat
