@echo off

@REM Store the initial path from where the script was exec
set "init_path=%cd%"

REM Prompt the user for the path to their Git repository
set /p repo_path="Enter the path to your Git repository: "

REM Change to the specified repository directory
cd /d "%repo_path%"

:search_branch
git branch

echo Make sure that all branches are up to date please. use git pull for each branch before continue.
echo.
pause

set /p branch="Enter the name of the branch to cherry-pick from: "
echo.

setlocal EnableDelayedExpansion
:cherry_pick_loop
set count=0
set start=1
set end=5

@REM just in case i want to readjust paging --skip !start! --max-count=!end!
for /f "tokens=1,*" %%a in ('git log --oneline %branch%') do (
    set /a count+=1
    set hash[!count!]=%%a
    set message[!count!]=%%b
)

cls
echo "The commits on the %branch% branch are: "
echo.

:loop
@REM !start!,1,!count!
for /l %%i in (!start!,1,!end!) do (
    echo [%%i] !hash[%%i]! !message[%%i]!
    @REM set "hash=!hash[%%i]!"
    @REM set "message=!message[%%i]!"

    @REM rem set the color to yellow for the index
    @REM echo | set /p="[\033[33m%%i\033[0m] "

    @REM rem set the color to green for the hash
    @REM echo | set /p="\033[32m!hash!\033[0m "

    @REM rem print the message
    @REM echo !message!
    if %%i equ !count! goto :commit_prompt
)

:commit_prompt
echo.
if !end! lss !count! (
    set /p selection="Enter 'n' to see the next 5 commits or the number of the commit to cherry-pick, or q to quit: "
) else (
    set /p selection="Enter the number of the commit to cherry-pick, or q to quit: "
)

@REM or !end! equ !count!
if /i !selection! equ q exit /b
if /i !selection! equ n (
        if !end! lss !count! (
            set /a start+=5
            set /a end+=5 
            goto loop 
        ) 
        @REM else (
        @REM     set /a start= !count!-5
        @REM     set /a end= !count!
        @REM     goto loop 
        @REM )
)

if not defined hash[%selection%] (
    set /p selection="The selected commit is invalid. Press any key to try again or 'q' to quit..."
    if /i "!selection!" equ "q" exit /b
    echo Invalid selection. Press any key to try again...
    pause >nul
    goto :cherry_pick_loop
)

echo.
echo Cherry-picking commit !hash[%selection%]! from branch %branch%...
echo.

git cherry-pick !hash[%selection%]!


set /p choice=Do you want to cherry-pick another commit? (Y/N)

if /i "%choice%"=="Y" (
    set /p same_branch=Is it from the same branch? (Y/N)
    if /i "%same_branch%"=="Y" (
        goto cherry_pick_loop
    ) else (
        goto search_branch
    )
)

echo "Don't forget to put a star on the repo. See you soon!"

echo.
echo Press any key to exit...
pause >nul

:end_loop
endlocal
cd /d "%init_path%"