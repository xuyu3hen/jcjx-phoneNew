@echo off
chcp 65001 >nul
REM 生成 HTTPS 证书脚本 (Windows)

set KEYSTORE_PATH=src\main\resources\keystore.p12
set ALIAS=apk-server
set PASSWORD=changeit
set VALIDITY=365

echo 生成 HTTPS 证书...
echo 密钥库路径: %KEYSTORE_PATH%
echo 别名: %ALIAS%
echo 有效期: %VALIDITY% 天
echo.

REM 检查 keytool 是否可用
where keytool >nul 2>&1
if errorlevel 1 (
    echo 错误: keytool 未找到，请确保已安装 Java JDK
    exit /b 1
)

REM 如果证书已存在，询问是否覆盖
if exist "%KEYSTORE_PATH%" (
    set /p OVERWRITE="证书已存在，是否覆盖? (y/n) "
    if /i not "!OVERWRITE!"=="y" (
        echo 已取消
        exit /b 0
    )
    del /f "%KEYSTORE_PATH%" >nul 2>&1
)

REM 生成证书
keytool -genkeypair ^
    -alias "%ALIAS%" ^
    -keyalg RSA ^
    -keysize 2048 ^
    -storetype PKCS12 ^
    -keystore "%KEYSTORE_PATH%" ^
    -validity %VALIDITY% ^
    -storepass "%PASSWORD%" ^
    -keypass "%PASSWORD%" ^
    -dname "CN=APK Distribution Server, OU=IT, O=JCJX, L=Beijing, ST=Beijing, C=CN"

if errorlevel 1 (
    echo.
    echo ✗ 证书生成失败
    exit /b 1
) else (
    echo.
    echo ✓ 证书生成成功!
    echo 密钥库: %KEYSTORE_PATH%
    echo 密码: %PASSWORD%
    echo.
    echo 提示: 生产环境请使用内网 CA 签发的正式证书
)
