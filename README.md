# jcjx_phone

一个flutter客户端项目

## Description

一个机车检修手持机项目 项目说明：
1、项目使用flutter框架开发，跨平台，支持安卓、ios、web、macos、windows、linux等平台。用于实现机务段要求。
2. 实现相关内容

## Getting start 
env_dev,env_release,env_test三种启动方式
以env_dev为例 
代码启动
flutter run --flavor env_dev -t lib/main_env_dev.dart 
代码打包
 flutter build apk --target-platform android-arm --flavor env_test -t lib/main_env_test.dart --no-tree-shake-icons
