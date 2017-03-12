::<?xml version="1.0" encoding="Cp850"?><contenido><![CDATA[
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: PROGRAM ®aBackup¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    A quick and dirty backup tool for Windows.
::
:: USAGE:
::    aBackup.bat
::
:: DEPENDENCIES: :findOutInstall :loadProperties :validateProgramAvailable
::               :getCurrentTimestampNumber
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@ECHO OFF
SETLOCAL EnableDelayedExpansion
:::::::::::::::::::::::::::::::::: PREPROCESS ::::::::::::::::::::::::::::::::::
:: This variable will be used to manage the final ERRORLEVEL of the program.
SET errLvl=0

CALL :findOutInstall "%~0" installDir
CALL :loadProperties "%installDir%\aBackup.properties"
CALL :parseParameters %*
SET errLvl=%ERRORLEVEL%
IF "%errLvl%" NEQ "0" (
 	GOTO :exit
)

:::::::::::::::::::::::::::::::::::: PROCESS :::::::::::::::::::::::::::::::::::
CALL :%param.command%
SET errLvl=%ERRORLEVEL%

GOTO :exit

:: Counts localGitRepository properties.
SET localGitRepository.length=0
FOR /F "delims=ª" %%i IN ('SET localGitRepository[') DO (
	SET /A "localGitRepository.length+=1"
)
SET /A "localGitRepository.lastIndex=localGitRepository.length-1"

:: Chooses to work with the last existent directory.
FOR /L %%i IN (0,1,%localGitRepository.lastIndex%) DO (
	IF EXIST "!localGitRepository[%%i]!" (
		SET chosenLocalGitRepository=!localGitRepository[%%i]!
	)
)
ECHO Backing up to "%chosenLocalGitRepository%"
PUSHD "%chosenLocalGitRepository%"

:: Verifies whether the local Git repository is in an appropiate state to copy 
:: files to it without messing up some work in progress.
::TODO: Extract to a subroutine.
:: [PROTOTYPE] of how to dump a command output to an array of variables.
SET var.length=0
FOR /F "usebackq tokens=*" %%i IN (`git status`) DO (
	SET var[!var.length!]=%%i
	SET /A "var.length+=1"
)

IF "%var[0]%" NEQ "On branch master" (
	ECHO ERROR: Target local repository "%chosenLocalGitRepository%" not on branch master.
	SET errLvl=1
	GOTO :exit
)

IF "%var[1]%" NEQ "Your branch is up-to-date with 'origin/master'." (
	ECHO ERROR: Target local repository "%chosenLocalGitRepository%" not up-to-date with its remote. Pull it and try again.
	SET errLvl=1
	GOTO :exit
)

IF "%var[2]%" NEQ "nothing to commit, working tree clean" (
	ECHO ERROR: Target local repository "%chosenLocalGitRepository%" working directory not clean.
	SET errLvl=1
	GOTO :exit
)

SET /P answer=Did you remember to remove all sensible data from whitelisted files? [y/N]:
IF /I NOT "%answer%" == "y" (
	ECHO Backup aborted.
	SET errLvl=-1
	GOTO :exit
)

FOR /F "usebackq eol=# tokens=* delims=ª" %%i IN ("%installDir%\git-backup.whitelist") DO (
	CALL :doCopy "%%i"
)

:: Resets variable "answer". Otherwise, previous value would stay if user just 
:: presses ENTER
SET answer=
SET /P answer=Commit changes? [y/N]:
IF /I NOT "%answer%" == "y" (
	ECHO Backup finished.
	SET errLvl=-1
	GOTO :exit
)
git add .
git commit -a -m "Periodic backup of files."

:: Resets variable "answer". Otherwise, previous value would stay if user just 
:: presses ENTER
SET answer=
SET /P answer=Push changes? [y/N]:
IF /I NOT "%answer%" == "y" (
	ECHO Backup finished.
	SET errLvl=-1
	GOTO :exit
)
git push

GOTO :exit
:::::::::::::::::::::::::::::::::: POSTPROCESS :::::::::::::::::::::::::::::::::
:exit

EXIT /B %errLvl% & ENDLOCAL

:::::::::::::::::::::::::::::::::: SUBROUTINES :::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®parseParameters¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Turns program actual parameters in environment variables that the program
:: can use.
:: 
:: USAGE: 
::    CALL :parseParameters %*
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:parseParameters
:: Since parameters can contain quotes and other string separators, they it is 
:: not reliable to compare them with the empty string. Instead, a variable is 
:: set, and if it is defined aftewards, it means that something has been passed 
:: as parameter.
SET aux=%*
IF NOT DEFINED aux (
	TYPE "%installDir%\help.txt"
	EXIT /B -1
)
ECHO DEBUG:aux=%aux%
SET aux=

IF "%~1" == "now" (
	SET param.command=now
) ELSE IF "%~1" == "help" (
	SET param.command=help
	SET param.helpTopic=%~2
	EXIT /B 0
) ELSE (
	ECHO ERROR: Unknown command ®%~1¯.
	EXIT /B 1
)
SHIFT

IF "%~1" == "" (
	ECHO ERROR: Missing parameter {repository}.
	EXIT /B 1
)

SET param.repository=%~1
IF "%~2" == "" (
	SET param.source=.
) ELSE (
	SET param.source=%param.repository%
	SET param.repository=%~2
)

EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®parseParameters¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®help¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Displays program help files.
:: 
:: USAGE: 
::    CALL :help
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:help
SETLOCAL EnableDelayedExpansion

IF NOT DEFINED param.helpTopic (
	TYPE "%installDir%\help.txt"
) ELSE IF "%param.helpTopic%" == "now" (
	TYPE "%installDir%\help-now.txt"
) ELSE (
	ECHO ERROR: Unknown command ®%param.helpTopic%¯.
	EXIT /B 1
)

EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®help¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®now¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Backups directory param.source into directory param.repository.
:: 
:: USAGE: 
::    CALL :now
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:now
SETLOCAL EnableDelayedExpansion

ECHO DEBUG: param.command=%param.command%
ECHO DEBUG: param.source=%param.source%
ECHO DEBUG: param.repository=%param.repository%

CALL :getCurrentTimestampNumber currentTimestamp
ECHO DEBUG: currentTimestamp=%currentTimestamp%

:: Change -1 to -9 for optimal compression size.
:: -AC can be used to remove the "archive" attribute of zipped files.
:: -AS can be used to process only the files with the "archive" attribute set.
:: Of course, it would be ideal to combine both.
>NUL ZIP -%compressionLevel% -r "%param.repository%\aBackup-%currentTimestamp%.zip" "%param.source%"
SET errLvl=%ERRORLEVEL%

ENDLOCAL & EXIT /B %errLvl%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®help¯
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

SET extension=%~x1
:: If the program is invoked without extension, it won't be found in the PATH. 
:: Adds the extension and recursively invokes :findoutInstall.
IF "%extension%" == "" (
	CALL :findOutInstall "%~1.bat" installDir
	GOTO :findOutInstall.end
) ELSE (
	SET installDir=%~$PATH:1
)

IF "%installDir%" EQU "" (
	SET installDir=%~f1
)

CALL :removeFileName "%installDir%" _removeFileName
SET installDir=%_removeFileName%

:findOutInstall.end
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

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®getCurrentTimestampNumber¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Returns a number made by concatenating current year, month, day of month, 
:: hours, minutes and seconds.
::
:: USAGE: 
::    CALL :getCurrentTimestampNumber ®retVar¯
:: WHERE...
::    ®retVar¯: Name of a variable (existent or not) by means of which the 
::              number will be returned.
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getCurrentTimestampNumber
SETLOCAL EnableDelayedExpansion
SET retVar=%1

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

ENDLOCAL & SET "%retVar%=%currentTimestamp%" & EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®getCurrentTimestampNumber¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::]]></contenido>
