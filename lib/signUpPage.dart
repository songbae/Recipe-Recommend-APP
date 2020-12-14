import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:crypto/crypto.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class Data {
  String value;
}

class _SignUpPageState extends State<SignUpPage> {
  String dropdownTitle = '선택(삭제)';
  List<String> ingredientListForAdd = [];
  final _formKeyID = GlobalKey<FormState>();
  final _formKeyPWD = GlobalKey<FormState>();
  List<dynamic> ingredientList;
  Data idObj = Data();
  Data passwordObj = Data();

  @override
  void initState() {
    fetchIngredients();
  }

  Future<List<dynamic>> fetchIngredients() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/ingredient.json');
    ingredientList = jsonDecode(data).map((cur) => cur["name"]).toList();
    return ingredientList;
  }

  @override
  Widget build(BuildContext context) {
    final _width = MediaQuery.of(context).size.width - 30;
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "오늘뭐먹지?",
              style: TextStyle(
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 25.0,
            ),
            InputField(
              form: _formKeyID,
              hintText: '아이디를 입력해주세요',
              context: idObj,
            ),
            SizedBox(
              height: 20.0,
            ),
            InputField(
              form: _formKeyPWD,
              hintText: '비밀번호를 입력해주세요',
              isPasswordField: true,
              context: passwordObj,
            ),
            SizedBox(
              height: 20.0,
            ),
            FutureBuilder(
              future: fetchIngredients(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    height: 50.0,
                    width: _width,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: dropdownTitle,
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 24,
                      onChanged: (val) {
                        setState(() {
                          ingredientListForAdd.add(val);
                          ingredientListForAdd = ingredientListForAdd.toSet().toList();
                        });
                      },
                      items: ['선택(더블클릭시 삭제)', ...snapshot.data]
                          .map<DropdownMenuItem<String>>(
                        (value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ).toList(),
                    ),
                  );
                }
                return CircularProgressIndicator();
              },
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 50,
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
                              ...ingredientListForAdd.map(
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
                                          ingredientListForAdd
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
                ],
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Builder(
              builder: (context) => MaterialButton(
                padding: EdgeInsets.all(0),
                onPressed: () async {
                  if (_formKeyID.currentState.validate() &&
                      _formKeyPWD.currentState.validate()) {
                    try {
                      final db = mongo.Db('mongodb://songbae:dotslab1234@'
                          'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
                          'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
                          'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
                          'toy_project?authSource=admin&compressors=disabled'
                          '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
                          '&ssl=true');
                      await db.open();
                      bool isDup = false;
                      final collection = db.collection('users');
                      final collection2 = db.collection('ingredients');
                      await collection.find({"id": idObj.value}).forEach((element) async {
                        if(element != null) {
                          final alert = AlertDialog(
                            title: Text('App'),
                            content: Text('아이디가 중복됩니다..'),
                            actions: [
                              FlatButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('OK'))
                            ],
                          );
                          showDialog(
                            context: context,
                            builder: (_) => alert,
                          );
                          isDup = true;
                        }
                      });
                      // 중복제거
                      if(!isDup) {
                        await collection.insert({
                          'id': idObj.value,
                          'password': md5
                              .convert(utf8.encode(passwordObj.value))
                              .toString(),
                          'ingList': jsonEncode(ingredientListForAdd),
                        });
                        await collection2.insert({
                          'id': idObj.value,
                          'expiry': null,
                        });
                        Scaffold.of(context)
                            .showSnackBar(
                          SnackBar(
                            duration: Duration(
                              seconds: 2,
                            ),
                            content: Text('회원가입 진행중입니다..'),
                          ),
                        )
                            .closed
                            .then((reason) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        });
                      }
                      db.close();
                    } catch (e) {
                      print(e);
                    }
                  }
                },
                child: Container(
                  width: _width,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "회원가입",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 15.0,
            ),
          ],
        ),
      ),
    );
  }
}

class InputField extends StatefulWidget {
  bool isPasswordField = false;
  final String hintText;
  Data context;
  final GlobalKey<FormState> form;

  InputField({this.isPasswordField, this.hintText, this.context, this.form});

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.form,
      child: Container(
        width: MediaQuery.of(context).size.width - 30,
        height: 50.0,
        child: TextFormField(
          onChanged: (newVal) {
            widget.context.value = newVal;
          },
          validator: (value) {
            if (value.isEmpty) {
              return '텍스트를 입력해주세요';
            }
            if (value.length < 4) {
              return '4자 이상 입력해주세요';
            }
            return null;
          },
          obscureText: widget.isPasswordField == null ? false : true,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
                borderSide: BorderSide(
              color: Colors.black54,
            )),
          ),
        ),
      ),
    );
  }
}
