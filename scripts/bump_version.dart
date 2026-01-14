/// 版本号自动递增脚本
/// 使用方法：
///   dart scripts/bump_version.dart          # 递增修订版本号（patch）
///   dart scripts/bump_version.dart minor    # 递增次版本号
///   dart scripts/bump_version.dart major    # 递增主版本号
///   dart scripts/bump_version.dart build   # 只递增构建号

import 'dart:io';

void main(List<String> args) {
  final pubspecFile = File('pubspec.yaml');
  
  if (!pubspecFile.existsSync()) {
    print('错误: 找不到 pubspec.yaml 文件');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  
  // 匹配版本号格式: version: 1.0.0+1
  final versionMatch = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')
      .firstMatch(content);
  
  if (versionMatch == null) {
    print('错误: 无法解析 pubspec.yaml 中的版本号');
    print('请确保版本号格式为: version: 1.0.0+1');
    exit(1);
  }

  final major = int.parse(versionMatch.group(1)!);
  final minor = int.parse(versionMatch.group(2)!);
  final patch = int.parse(versionMatch.group(3)!);
  final build = int.parse(versionMatch.group(4)!);

  String newVersion;
  String versionType;
  
  if (args.isNotEmpty && args[0] == 'major') {
    newVersion = '${major + 1}.0.0+${build + 1}';
    versionType = '主版本号';
  } else if (args.isNotEmpty && args[0] == 'minor') {
    newVersion = '$major.${minor + 1}.0+${build + 1}';
    versionType = '次版本号';
  } else if (args.isNotEmpty && args[0] == 'build') {
    newVersion = '$major.$minor.$patch+${build + 1}';
    versionType = '构建号';
  } else {
    // 默认递增修订版本号
    newVersion = '$major.$minor.${patch + 1}+${build + 1}';
    versionType = '修订版本号';
  }

  final newContent = content.replaceAll(
    RegExp(r'version:\s*[\d.]+[\+\d]*'),
    'version: $newVersion'
  );

  pubspecFile.writeAsStringSync(newContent);
  
  print('✓ 版本号已更新');
  print('  类型: $versionType');
  print('  旧版本: ${versionMatch.group(0)}');
  print('  新版本: version: $newVersion');
  print('');
  print('提示: 请提交版本号变更到 Git');
}
