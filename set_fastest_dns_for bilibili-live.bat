Setlocal Enabledelayedexpansion

:: �����ߘ��ޤ�ȡ�ä������ɤ������жϤ���
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (  
    goto UACPrompt  
) else ( goto gotAdmin )

:: vbs������ץȤ�������������Υ�����ץȣ�bat��������ߤȤ��ƌg�Ф���
:UACPrompt  
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs" 
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:: һ�r�Ĥ�vbs������ץȤ����ڤ�����Ϥ���������
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"


echo �������x�k֫���x��Ǥ�������:
echo 1 - Hosts��live-push.bilibili.com���O�����Ƹ��¤��ޤ�
echo 2 - Hosts�ե����뤫�� live-push.bilibili.com ���O�����������ޤ�

CHOICE /C 12 /M "�x������֤��������Ƥ�������:"
IF ERRORLEVEL 2 GOTO REMOVE_SETTING
IF ERRORLEVEL 1 GOTO ADD_SETTING


:ADD_SETTING
:: live-push.bilivideo.com�Υɥᥤ�������������
for /f "tokens=2" %%a in ('nslookup live-push.bilivideo.com ^| find "Address"') do (
    set ip=%%a
    echo %%a>>temp.txt
)

:: live-push.bilivideo.com�Υɥᥤ�������������temp.txt�˱��椹��
nslookup live-push.bilivideo.com>temp.txt

:: ��Ҫ�ʉ�������ڻ�����
set "start=no"
set "ip=ip.txt"

:: �¤����Y���ե���������ɤ���
type nul > !ip!

:: nslookup�νY�����ߖˤ���
for /f "tokens=1,2" %%a in (temp.txt) do (
    :: "Addresses:" �Ȥ����Ф����ݤ����٤��ߖˤ��줿���ɤ�����_�J����
    if /i "%%a"=="Addresses:" (
        type nul > !ip!
        set "start=yes"
    ) else (
        :: "Addresses:" ���Ф���Ǥ���С������Ф����ݤ�Y���ե�����˱��椹��
        if "!start!" equ "yes" (
            echo %%a %%b>> !ip!
        )
    )
)
del temp.txt


:: CloudflareST�Όg�Хѥ��`���`��׷��?����Ǥ��ޤ��� echo.| ��Ŀ�Ĥ��ԄӵĤ˥��󥿩`���`��Ѻ���ƥץ�����K�ˤ��뤳�ȤǤ� (-p 0�ѥ��`���`�Ϥ⤦��Ҫ�ʤ��Ǥ�)
echo.|CloudflareST.exe -t 100 -f "ip.txt" -o "speed_test.txt"
del ip.txt


:: �Y���ե����뤬���ڤ��뤫�ɤ������жϤ��롢���ڤ��ʤ����ϤϽY���� 0
if not exist speed_test.txt (
    echo.
    echo CloudflareST���ٶȜy���Y����IP����0���ΤΥ��ƥåפ򥹥��åפ��ޤ�...
    goto :STOP
)

:: ���٤�IP��ȡ�ä���
for /f "tokens=1 delims=," %%i in (speed_test.txt) do (
    SET /a n+=1 
    IF !n! GEQ 2 (
        IF !n! LEQ 4 (
            echo %%i>> best_ips.txt
        )
    )
)


:: ��Ҫ�ʉ�������ڻ�����
set "hostsFile=C:\Windows\System32\drivers\etc\hosts"
set "tempFile=C:\Windows\System32\drivers\etc\temp3.txt"

:: �¤���һ�r�ե���������ɤ���
type nul > !tempFile!

:: �Ť� hosts �ե�������ߖˤ���
for /f "delims=" %%a in (!hostsFile!) do (
    :: �F�ڤ��Ф� "live-push.bilivideo.com"�����ޤ�Ƥ��뤫�ɤ�����_�J����
    echo %%a|findstr /C:"live-push.bilivideo.com" >nul 2>&1
    if errorlevel 1 (
        ::  "live-push.bilivideo.com"�����ޤ�Ƥ��ʤ����Ϥ��¤���һ�r�ե�����˕����z��
        echo %%a>> !tempFile!
    )
)

:: �Ť� hosts �ե��������������
del /f !hostsFile!

:: �¤���һ�r�ե�������¤��� hosts �ե�����˥�ͩ`�ह��
move /y !tempFile! !hostsFile!

:: hosts �ե������׷�Ӥ���
:hosts
for /f "tokens=*" %%i in (best_ips.txt) do (
    echo %%i live-push.bilivideo.com>>C:\Windows\System32\drivers\etc\hosts
)
del best_ips.txt

:: DNS����å�����ե�å��夹��
ipconfig /flushdns
GOTO STOP


:REMOVE_SETTING
:: ��Ҫ�ʉ�������ڻ�����
set "hostsFile=C:\Windows\System32\drivers\etc\hosts"
set "tempFile=C:\Windows\System32\drivers\etc\temp3.txt"

:: �¤���һ�r�ե���������ɤ���
type nul > !tempFile!

:: �Ť� hosts �ե�������ߖˤ���
for /f "delims=" %%a in (!hostsFile!) do (
    :: �F�ڤ��Ф� "live-push.bilivideo.com"�����ޤ�Ƥ��뤫�ɤ�����_�J����
    echo %%a|findstr /C:"live-push.bilivideo.com" >nul 2>&1
    if errorlevel 1 (
        ::  "live-push.bilivideo.com"�����ޤ�Ƥ��ʤ����Ϥ��¤���һ�r�ե�����˕����z��
        echo %%a>> !tempFile!
    )
)

:: �Ť� hosts �ե��������������
del /f !hostsFile!

:: �¤���һ�r�ե�������¤��� hosts �ե�����˥�ͩ`�ह��
move /y !tempFile! !hostsFile!


:STOP
endlocal
pause