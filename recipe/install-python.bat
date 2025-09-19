@echo off

REM Install the Quarto Python API package
pip install quarto-cli --no-deps --ignore-installed --no-cache-dir -vvv
if errorlevel 1 exit 1