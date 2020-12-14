import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:recipe_app/mainPage.dart';
import 'package:recipe_app/signUpPage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:crypto/crypto.dart';
import 'package:localstorage/localstorage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

class Data {
  String value;
}

class _LoginPage extends State<LoginPage> {
  String id, passwd;
  List<String> ingredientList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  LocalStorage storage;

  @override
  void initState() {
    storage = LocalStorage('login_info');
  }

  @override
  Widget build(BuildContext context) {
    final _width = MediaQuery.of(context).size.width - 30;
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Login",
              style: TextStyle(
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 25.0,
            ),
            InputField(
              hintText: 'ID를 입력해주세요',
              onChange: (val) {
                id = val;
              },
            ),
            SizedBox(
              height: 20.0,
            ),
            InputField(
              hintText: '패스워드를 입력해주세요.',
              isPasswdField: true,
              onChange: (val) {
                passwd = val;
              },
            ),
            SizedBox(
              height: 30.0,
            ),
            MaterialButton(
              padding: EdgeInsets.all(0),
              onPressed: () async {
                try {
                  final db = mongo.Db('mongodb://songbae:dotslab1234@'
                      'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
                      'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
                      'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
                      'toy_project?authSource=admin&compressors=disabled'
                      '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
                      '&ssl=true');
                  await db.open();
                  final collection = db.collection('users');
                  collection.find().forEach((v) {
                    if (v['id'] == id &&
                        v['password'] ==
                            md5.convert(utf8.encode(passwd)).toString()) {
                      setState(() {
                        storage.setItem(
                          'info',
                          jsonEncode(
                            {
                              'id': id,
                              'userFavor': jsonDecode(v['ingList']),
                            },
                          ),
                        );
                      });
                      _scaffoldKey.currentState
                          .showSnackBar(
                            SnackBar(
                              duration: Duration(
                                seconds: 2,
                              ),
                              content: Text('로그인 진행중입니다..'),
                            ),
                          )
                          .closed
                          .then((_) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(),
                          ),
                        );
                      });
                    } else {
                      // final alert = AlertDialog(
                      //   title: Text('App'),
                      //   content: Text('해당하는 아이디가 없거나 비밀번호가 틀립니다.'),
                      //   actions: [
                      //     FlatButton(
                      //         onPressed: () {
                      //           Navigator.pop(context);
                      //         },
                      //         child: Text('OK'))
                      //   ],
                      // );
                      // showDialog(
                      //   context: context,
                      //   builder: (_) => alert,
                      // );
                    }
                  });
                } catch (e) {
                  print(e);
                }
              },
              child: Container(
                width: _width,
                height: 40.0,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    10.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    "로그인",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 15.0,
            ),
            Container(
              width: _width,
              child: Divider(
                color: Colors.black54,
              ),
            ),
            MaterialButton(
              child: Text("회원가입"),
              onPressed: () => {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SignUpPage()))
              },
            )
          ],
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final String hintText;
  final Function onChange;
  bool isPasswdField = false;

  InputField({this.hintText, this.onChange, this.isPasswdField});

  @override
  Widget build(BuildContext context) {
    final _width = MediaQuery.of(context).size.width - 30;
    return Container(
      width: _width,
      height: 50.0,
      child: TextField(
        onChanged: onChange,
        obscureText: isPasswdField == true ? true : false,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
