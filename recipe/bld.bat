SET QUARTO_VENDOR_BINARIES=false
SET QUARTO_NO_SYMLINK=1

:: Rust on Windows defaults to statically linking ucrt, but conda-forge MSVC
:: libraries are dynamically linked to ucrt.dll. Without this flag the
:: typst-gather Rust build can fail to link against conda-provided C libs.
:: Context: https://github.com/conda-forge/deno-feedstock/pull/196#issuecomment-4273043821
SET RUSTFLAGS=-C target-feature=-crt-static

:: With {{ compiler('c') }} / {{ compiler('rust') }} in build:, conda-build
:: uses dual-prefix mode, so build-time tools live in %BUILD_PREFIX%\Library,
:: not %PREFIX%\Library (which %LIBRARY_BIN% resolves to).
SET QUARTO_DENO=%BUILD_PREFIX%\Library\bin\deno.exe
SET DENO_BIN_PATH=%BUILD_PREFIX%\Library\bin\deno.exe
SET QUARTO_PANDOC=%BUILD_PREFIX%\Library\bin\pandoc.exe
SET QUARTO_ESBUILD=%BUILD_PREFIX%\Library\bin\esbuild.exe
SET QUARTO_DART_SASS=%BUILD_PREFIX%\Library\bin\sass.exe
SET QUARTO_TYPST=%BUILD_PREFIX%\Library\bin\typst.exe

:: Alter the configuration file with a dynamic value containing the full
:: package version (e.g. 1.3.340). The only thing allowed in this file is
:: export statements with static assignments, so we strip the upstream
:: assignment and append a new one using the build-time PKG_VERSION.
:: More context: https://github.com/conda-forge/quarto-feedstock/pull/7
pwsh -Command "(Get-Content configuration) -notmatch '^export QUARTO_VERSION=' | Set-Content configuration"
echo set "QUARTO_VERSION=%PKG_VERSION%" >> configuration

:: TODO: These should be set here, and they should override values in
::       win_configuration.bat, but batch scripts make that non-trivial.
@REM SET QUARTO_PACKAGE_PATH=%SRC_DIR%\package
@REM SET QUARTO_DIST_PATH=%LIBRARY_PREFIX%
@REM SET QUARTO_SHARE_PATH=%LIBRARY_PREFIX%\share\quarto

:: conda-forge's Rust toolchain sets CARGO_BUILD_TARGET to the host triple,
:: so `cargo build` writes to target\<triple>\release\ instead of the default
:: target\release\. Upstream configure.cmd hardcodes the default path for the
:: COPY after cargo build. Patch it in-place.
pwsh -Command "(Get-Content configure.cmd) -replace 'package\\typst-gather\\target\\release', 'package\typst-gather\target\%CARGO_BUILD_TARGET%\release' | Set-Content configure.cmd"

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
