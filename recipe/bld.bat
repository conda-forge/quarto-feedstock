bin\quarto check

robocopy bin %LIBRARY_BIN% /E
robocopy share %LIBRARY_PREFIX%\share\quarto /E

 MKDIR %PREFIX%\etc\conda\activate.d
(
  :: The slash manipulation is to make sure that we only record one style of slash
  ::    for conda's prefix replacement. It seemed like there was a bug where if you
  ::    had a mix of slashes in different files, then not all of them would be replaced
  ::    correctly.
  echo SET "QUARTO_SHARE_PATH=%LIBRARY_PREFIX:\=/%\share\quarto"
) > %PREFIX%\etc\conda\activate.d\quarto.bat


 MKDIR %PREFIX%\etc\conda\deactivate.d
(
  echo SET QUARTO_SHARE_DIR=
) > %PREFIX%\etc\conda\deactivate.d\quarto.bat

