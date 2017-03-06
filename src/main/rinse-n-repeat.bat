::<?xml version="1.0" encoding="Cp850"?><contenido><![CDATA[
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: PROGRAM ®rinse-n-repeat¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    It allows to test code you are not really sure how/if would work.
::
:: USAGE:
::    rinse-n-repeat.bat
::
:: DEPENDENCIES: :findOutInstall
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@ECHO OFF
SETLOCAL EnableDelayedExpansion
:::::::::::::::::::::::::::::::::: PREPROCESS ::::::::::::::::::::::::::::::::::
:: This variable will be used to manage the final ERRORLEVEL of the program.
SET errLvl=0

:: This program admits no parameters right now.
REM CALL :parseParameters %*
REM IF ERRORLEVEL 1 (
REM 	SET errLvl=1
REM 	GOTO :exit
REM )
CALL :findOutInstall "%~0" installDir
REM CALL :loadProperties "%installDir%\git-backup.properties"

:::::::::::::::::::::::::::::::::::: PROCESS :::::::::::::::::::::::::::::::::::
:: Change -1 to -9 for optimal compression size.
:: -AC can be used to remove the "archive" attribute of zipped files.
:: -AS can be used to process only the files with the "archive" attribute set.
:: Of course, it would be ideal to combine both.
REM ZIP -1 -r D:\prueba\prueba.zip .

FOR /F "skip=1 tokens=1-6 delims= " %%i IN ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
	IF NOT "%%~n"=="" (
		SET currentYear=%%n
		SET currentMonth=%%l
		IF !currentMonth! LSS 10 (
			SET currentMonth=0!currentMonth!
		)
		SET currentDay=%%i
		IF !currentDay! LSS 10 (
			SET currentDay=0!currentDay!
		)
		SET currentHour=%%j
		IF !currentHour! LSS 10 (
			SET currentHour=0!currentHour!
		)
		SET currentMinute=%%k
		IF !currentMinute! LSS 10 (
			SET currentMinute=0!currentMinute!
		)
		SET currentSecond=%%m
		IF !currentSecond! LSS 10 (
			SET currentSecond=0!currentSecond!
		)
		SET currentTimestamp=!currentYear!!currentMonth!!currentDay!!currentHour!!currentMinute!!currentSecond!
	)
)
SET currentTimestamp

GOTO :exit
:::::::::::::::::::::::::::::::::: POSTPROCESS :::::::::::::::::::::::::::::::::
:exit

EXIT /B %errLvl% & ENDLOCAL

:::::::::::::::::::::::::::::::::: SUBROUTINES :::::::::::::::::::::::::::::::::
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
