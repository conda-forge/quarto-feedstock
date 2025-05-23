SET QUARTO_VENDOR_BINARIES=false
SET QUARTO_NO_SYMLINK=1
SET QUARTO_DENO=%LIBRARY_BIN%\deno.exe
SET DENO_BIN_PATH=%LIBRARY_BIN%\deno.exe
SET QUARTO_PANDOC=%LIBRARY_BIN%\pandoc.exe
SET QUARTO_ESBUILD=%LIBRARY_BIN%\esbuild.exe
SET QUARTO_DART_SASS=%LIBRARY_BIN%\sass.exe
SET QUARTO_TYPST=%LIBRARY_BIN%\typst.exe

:: Alter the configuration file with a dynamic value containing the full
:: package version (e.g. 1.3.340). The only thing allowed in this file is
:: export statements with static assignments, so we use a combination of a
:: patch to update the source code to remove the original assignment and a
:: build-time update to place the dynamic build-time PKG_VERSION as a static
:: value.
:: More context: https://github.com/conda-forge/quarto-feedstock/pull/7
echo set "QUARTO_VERSION=%PKG_VERSION%" >> configuration

:: TODO: These should be set here, and they should override values in
::       win_configuration.bat, but batch scripts make that non-trivial.
@REM SET QUARTO_PACKAGE_PATH=%SRC_DIR%\package
@REM SET QUARTO_DIST_PATH=%LIBRARY_PREFIX%
@REM SET QUARTO_SHARE_PATH=%LIBRARY_PREFIX%\share\quarto

call configure.cmd
:: this shouldn't be strictly necessary, since configure.cmd should theoretically set it, but the builds don't
:: seem to be picking this up. Leaving this in as a hack for now.
set QUARTO_VERSION=%PKG_VERSION%

call package\src\quarto-bld.cmd prepare-dist
call package\src\quarto-bld.cmd make-installer-dir

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
  echo SET "QUARTO_TYPST=%LIBRARY_BIN:\=/%\typst.exe"
  echo SET "QUARTO_SHARE_PATH=%LIBRARY_PREFIX:\=/%\share\quarto"
  echo SET "QUARTO_CONDA_PREFIX=%LIBRARY_PREFIX:\=/%"
) > %PREFIX%\etc\conda\activate.d\quarto.bat

(
  echo $env:QUARTO_DENO="%LIBRARY_BIN:\=/%\deno.exe"
  echo $env:QUARTO_DENO_DOM="%DENO_DOM_PLUGIN%"
  echo $env:QUARTO_PANDOC="%LIBRARY_BIN:\=/%\pandoc.exe"
  echo $env:QUARTO_ESBUILD="%LIBRARY_BIN:\=/%\esbuild.exe"
  echo $env:QUARTO_DART_SASS="%LIBRARY_BIN:\=/%\sass.bat"
  echo $env:QUARTO_TYPST="%PREFIX:\=/%\bin\typst.exe"
  echo $env:QUARTO_SHARE_PATH="%LIBRARY_PREFIX:\=/%\share\quarto"
  echo $env:QUARTO_CONDA_PREFIX="%LIBRARY_PREFIX:\=/%"
) > %PREFIX%\etc\conda\activate.d\quarto.ps1

(
  echo export QUARTO_DENO="%LIBRARY_BIN:\=/%\deno.exe"
  echo export QUARTO_DENO_DOM="%DENO_DOM_PLUGIN%"
  echo export QUARTO_PANDOC="%LIBRARY_BIN:\=/%\pandoc.exe"
  echo export QUARTO_ESBUILD="%LIBRARY_BIN:\=/%\esbuild.exe"
  echo export QUARTO_DART_SASS="%LIBRARY_BIN:\=/%\sass.bat"
  echo export QUARTO_TYPST="%PREFIX:\=/%\bin\typst.exe"
  echo export QUARTO_SHARE_PATH="%LIBRARY_PREFIX:\=/%\share\quarto"
  echo export QUARTO_CONDA_PREFIX="%LIBRARY_PREFIX:\=/%"
) > %PREFIX%\etc\conda\activate.d\quarto.sh

MKDIR %PREFIX%\etc\conda\deactivate.d
(
  echo SET QUARTO_DENO=
  echo SET QUARTO_DENO_DOM=
  echo SET QUARTO_PANDOC=
  echo SET QUARTO_ESBUILD=
  echo SET QUARTO_DART_SASS=
  echo SET QUARTO_TYPST=
  echo SET QUARTO_SHARE_PATH=
  echo SET QUARTO_CONDA_PREFIX=
) > %PREFIX%\etc\conda\deactivate.d\quarto.bat

(
  echo Remove-Item -Path Env:\QUARTO_DENO
  echo Remove-Item -Path Env:\QUARTO_DENO_DOM
  echo Remove-Item -Path Env:\QUARTO_PANDOC
  echo Remove-Item -Path Env:\QUARTO_ESBUILD
  echo Remove-Item -Path Env:\QUARTO_DART_SASS
  echo Remove-Item -Path Env:\QUARTO_TYPST
  echo Remove-Item -Path Env:\QUARTO_SHARE_PATH
  echo Remove-Item -Path Env:\QUARTO_CONDA_PREFIX
) > %PREFIX%\etc\conda\deactivate.d\quarto.ps1

(
  echo unset QUARTO_DENO
  echo unset QUARTO_DENO_DOM
  echo unset QUARTO_PANDOC
  echo unset QUARTO_ESBUILD
  echo unset QUARTO_DART_SASS
  echo unset QUARTO_TYPST
  echo unset QUARTO_SHARE_PATH
  echo unset QUARTO_CONDA_PREFIX
) > %PREFIX%\etc\conda\deactivate.d\quarto.sh
