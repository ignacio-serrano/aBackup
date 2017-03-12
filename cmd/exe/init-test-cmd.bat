::<?xml version="1.0" encoding="Cp850"?><contenido><![CDATA[
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: PROGRAM ®init-test-cmd¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    ${description}
::
:: USAGE:
::    init-test-cmd.bat
::
:: DEPENDENCIES: :findOutInstall :loadProperties
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@ECHO OFF
SETLOCAL EnableDelayedExpansion
:::::::::::::::::::::::::::::::::: PREPROCESS ::::::::::::::::::::::::::::::::::
:: This program admits no parameters right now.
REM CALL :parseParameters %*
REM IF ERRORLEVEL 1 (
REM 	SET errLvl=1
REM 	GOTO :exit
REM )
CALL :findOutInstall "%~0" installDir
CALL :loadProperties "%installDir%\init-test-cmd.properties"

:::::::::::::::::::::::::::::::::::: PROCESS :::::::::::::::::::::::::::::::::::
TITLE %title%
SET addToPath=%installDir%\..\..\src\main

:: Directory change is lost on ENDLOCAL. Instead, it PUSHD from the intended 
:: final directory and POPD after ENDLOCAL (achieving the same result).
CD %installDir%\%startIn%
PUSHD C:

GOTO :exit
:::::::::::::::::::::::::::::::::: POSTPROCESS :::::::::::::::::::::::::::::::::
:exit
ENDLOCAL & SET PATH=%PATH%;%addToPath%
POPD
EXIT /B 0

:::::::::::::::::::::::::::::::::: SUBROUTINES :::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®doCopy¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Copies the directory or file passed as parameter using the most appropiate 
:: method.
:: 
:: USAGE: 
::    CALL :doCopy ®["]path["]¯
:: WHERE...
::    ®["]path["]¯: Path of the file or directory to copy, relative to the 
::                  directory where git-backup.bat lives. If the path contains 
::                  white spaces, it must be enclosed in double quotes. It is 
::                  optional otherwise.
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:doCopy
SETLOCAL

SET errLvl=0
SET srcPath=%installDir%\%~1
SET tgtPath=%chosenLocalGitRepository%\%~1

:: If the path is a directory (note the trailing "\") uses ROBOCOPY. Most flags 
:: are just to prevent ROBOCOPY to output anything. "/E" is to ensure that 
:: empty subfolders are copied as well.
:: If the path is a file uses COPY. It could be done by means of ROBOCOPY but 
:: syntax would more complex.
:: If the path doesn't exist simply warns that it doesn't exist and will be 
:: skipped.
IF EXIST "%srcPath%\" (
	ECHO Copying "%srcPath%"
	ROBOCOPY "%srcPath%" "%tgtPath%" /E /NFL /NDL /NJH /NJS /NP

) ELSE IF EXIST "%srcPath%" (
	ECHO Copying "%srcPath%"
	>NUL COPY "%srcPath%" "%tgtPath%"
) ELSE (
	ECHO SKIPPING "%srcPath%" ^(doesn't exist^)
)

ENDLOCAL & EXIT /B %errLvl%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®doCopy¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®findOutInstall¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Computes the absolute path of the .bat passed as parameter. This 
:: subroutine helps identify the installation directory of .bat script which 
:: invokes it.
:: 
:: USAGE: 
::    CALL :findOutInstall "%~0" ®retVar¯
:: WHERE...
::    ®retVar¯: Name of a variable (existent or not) by means of which the 
::              directory will be returned.
::
:: DEPENDENCIES: :removeFileName
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:findoutInstall
SETLOCAL
SET retVar=%2

SET installDir=%~$PATH:1
IF "%installDir%" EQU "" (
	SET installDir=%~f1
)

CALL :removeFileName "%installDir%" _removeFileName
SET installDir=%_removeFileName%

ENDLOCAL & SET %retVar%=%installDir%
EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®findOutInstall¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®removeFileName¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Removes the file name from a path.
::
:: USAGE: 
::    CALL :removeFileName ®["]path["]¯ ®retVar¯
:: WHERE...
::    ®["]path["]¯: Path from which the file name is to be removed. If the path
::                  contains white spaces, it must be enclosed in double quotes.
::                  It is optional otherwise.
::    ®retVar¯:     Name of a variable (existent or not) by means of which the 
::                  directory will be returned.
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:removeFileName
SETLOCAL
SET retVar=%2
SET path=%~dp1

PUSHD %path%
SET path=%CD%
POPD

ENDLOCAL & SET %retVar%=%path%
EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®removeFileName¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®loadProperties¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Reads a propreties file and loads it in environment variables.
::
:: USAGE: 
::    CALL :loadProperties "®properties file path¯"
:: WHERE...
::    ®properties file path¯: Absolute or relative path of the properties file 
::                            to read.
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:loadProperties
FOR /F "usebackq eol=# tokens=1 delims=ª" %%i IN ("%~1") DO (
	SET %%i
)
EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®loadProperties¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®validateProgramAvailable¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Verifies whether an executable file is present in PATH environment 
:: variable.
::
:: USAGE: 
::    CALL :validateProgramAvailable ®["]program["]¯
:: WHERE...
::    ®["]program["]¯: Name of the executable file. If the file name contains 
::                     white spaces, it must be enclosed in double quotes. It 
::                     is optional otherwise.
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:validateProgramAvailable
SETLOCAL
SET errLvl=0
IF "%~$PATH:1" == "" (
	ECHO ERROR: Program ®%1¯ cannot be found in PATH. git-backup requires a ®%1¯ installation to work.
	SET errLvl=1
)
ENDLOCAL & EXIT /B %errLvl%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®validateProgramAvailable¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::]]></contenido>
