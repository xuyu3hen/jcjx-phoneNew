import '../../index.dart';

class EnterList extends StatefulWidget {
  const EnterList({Key? key}) : super(key: key);

  @override
  State createState() => _EnterList();
}

class _EnterList extends State<EnterList> {
  var logger = AppLogger.logger;
  // 列表尽头
  static const loadingTag = '##loading##';
  var _items = <TrainEntry>[TrainEntry()..code = loadingTag];
  // 翻页标志
  bool hasMore = true;
  int pageNum = 1;

  void _queryEntryData() async {
    try {
      var data = await ProductApi().getTrainEntry(queryParametrs: {
        'pageNum': pageNum,
        'page_size': 10,
      });

      if (data.rows != null) {
        hasMore = data.rows!.isNotEmpty && data.rows!.length % 10 == 0;
        setState(() {
          _items.insertAll(_items.length - 1, data.rows!);
          pageNum++;
        });
      } else {
        hasMore = false;
      }
    } catch (e, stackTrace) {
      logger.e('_queryEntryData 方法中发生异常: $e\n堆栈信息: $stackTrace');
    }
  }

  // 刷新
  update() {
    setState(() {
      _items = <TrainEntry>[TrainEntry()..code = loadingTag];
      hasMore = true;
      pageNum = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('检修状态'),
      ),
      body: _buildBody(),
    );
  }

  bool get _canSeeEnterDetailRecord {
    final user = Global.profile.permissions?.user;
    final name = (user?.nickName ?? user?.userName ?? '').toString().trim();
    final userId = (user?.userId ?? '').toString().trim();
    final workNo = (user?.workNumber ?? '').toString().trim();
    const allowedNos = <String>{
      '60786',
      '60671',
      '60618',
      '60118',
      '60316',
      '60571',
      '60387',
      '60502',
      '60951',
      '60195',
      '60897',
      '60121',
      '60115',
    };
    const allowedNames = <String>{
      '聂星',
      '王志赢',
      '罗晶',
      '夏龙',
      '李千通',
      '张扬',
      '李金飞',
      '黄忆',
      '曾志凌',
      '邓波',
      '白冰涛',
      '潘松松',
      '杨志国',
    };
    return allowedNos.contains(workNo) ||
        allowedNos.contains(userId) ||
        allowedNames.contains(name);
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              if (_items[index].code == loadingTag) {
                if (hasMore) {
                  _queryEntryData();
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  );
                }
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '已经到头了',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                );
              }
              final item = _items[index];
              final title =
                  '${item.typeName ?? ''}-${item.trainNum ?? ''}'.trim();
              final sub =
                  '${item.repairProcName ?? ''}-${item.repairTimes ?? ''}'.trim();
              return ListTile(
                title: Text(title.isEmpty ? '-' : title),
                subtitle: Text(sub == '-' ? '' : sub),
                trailing: Text((item.arrivePlatformTime ?? '').toString()),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 0),
          ),
        ),
        if (_canSeeEnterDetailRecord)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, 'enterDetailRecord'),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('入段细录'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
