import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';

class AmendingIng extends StatefulWidget {
  @override
  _AmendingIngState createState() => _AmendingIngState();
}

class _AmendingIngState extends State<AmendingIng> {
  LocalStorage storage;
  List<String> currentIngList;
  List<String> _ingList;
  List<String> _searchResult;
  String searchParam;

  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    storage = LocalStorage('login_info');
    currentIngList =
        List<String>.from(jsonDecode(storage.getItem('info'))['userFavor']);
    _ingList = List<String>.from(jsonDecode(storage.getItem('ing'))
        .map((cur) => cur.values
            .toString()
            .replaceAll(RegExp('[()]'), '')
            .trim()
            .replaceAll(RegExp(r",*$"), ""))
        .toList());
    _ingList.sort((a, b) {
      return a.compareTo(b);
    });
    _searchResult = []..addAll(_ingList);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(
            () {
              _controller.text = val.recognizedWords;
              searchParam = val.recognizedWords;
            },
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        floatingActionButton: AvatarGlow(
          animate: _isListening,
          glowColor: Theme.of(context).primaryColor,
          endRadius: 75.0,
          duration: Duration(milliseconds: 2000),
          repeatPauseDuration: Duration(milliseconds: 100),
          repeat: true,
          child: FloatingActionButton(
            onPressed: () async {
              _listen();
            },
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 5.0,
            title: Text(
              '오늘뭐먹지?',
              style: TextStyle(color: Colors.black45),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: Colors.black54,
                ),
                onPressed: () async {
                  final id = jsonDecode(storage.getItem('info'))['id'];
                  storage.setItem(
                      'info',
                      jsonEncode({
                        "id": id,
                        "userFavor": currentIngList,
                      }));
                  final db = mongo.Db('mongodb://songbae:dotslab1234@'
                      'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
                      'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
                      'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
                      'toy_project?authSource=admin&compressors=disabled'
                      '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
                      '&ssl=true');
                  await db.open();
                  final collection = db.collection('users');
                  await collection.update({
                    'id': id
                  }, {
                    '\$set': {'ingList': jsonEncode(currentIngList)}
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 15.0,
                  ),
                  child: Text("현재 내 냉장고 재료 목록"),
                ),
                SizedBox(
                  height: 40.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ),
                        child: Row(
                          children: [
                            ...currentIngList.map(
                              (value) => Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: GestureDetector(
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 20.0,
                                    ),
                                  ),
                                  onDoubleTap: () {
                                    setState(
                                      () {
                                        currentIngList
                                            .removeWhere((el) => el == value);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    onChanged: (str) {
                      searchParam = str;
                      _searchResult.clear();
                      if (searchParam == null || searchParam.length == 0) {
                        setState(() {
                          _searchResult = []..addAll(_ingList);
                        });
                      } else {
                        _ingList.forEach((ing) {
                          if (ing.contains(searchParam)) {
                            setState(() {
                              _searchResult.add(ing);
                              _searchResult.sort((a, b) {
                                return a.compareTo(b);
                              });
                            });
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              flex: 10,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) => ListTile(
                  title: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIngList.add(_searchResult[index]);
                        currentIngList =
                            LinkedHashSet<String>.from(currentIngList).toList();
                      });
                    },
                    child: Text(
                      _searchResult[index],
                    ),
                  ),
                ),
                itemCount: _searchResult.length,
              ),
            )
          ],
        ),
      ),
    );
  }
}
