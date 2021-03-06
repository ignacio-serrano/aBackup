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
:: Since parameters can contain quotes and other string separators, it is 
:: not reliable to compare them with the empty string. Instead, a variable is 
:: set, and if it is defined aftewards, it means that something has been passed 
:: as parameter.
SET aux=%*
IF NOT DEFINED aux (
	TYPE "%installDir%\help.txt"
	EXIT /B -1
)
REM ECHO DEBUG:aux=%aux%
SET aux=

IF "%~1" == "now" (
	SET param.command=%~1
	IF "%~2" == "" (
		SET "param.repository= "
	) ELSE (
		SET param.repository=%~2
	)
	
	IF "%~3" == "" (
		SET param.source=.
	) ELSE (
		SET param.source=%param.repository%
		SET param.repository=%~3
	)
) ELSE IF "%~1" == "init" (
	SET param.command=%~1
	IF "%~2" == "" (
		ECHO ERROR: Missing parameter {repository}.
		EXIT /B 1
	)

	SET param.repository=%~2
	IF "%~3" == "" (
		SET param.source=.
	) ELSE (
		SET param.source=%param.repository%
		SET param.repository=%~3
	)
) ELSE IF "%~1" == "restore" (
	SET param.command=%~1
	IF "%~2" == "" (
		SET "param.repository= "
	) ELSE (
		SET param.repository=%~2
	)
	
	IF "%~3" == "" (
		SET param.target=.
	) ELSE (
		SET param.target=%~3
	)
) ELSE IF "%~1" == "help" (
	SET param.command=%~1
	SET param.helpTopic=%~2
	EXIT /B 0
) ELSE (
	ECHO ERROR: Unknown command ®%~1¯.
	EXIT /B 1
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
	TYPE "%installDir%\help-%param.helpTopic%.txt"
) ELSE IF "%param.helpTopic%" == "init" (
	TYPE "%installDir%\help-%param.helpTopic%.txt"
) ELSE IF "%param.helpTopic%" == "restore" (
	TYPE "%installDir%\help-%param.helpTopic%.txt"
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

REM ECHO DEBUG: param.command=%param.command%
REM ECHO DEBUG: param.source=%param.source%
REM ECHO DEBUG: param.repository=%param.repository%

CALL :validateProgramAvailable zip.exe
SET errLvl=%ERRORLEVEL%
IF "%errLvl%" NEQ "0" (
	GOTO :exit
)

IF "%param.repository%" == " " (
	REM ECHO DEBUG: Repo is SPACE.
	IF EXIST "%param.source%\.aBackup" (
		CALL :loadProperties "%param.source%\.aBackup"
		IF EXIST "!repository!" (
			SET param.repository=!repository!
		) ELSE (
			ECHO ERROR: Broken meta data file ®%param.source%\.aBackup¯.
			EXIT /B 2
		)
	) ELSE (
		CALL :canonicalizePath "%param.source%" canonicalPath
		
		ECHO ERROR: ®!canonicalPath!¯ is not initialized and parameter {repository} is not specified.
		EXIT /B 1
	)
)

CALL :getCurrentTimestampNumber currentTimestamp
REM ECHO DEBUG: currentTimestamp=%currentTimestamp%

:: Change -1 to -9 for optimal compression size.
:: -AC can be used to remove the "archive" attribute of zipped files.
:: -AS can be used to process only the files with the "archive" attribute set.
:: Of course, it would be ideal to combine both.
>NUL ZIP -%compressionLevel% -r "%param.repository%\aBackup-%currentTimestamp%.zip" "%param.source%" -x .aBackup
SET errLvl=%ERRORLEVEL%

ENDLOCAL & EXIT /B %errLvl%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®now¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®restore¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Restores a backup from the repository to param.target.
:: 
:: USAGE: 
::    CALL :restore
::
:: DEPENDENCIES: :strLen :validateProgramAvailable
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:restore
SETLOCAL EnableDelayedExpansion

CALL :validateProgramAvailable unzip.exe
SET errLvl=%ERRORLEVEL%
IF "%errLvl%" NEQ "0" (
	GOTO :exit
)

:: If {repository} parameter isn't set, looks for a previously configured 
:: repository in the metadata file.
IF "%param.repository%" == " " (
	IF EXIST "%param.target%\.aBackup" (
		CALL :loadProperties "%param.target%\.aBackup"
		IF EXIST "!repository!" (
			SET param.repository=!repository!
		) ELSE (
			ECHO ERROR: Broken meta data file ®%param.target%\.aBackup¯.
			EXIT /B 2
		)
	) ELSE (
		CALL :canonicalizePath "%param.target%" canonicalPath
		
		ECHO ERROR: ®!canonicalPath!¯ is not initialized and parameter {repository} is not specified.
		EXIT /B 1
	)
)

:: Analizes repository dirctory identifying all backups.
CALL :strLen "aBackup-" prefixLength
SET backups.length=0
FOR /F "usebackq tokens=* delims=:" %%i IN (`DIR /B /O:-N "%param.repository%"\aBackup-*`) DO (
	SET backups[!backups.length!].file=%%i
	SET /A "startAt=prefixLength"
	CALL SET backups[!backups.length!].year=%%backups[!backups.length!].file:~!startAt!,4%%
	SET /A "startAt+=4"
	CALL SET backups[!backups.length!].month=%%backups[!backups.length!].file:~!startAt!,2%%
	SET /A "startAt+=2"
	CALL SET backups[!backups.length!].day=%%backups[!backups.length!].file:~!startAt!,2%%
	SET /A "startAt+=2"
	CALL SET backups[!backups.length!].hour=%%backups[!backups.length!].file:~!startAt!,2%%
	SET /A "startAt+=2"
	CALL SET backups[!backups.length!].minute=%%backups[!backups.length!].file:~!startAt!,2%%
	SET /A "startAt+=2"
	CALL SET backups[!backups.length!].second=%%backups[!backups.length!].file:~!startAt!,2%%
	SET /A "backups.length+=1"
)
SET /A "backups.lastIndex=backups.length-1"

:: If there are more than one, asks the user to choose one.
IF "%backups.length%" GTR "1" (
	ECHO There are more than one backups in the repository:
	ECHO    #  Year Month Day Hour Minute Second
	FOR /L %%i IN (0,1,%backups.lastIndex%) DO (
		ECHO    %%i: !backups[%%i].year! !backups[%%i].month!    !backups[%%i].day!  !backups[%%i].hour!   !backups[%%i].minute!     !backups[%%i].second!     !backups[%%i].file!
	)
	SET /P answer=Which one do you want to restore?: 
	IF "!answer!" GEQ "0" (
		IF "!answer!" LEQ "%backups.lastIndex%" (
			CALL SET theBackup=%%backups[!answer!].file%%
		) ELSE (
			ECHO ERROR: ®!answer!¯ is an invalid input. Input a number from the list.
			EXIT /B 1
		)
	) ELSE (
		ECHO ERROR: ®!answer!¯ is an invalid input. Input a number from the list.
		EXIT /B 1
	)
) ELSE IF "%backups.length%" EQU "0" (
	ECHO ERROR: No backups found in repository ®!param.repository!¯.
	SET EXIT /B 1
) ElSE (
	SET theBackup=!backups[0].file!
)

:: Finally, unzips the backup file in the target directory.
UNZIP -qq "%param.repository%\%theBackup%" -d "%param.target%"

ENDLOCAL & EXIT /B %errLvl%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®restore¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®init¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Adds the files needed for a directory to be repeatedly backed up.
:: 
:: USAGE: 
::    CALL :init
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:init
SETLOCAL EnableDelayedExpansion

REM ECHO DEBUG: param.source=%param.source%
REM ECHO DEBUG: param.repository=%param.repository%

CALL :canonicalizePath "%param.repository%" canonicalPath
REM ECHO DEBUG: canonicalPath=%canonicalPath%

>"%param.source%\.aBackup" ECHO repository=%canonicalPath%

ENDLOCAL & EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®init¯
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
	ECHO ERROR: Program ®%1¯ cannot be found in PATH. A ®%1¯ installation is required.
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
	IF NOT "%%~n" == "" (
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

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®canonicalizePath¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Gets the canonical form of a path.
:: 
:: USAGE: 
::    CALL :canonicalizePath ®["]path["]¯ ®retVar¯
:: WHERE...
::    ®["]path["]¯: Path to canonicalize. If the path contains white spaces, it
::                  must be enclosed in double quotes. It is optional 
::                  otherwise.
::    ®retVar¯:     Name of a variable (existent or not) by means of which the 
::                  canonical path will be returned.
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:canonicalizePath
SET "%2=%~f1" & EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®canonicalizePath¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: BEGINNING: SUBROUTINE ®strLen¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::    Gets the length of a string.
::
::    All credits to "jeb" who provided this algorithm for counting characters 
:: at http://stackoverflow.com/questions/5837418/how-do-you-get-the-string-length-in-a-batch-file
:: 
:: USAGE: 
::    CALL :strLen ®["]string["]¯ ®retVar¯
:: WHERE...
::    ®["]string["]¯: The string to count characters from. If the string can 
::                    contains white spaces, it must be enclosed in double 
::                    quotes. It is optional otherwise.
::    ®retVar¯:       Name of a variable (existent or not) by means of which 
::                    the number of characters will be returned.
::
:: DEPENDENCIES: NONE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:strLen
SETLOCAL EnableDelayedExpansion

SET str=%~1#
SET retVar=%2
SET len=0

FOR %%i IN (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) DO (
	IF "!str:~%%i,1!" NEQ "" ( 
		SET /A "len+=%%i"
		SET str=!str:~%%i!
	)
)

ENDLOCAL & SET "%retVar%=%len%" & EXIT /B 0
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END: SUBROUTINE ®strLen¯
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::]]></contenido>
