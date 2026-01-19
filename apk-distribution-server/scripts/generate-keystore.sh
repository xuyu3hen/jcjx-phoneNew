#!/bin/bash
# 生成 HTTPS 证书脚本

KEYSTORE_PATH="src/main/resources/keystore.p12"
ALIAS="apk-server"
PASSWORD="changeit"
VALIDITY=365

echo "生成 HTTPS 证书..."
echo "密钥库路径: $KEYSTORE_PATH"
echo "别名: $ALIAS"
echo "有效期: $VALIDITY 天"
echo ""

# 检查 keytool 是否可用
if ! command -v keytool &> /dev/null; then
    echo "错误: keytool 未找到，请确保已安装 Java JDK"
    exit 1
fi

# 如果证书已存在，询问是否覆盖
if [ -f "$KEYSTORE_PATH" ]; then
    read -p "证书已存在，是否覆盖? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
    rm -f "$KEYSTORE_PATH"
fi

# 生成证书
keytool -genkeypair \
    -alias "$ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -storetype PKCS12 \
    -keystore "$KEYSTORE_PATH" \
    -validity "$VALIDITY" \
    -storepass "$PASSWORD" \
    -keypass "$PASSWORD" \
    -dname "CN=APK Distribution Server, OU=IT, O=JCJX, L=Beijing, ST=Beijing, C=CN"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 证书生成成功!"
    echo "密钥库: $KEYSTORE_PATH"
    echo "密码: $PASSWORD"
    echo ""
    echo "提示: 生产环境请使用内网 CA 签发的正式证书"
else
    echo ""
    echo "✗ 证书生成失败"
    exit 1
fi
