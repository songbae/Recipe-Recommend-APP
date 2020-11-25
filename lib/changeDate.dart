import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class ChangeDate extends StatefulWidget {
  static const id = 'change_date';

  @override
  _ChangeDateState createState() => _ChangeDateState();
}

class _ChangeDateState extends State<ChangeDate> {
  AsyncMemoizer _memoizer;
  LocalStorage storage;
  List<String> ing;
  Map<String, String> expiry = {};
  mongo.Db db;
  String _id;
  mongo.DbCollection collection;
  DateTime picked;
  bool dateUpdated = false;

  @override
  void initState() {
    storage = LocalStorage('login_info');
    _id = jsonDecode(storage.getItem('info'))['id'];
    ing = List<String>.from(jsonDecode(storage.getItem('info'))['userFavor']);
    db = mongo.Db('mongodb://songbae:dotslab1234@'
        'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
        'toy_project?authSource=admin&compressors=disabled'
        '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
        '&ssl=true');
    collection = db.collection('ingredients');
    _memoizer = AsyncMemoizer();
  }

  syncFromDB() async {
    return this._memoizer.runOnce(() async {
      await db.open();
      await collection.find({'id': _id}).forEach((element) async {
        if (element['expiry'] == null) {
          ing.forEach((_ing) {
            expiry[_ing] = DateTime.now().toString();
          });
          await collection.update({
            'id': _id
          }, {
            'id': _id,
            'expiry': jsonEncode(expiry),
          });
        } else {
          ing.forEach((_ing) {
            expiry[_ing] = jsonDecode(element['expiry'])[_ing] ??
                DateTime.now().toString();
          });
          await collection.update({
            'id': _id
          }, {
            'id': _id,
            'expiry': jsonEncode(expiry),
          });
        }
      });
      await db.close();
      await Future.delayed(Duration(seconds: 1));
      return expiry;
    });
  }

  _selectDate(context, date, ingName) async {
    picked = await showDatePicker(
        context: context,
        initialDate: date,
        // Refer step 1
        firstDate: DateTime(2019),
        lastDate: DateTime(2023),
        initialEntryMode: DatePickerEntryMode.input,
        locale: Locale('ko'),
        helpText: '유통기한을 선택하세요',
        cancelText: '취소',
        confirmText: '확인',
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Colors.black54,
              accentColor: Colors.pinkAccent, //selection color
            ),
            child: child,
          );
        });
    if (picked != null && picked != date) {
      setState(() {
        expiry[ingName] = picked.toString();
      });
      await db.open();
      await collection.update({
        'id': _id
      }, {
        'id': _id,
        'expiry': jsonEncode(expiry),
      });
      db.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          actions: [
            IconButton(
              icon: Icon(
                Icons.update,
                color: Colors.black54,
              ),
              onPressed: () {
                print(expiry);
              },
            )
          ],
        ),
      ),
      body: FutureBuilder(
          future: syncFromDB(),
          builder: (_context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _selectDate(
                        context,
                        DateTime.parse(snapshot.data[ing[index]]),
                        ing[index],
                      );
                    },
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ing[index]),
                          Text(snapshot.data[ing[index]].split(' ')[0]),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: ing.length,
              );
            }
            return Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
