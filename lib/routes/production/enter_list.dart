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
        title: const Text("检修状态"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child:
          Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Container(
            alignment: Alignment.topCenter,
            height: (MediaQuery.of(context).size.height) * 0.9,
            child: ListView.separated(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                if (_items[index].code == loadingTag) {
                  //单次加载容量
                  if (hasMore) {
                    // 请求请料表数据
                    _queryEntryData();
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: const SizedBox(
                          width: 24.0,
                          height: 24.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          )),
                    );
                  } else {
                    return Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "已经到头了",
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    );
                  }
                }
                // return EntryTrainItem(_items[index], () => update());
              },
              separatorBuilder: (context, index) => const SizedBox(
                height: .0,
              ),
            ))
      ]),
    );
  }
}
