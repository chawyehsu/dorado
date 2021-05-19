@echo off
setlocal enabledelayedexpansion

@rem bee check
if not exist "%~dp0bee.exe" (
  echo Could not find bee.exe, please make sure it's next to beesvc.
  exit /b 0
)

@rem subcommands check
if "%~1" == "create" (
  call :create
) else if "%~1" == "delete" (
  call :delete
) else if "%~1" == "start" (
  call :start
) else if "%~1" == "status" (
  call :status
) else if "%~1" == "stop" (
  call :stop
) else (
  call :printhelp
)
exit /b !ERRORLEVEL!

:create
sc.exe query SwarmBeeSvc >nul
if !ERRORLEVEL! equ 0 (
  echo Swarm Bee serivce has already been created. skip creating.
  exit /b !ERRORLEVEL!
) else if !ERRORLEVEL! equ 1060 (
  sc.exe create SwarmBeeSvc binPath= "%~dp0bee.exe start --config=%~dp0data\bee.yaml" type= share start= delayed-auto displayName= "Bee" >nul
  if !ERRORLEVEL! equ 0 (
    sc.exe description SwarmBeeSvc "Bee, Swarm client." >nul
    echo Swarm Bee serivce has been successfully created.
    exit /b 0
  ) else if !ERRORLEVEL! equ 5 (
    echo Administrator privileges is required to create serivce.
    echo Use [sudo] or open an administrator console to run beesvc.
    exit /b !ERRORLEVEL!
  ) else (
    echo Unkown error on command 'sc.exe create SwarmBeeSvc'. (code: !ERRORLEVEL!^)
    exit /b !ERRORLEVEL!
  )
) else (
  echo Unkown error on command 'sc.exe query SwarmBeeSvc'. (code: !ERRORLEVEL!^)
  exit /b !ERRORLEVEL!
)

:delete
sc.exe query SwarmBeeSvc >nul
if !ERRORLEVEL! equ 1060 (
  echo Swarm Bee serivce has not been created yet, skip deleting.
  exit /b !ERRORLEVEL!
) else if !ERRORLEVEL! equ 0 (
  sc.exe stop SwarmBeeSvc >nul
  @rem 0: stop success or 1062: not been started
  if !ERRORLEVEL! equ 0 or !ERRORLEVEL! equ 1062 (
    sc.exe delete SwarmBeeSvc >nul
    if !ERRORLEVEL! equ 0 (
      echo Swarm Bee serivce has been successfully deleted.
      exit /b 0
    ) else if !ERRORLEVEL! equ 5 (
      echo Administrator privileges is required to delete serivce.
      echo Use [sudo] or open an administrator console to run beesvc.
      exit /b !ERRORLEVEL!
    ) else (
      echo Unkown error on command 'sc.exe delete SwarmBeeSvc'. (code: !ERRORLEVEL!^)
      exit /b !ERRORLEVEL!
    )
  ) else if !ERRORLEVEL! equ 5 (
    echo Administrator privileges is required to delete serivce.
    echo Use [sudo] or open an administrator console to run beesvc.
    exit /b !ERRORLEVEL!
  ) else (
    echo Unkown error on command 'sc.exe stop SwarmBeeSvc'. (code: !ERRORLEVEL!^)
    exit /b !ERRORLEVEL!
  )
) else (
  echo Unkown error on command 'sc.exe query SwarmBeeSvc'. (code: !ERRORLEVEL!^)
  exit /b !ERRORLEVEL!
)

:start
sc.exe query SwarmBeeSvc >nul
if !ERRORLEVEL! equ 1060 (
  echo Swarm Bee serivce has not been created yet, please use '%~n0 create' first.
  exit /b !ERRORLEVEL!
) else if !ERRORLEVEL! equ 0 (
  sc.exe start SwarmBeeSvc >nul
  if !ERRORLEVEL! equ 0 (
    echo Swarm Bee serivce has been successfully started.
    exit /b 0
  ) else if !ERRORLEVEL! equ 5 (
    echo Administrator privileges is required to start serivce.
    echo Use [sudo] or open an administrator console to run beesvc.
    exit /b !ERRORLEVEL!
  ) else (
    echo Unkown error on command 'sc.exe start SwarmBeeSvc'. (code: !ERRORLEVEL!^)
    exit /b !ERRORLEVEL!
  )
) else (
  echo Unkown error on command 'sc.exe query SwarmBeeSvc'. (code: !ERRORLEVEL!^)
  exit /b !ERRORLEVEL!
)

:status
sc.exe query SwarmBeeSvc >nul
if !ERRORLEVEL! equ 1060 (
  echo Swarm Bee serivce has not been created yet, please use '%~n0 create' first.
  exit /b !ERRORLEVEL!
) else if !ERRORLEVEL! equ 0 (
  sc.exe query SwarmBeeSvc | findstr.exe "RUNNING" >nul
  if !ERRORLEVEL! equ 0 (
    echo RUNNING.
    exit /b 0
  )

  echo STOPPED.
  exit /b 0
) else (
  echo Unkown error on command 'sc.exe query SwarmBeeSvc'. (code: !ERRORLEVEL!^)
  exit /b !ERRORLEVEL!
)

:stop
sc.exe query SwarmBeeSvc >nul
if !ERRORLEVEL! equ 1060 (
  echo Swarm Bee serivce has not been created yet, skip stopping.
  exit /b !ERRORLEVEL!
) else if !ERRORLEVEL! equ 0 (
  sc.exe stop SwarmBeeSvc >nul
  @rem 0: stop success or 1062: not been started
  if !ERRORLEVEL! equ 5 (
    echo Administrator privileges is required to stop serivce.
    echo Use [sudo] or open an administrator console to run beesvc.
    exit /b !ERRORLEVEL!
  ) else if !ERRORLEVEL! equ 0 or !ERRORLEVEL! equ 1062 (
    echo Swarm Bee serivce has been successfully stopped.
    exit /b 0
  ) else (
    echo Unkown error on command 'sc.exe stop SwarmBeeSvc'. (code: !ERRORLEVEL!^)
    exit /b !ERRORLEVEL!
  )
) else (
  echo Unkown error on command 'sc.exe query SwarmBeeSvc'. (code: !ERRORLEVEL!^)
  exit /b !ERRORLEVEL!
)

:printhelp
echo %~n0 0.1.0
echo Copyright (c) Chawye Hsu^<chawyehsu@hotmail.com^>
echo A tool for Swarm Bee Windows service management
echo.
echo USAGE:
echo     %~n0 [SUBCOMMAND]
echo.
echo SUBCOMMANDS:
echo     create        Create Swarm Bee serivce
echo     delete        Delete Swarm Bee serivce
echo     start         Start Swarm Bee serivce
echo     status        Display Swarm Bee serivce status
echo     stop          Stop Swarm Bee serivce
echo     help          Display this help and exit
echo.
exit /b 0
