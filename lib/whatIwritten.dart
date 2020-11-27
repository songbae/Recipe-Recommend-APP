import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:localstorage/localstorage.dart';
import 'package:recipe_app/individualRecipe.dart';

class WhatIWritten extends StatefulWidget {
  @override
  _WhatIWrittenState createState() => _WhatIWrittenState();
}

class _WhatIWrittenState extends State<WhatIWritten> {
  LocalStorage _storage;
  String id;
  mongo.Db db;
  mongo.DbCollection collection;
  List<Map<String, dynamic>> _recipeList = [];
  Future _recipeListAfterFetch;

  @override
  void initState() {
    _storage = LocalStorage('login_info');
    db = mongo.Db('mongodb://songbae:dotslab1234@'
        'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
        'toy_project?authSource=admin&compressors=disabled'
        '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
        '&ssl=true');
    _recipeListAfterFetch = fetchThread();
  }

  refreshState() async {
    _recipeListAfterFetch = fetchThread();
  }

  Future<List<Map<String, dynamic>>> fetchThread() async {
    _recipeList.clear();
    await db.open(secure: true);
    collection = db.collection('recipe');
    id = jsonDecode(_storage.getItem('info'))['id'];
    await collection.find({"writer": id}).forEach((cur) {
      _recipeList.add(cur);
    });
    return Future.value(_recipeList);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              color: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            backgroundColor: Colors.white,
            elevation: 5.0,
            centerTitle: true,
            title: Text(
              '오늘뭐먹지?',
              style: TextStyle(color: Colors.black45),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  "내가 쓴 글 목록",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: FutureBuilder(
                future: _recipeListAfterFetch,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            int i = 0;
                            for (;
                                i < _recipeList[index]['likes'].length &&
                                    !(_recipeList[index]['likes'][i] ==
                                        jsonDecode(
                                            _storage.getItem('info'))['id']);
                                ++i) {}
                            if (i < _recipeList[index]['likes'].length) {
                              // 좋아요 기록이 있을경우
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IndividualRecipe(
                                    recipeList: _recipeList[index],
                                    like: true,
                                  ),
                                ),
                              ).then((_) async => await refreshState());
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IndividualRecipe(
                                    recipeList: _recipeList[index],
                                    like: false,
                                  ),
                                ),
                              ).then((_) async => await refreshState());
                            }
                          },
                          child: ListTile(
                            title: Text(snapshot.data[index]['name']),
                          ),
                        );
                      },
                      itemCount: snapshot.data.length,
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
