import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:recipe_app/amendingIng.dart';
import 'package:recipe_app/changeDate.dart';
import 'package:recipe_app/whatIwritten.dart';

class InfoPage extends StatefulWidget {
  static const id = 'info_page';

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  LocalStorage storage;
  final _scaffoldState = GlobalKey<ScaffoldState>();

  Future<dynamic> loginInfo() async {
    return await jsonDecode(storage.getItem('info'));
  }

  @override
  void initState() {
    storage = LocalStorage('login_info');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: _scaffoldState,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 5.0,
            title: Text(
              '오늘뭐먹지?',
              style: TextStyle(color: Colors.black45),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_outlined,
                color: Colors.black54,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 30.0,
            horizontal: 30.0,
          ),
          child: FutureBuilder(
              future: loginInfo(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final parsedInfo = Map<String, dynamic>.from(snapshot.data);
                  return Column(
                    children: <Widget>[
                      Center(
                        child: Text(
                          "로그인 정보",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width - 30,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 30.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ID: ${parsedInfo['id']}",
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              ),
                              Text(
                                "내 식재료: ${parsedInfo['userFavor']}",
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Divider(
                        color: Colors.black54,
                      ),
                      MaterialButton(
                        padding: EdgeInsets.all(0),
                        child: Text("식재료 추가 / 삭제"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AmendingIng(),
                            ),
                          );
                        },
                      ),
                      MaterialButton(
                        padding: EdgeInsets.all(0),
                        child: Text("유통기한 확인"),
                        onPressed: () {
                          Navigator.pushNamed(context, ChangeDate.id);
                        },
                      ),
                      MaterialButton(
                        padding: EdgeInsets.all(0),
                        child: Text("내가 쓴 글"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WhatIWritten(),
                            ),
                          );
                        },
                      ),
                      MaterialButton(
                        padding: EdgeInsets.all(0),
                        child: Text("Log out"),
                        onPressed: () {
                          storage.deleteItem('info');
                          _scaffoldState.currentState
                              .showSnackBar(
                                SnackBar(
                                  duration: Duration(
                                    seconds: 2,
                                  ),
                                  content: Text('로그아웃...'),
                                ),
                              )
                              .closed
                              .then((_) {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          });
                        },
                      )
                    ],
                  );
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              }),
        ),
      ),
    );
  }
}
