Setlocal Enabledelayedexpansion

:: 管理者権限を取得したかどうかを判断する
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (  
    goto UACPrompt  
) else ( goto gotAdmin )

:: vbsスクリプトを書き出し、このスクリプト（bat）を管理者として実行する
:UACPrompt  
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs" 
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:: 一時的なvbsスクリプトが存在する場合は削除する
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"


echo 操作の選択肢を選んでください:
echo 1 - Hostsのlive-push.bilibili.comを設定して更新します
echo 2 - Hostsファイルから live-push.bilibili.com の設定を削除します

CHOICE /C 12 /M "選んだ数字を入力してください:"
IF ERRORLEVEL 2 GOTO REMOVE_SETTING
IF ERRORLEVEL 1 GOTO ADD_SETTING


:ADD_SETTING
:: live-push.bilivideo.comのドメイン名を検索する
for /f "tokens=2" %%a in ('nslookup live-push.bilivideo.com ^| find "Address"') do (
    set ip=%%a
    echo %%a>>temp.txt
)

:: live-push.bilivideo.comのドメイン名を検索し、temp.txtに保存する
nslookup live-push.bilivideo.com>temp.txt

:: 必要な変数を初期化する
set "start=no"
set "ip=ip.txt"

:: 新しい結果ファイルを作成する
type nul > !ip!

:: nslookupの結果を走査する
for /f "tokens=1,2" %%a in (temp.txt) do (
    :: "Addresses:" という行の内容がすべて走査されたかどうかを確認する
    if /i "%%a"=="Addresses:" (
        type nul > !ip!
        set "start=yes"
    ) else (
        :: "Addresses:" の行の後であれば、この行の内容を結果ファイルに保存する
        if "!start!" equ "yes" (
            echo %%a %%b>> !ip!
        )
    )
)
del temp.txt


:: CloudflareSTの実行パラメーターを追加?変更できます。 echo.| の目的は自動的にエンターキーを押してプログラムを終了することです (-p 0パラメーターはもう必要ないです)
echo.|CloudflareST.exe -t 100 -f "ip.txt" -o "speed_test.txt"
del ip.txt


:: 結果ファイルが存在するかどうかを判断する、存在しない場合は結果は 0
if not exist speed_test.txt (
    echo.
    echo CloudflareSTの速度測定結果のIP数は0、次のステップをスキップします...
    goto :STOP
)

:: 高速なIPを取得する
for /f "tokens=1 delims=," %%i in (speed_test.txt) do (
    SET /a n+=1 
    IF !n! GEQ 2 (
        IF !n! LEQ 4 (
            echo %%i>> best_ips.txt
        )
    )
)


:: 必要な変数を初期化する
set "hostsFile=C:\Windows\System32\drivers\etc\hosts"
set "tempFile=C:\Windows\System32\drivers\etc\temp3.txt"

:: 新しい一時ファイルを作成する
type nul > !tempFile!

:: 古い hosts ファイルを走査する
for /f "delims=" %%a in (!hostsFile!) do (
    :: 現在の行に "live-push.bilivideo.com"が含まれているかどうかを確認する
    echo %%a|findstr /C:"live-push.bilivideo.com" >nul 2>&1
    if errorlevel 1 (
        ::  "live-push.bilivideo.com"が含まれていない場合は新しい一時ファイルに書き込む
        echo %%a>> !tempFile!
    )
)

:: 古い hosts ファイルを削除する
del /f !hostsFile!

:: 新しい一時ファイルを新しい hosts ファイルにリネームする
move /y !tempFile! !hostsFile!

:: hosts ファイルに追加する
:hosts
for /f "tokens=*" %%i in (best_ips.txt) do (
    echo %%i live-push.bilivideo.com>>C:\Windows\System32\drivers\etc\hosts
)
del best_ips.txt

:: DNSキャッシュをリフレッシュする
ipconfig /flushdns
GOTO STOP


:REMOVE_SETTING
:: 必要な変数を初期化する
set "hostsFile=C:\Windows\System32\drivers\etc\hosts"
set "tempFile=C:\Windows\System32\drivers\etc\temp3.txt"

:: 新しい一時ファイルを作成する
type nul > !tempFile!

:: 古い hosts ファイルを走査する
for /f "delims=" %%a in (!hostsFile!) do (
    :: 現在の行に "live-push.bilivideo.com"が含まれているかどうかを確認する
    echo %%a|findstr /C:"live-push.bilivideo.com" >nul 2>&1
    if errorlevel 1 (
        ::  "live-push.bilivideo.com"が含まれていない場合は新しい一時ファイルに書き込む
        echo %%a>> !tempFile!
    )
)

:: 古い hosts ファイルを削除する
del /f !hostsFile!

:: 新しい一時ファイルを新しい hosts ファイルにリネームする
move /y !tempFile! !hostsFile!


:STOP
endlocal
pause