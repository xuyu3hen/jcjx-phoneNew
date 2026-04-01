import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcjx_phone/common/global.dart';
import 'package:jcjx_phone/models/permissions.dart';
import 'package:jcjx_phone/models/profile.dart';
import 'package:jcjx_phone/routes/message_center_page.dart';

class _FakeShuntingNoticeApi implements ShuntingNoticeApi {
  bool _read = false;
  int updateCalls = 0;

  @override
  Future<dynamic> getShuntingNotice({Map<String, dynamic>? queryParametrs}) async {
    final status = (queryParametrs?['status'] ?? 0).toString();
    final isReadQuery = status == '1';
    final rows = <Map<String, dynamic>>[];
    if (isReadQuery) {
      if (_read) rows.add(_item(status: 1));
    } else {
      if (!_read) rows.add(_item(status: 0));
    }
    return {
      'rows': rows,
      'total': rows.length,
    };
  }

  @override
  Future<dynamic> updateShuntingNotice(List<dynamic> queryParametrs) async {
    updateCalls += 1;
    _read = true;
    return {'ok': true};
  }

  Map<String, dynamic> _item({required int status}) {
    return {
      'code': 'N1',
      'content': '测试调令',
      'trainNum': '1234',
      'typeName': 'DF4',
      'status': status,
      'shuntingType': 99,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('消息详情：查看不消除，点已读后从未读列表移除', (tester) async {
    Global.profile = Profile(theme: 0);
    Global.profile.permissions = Permissions(
      msg: '',
      code: 200,
      permissions: const <String>[],
      roles: const <String>[],
      user: User(
        admin: false,
        userId: 1,
        userName: 'tester',
        nickName: 'tester',
      ),
    );

    final api = _FakeShuntingNoticeApi();

    await tester.pumpWidget(
      MaterialApp(
        home: MessageDetailPage(
          message: const <String, dynamic>{'title': '消息详情'},
          shuntingNoticeApi: api,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试调令'), findsOneWidget);
    expect(api.updateCalls, 0);

    await tester.tap(find.text('查看'));
    await tester.pumpAndSettle();
    expect(find.text('测试调令'), findsOneWidget);
    expect(api.updateCalls, 0);

    await tester.tap(find.text('已读'));
    await tester.pumpAndSettle();
    expect(find.text('确认已读'), findsOneWidget);

    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(find.text('暂无未读通知'), findsOneWidget);
  });
}

