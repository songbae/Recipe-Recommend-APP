import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:localstorage/localstorage.dart';
import 'package:file_picker/file_picker.dart';

class Write extends StatefulWidget {
  static const id = 'write';

  @override
  _WriteState createState() => _WriteState();
}

class _WriteState extends State<Write> {
  int stepNum = 1;
  LocalStorage _storage;
  LocalStorage _storage2;
  static List<_RecipeBox> recipeList = [];
  String dropdownTitle = '선택해주세요 (더블클릭시 삭제)';

  // File _image;
  mongo.Db _db = mongo.Db('mongodb://songbae:dotslab1234@'
      'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
      'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
      'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
      'toy_project?authSource=admin&compressors=disabled'
      '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
      '&ssl=true');
  mongo.DbCollection collection;
  mongo.DbCollection collection2;
  static mongo.GridFS bucket;
  ImageProvider provider;
  String id;
  int cnt = 0;
  String name, summary, cal;
  List<String> info, ingredients;
  List<String> nations, categories, levels, servings;
  String nationVal, categoryVal, levelVal, servingVal;

  @override
  void initState() {
    _storage = LocalStorage('reipce_info');
    _storage2 = LocalStorage('login_info');
    nations = List<String>.from(_storage?.getItem('nations'));
    categories = List<String>.from(_storage?.getItem('categories'));
    levels = List<String>.from(_storage?.getItem('levels'));
    servings = ['1인분', '2인분', '3인분', '4인분', '5인분', '6인분'];
    nationVal = nations[0];
    categoryVal = categories[0];
    levelVal = levels[0];
    servingVal = servings[0];
    collection = _db.collection('users');
    collection2 = _db.collection('recipe');
    info = List.filled(100, '');
    fetchUserinfoFromDB();
    connection();
  }

  Future connection() async {
    bucket = mongo.GridFS(_db, "image");
  }

  Future fetchUserinfoFromDB() async {
    await _db.open(secure: true);
    id = jsonDecode(_storage2.getItem('info'))['id'];
    cnt = Map<String, dynamic>.from(
        (await collection.findOne({"id": id})))['recipeCnt'];
  }

  @override
  void dispose() {
    stepNum = 1;
    recipeList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(45.0),
          child: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                padding: EdgeInsets.all(0),
                onPressed: () {
                  bucket.chunks.remove({"_id": "$id--main-$cnt"});
                  for (var i = 1; i <= recipeList.length; ++i) {
                    bucket.chunks.remove({"_id": "$id--STEP$i-$cnt"});
                  }
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.black,
                ),
              ),
              IconButton(
                padding: EdgeInsets.all(0),
                onPressed: () async {
                  if (provider != null &&
                      name != null &&
                      summary != null &&
                      cal != null &&
                      ingredients.isNotEmpty &&
                      ingredients.length != 0) {
                    await collection2.insert({
                      "writer": id,
                      "name": name,
                      "summary": summary,
                      "nation": nationVal,
                      "qnt": servingVal,
                      "cal": cal,
                      "level": levelVal,
                      "picture": "$id--main-$cnt",
                      "category": categoryVal,
                      "ingredients": jsonEncode(ingredients),
                      "info": jsonEncode(
                        [
                          ...recipeList.map(
                            (e) => {
                              "content": info[e.stepNum - 1],
                              "picture": e.provider != null
                                  ? "$id--STEP${e.stepNum}-$cnt"
                                  : ""
                            },
                          ),
                        ],
                      ),
                      "likes": [],
                    });
                    await collection.update({
                      "id": id
                    }, {
                      "\$set": {
                        "recipeCnt": ++cnt,
                      },
                    });
                    Navigator.pop(context);
                  }
                },
                icon: Icon(
                  Icons.check,
                  color: Colors.black,
                ),
              ),
            ],
            backgroundColor: Colors.white,
            elevation: 5.0,
            title: Text(
              '오늘뭐먹지?',
              style: TextStyle(color: Colors.black45),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 40.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      30.0,
                    ),
                    border: Border.all(
                      color: Colors.black54,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: GestureDetector(
                          onTap: () async {
                            FilePickerResult result =
                                await FilePicker.platform.pickFiles();

                            if (result != null) {
                              String filePath = result.files.single.path;
                              var _cmpressed_image;
                              // if(Platform.isAndroid) {
                              //   _cmpressed_image =
                              //   await FlutterImageCompress.compressWithFile(
                              //       filePath,
                              //       format: CompressFormat.jpeg,
                              //       quality: 70);
                              // }
                              // if(Platform.isIOS) {
                              //   _cmpressed_image =
                              //   await FlutterImageCompress.compressWithFile(
                              //       filePath,
                              //       format: CompressFormat.heic,
                              //       quality: 70);
                              // }
                              // HEIC 코덱은 android가 지원을 안함
                                _cmpressed_image =
                                await FlutterImageCompress.compressWithFile(
                                    filePath,
                                    format: CompressFormat.jpeg,
                                    quality: 70);
                              Map<String, dynamic> image = {
                                "_id": "$id--main-$cnt",
                                "data": base64Encode(_cmpressed_image),
                              };

                              var res = await bucket.chunks.insert(image);
                              var img = await bucket.chunks.findOne({
                                "_id": "$id--main-$cnt",
                              });
                              setState(() {
                                provider =
                                    MemoryImage(base64Decode(img["data"]));
                              });
                            } else {
                              // User canceled the picker
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(1.0),
                            child: Text(
                              "파일 선택",
                            ),
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(0.0, 1.0), //(x,y)
                              blurRadius: 1.0,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 5.0,
                      ),
                      provider == null
                          ? Text("선택된 파일 없음")
                          : Image(
                              image: provider,
                            ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    "* 완성사진을 업로드 해주세요.",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _TextField(
                  hintText: "요리 이름을 입력해주세요",
                  onChanged: (val) {
                    name = val;
                  },
                ),
                _TextField(
                  hintText: "요리에 대한 간략한 설명을 입력해주세요",
                  onChanged: (val) {
                    summary = val;
                  },
                ),
                _TextField(
                  hintText: "요리 재료를 입력해주세요(띄어쓰기로 구분)",
                  onChanged: (val) {
                    ingredients = val.split(" ");
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: _TextField(
                        hintText: "칼로리를 입력해주세요",
                        onChanged: (val) {
                          cal = val;
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Kcal",
                        style: TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(5.0),
                            child: DropdownButtonFormField(
                              decoration: InputDecoration.collapsed(),
                              value: nationVal,
                              items: nations
                                  .map<DropdownMenuItem>(
                                    (cur) => DropdownMenuItem(
                                        value: cur, child: Text(cur)),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  nationVal = val;
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(5.0),
                            child: DropdownButtonFormField(
                              decoration: InputDecoration.collapsed(),
                              value: categoryVal,
                              items: categories
                                  .map<DropdownMenuItem>(
                                    (cur) => DropdownMenuItem(
                                      value: cur,
                                      child: Text(cur),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  categoryVal = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(5.0),
                            child: DropdownButtonFormField(
                              decoration: InputDecoration.collapsed(),
                              value: levelVal,
                              items: levels
                                  .map<DropdownMenuItem>(
                                    (cur) => DropdownMenuItem(
                                        value: cur, child: Text(cur)),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  levelVal = val;
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(5.0),
                            child: DropdownButtonFormField(
                              decoration: InputDecoration.collapsed(),
                              value: servingVal,
                              items: servings
                                  .map<DropdownMenuItem>(
                                    (cur) => DropdownMenuItem(
                                      value: cur,
                                      child: Text(cur),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  servingVal = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(
                  height: 30.0,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    child: Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.black,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      setState(
                        () {
                          recipeList.add(
                            _RecipeBox(
                              count: cnt,
                              id: id,
                              value: info,
                              bucket: bucket,
                              stepNum: stepNum++,
                              callback: (stNum) {
                                setState(() {
                                  _WriteState.recipeList
                                      .removeWhere((el) => el.stepNum == stNum);
                                });
                                if (recipeList.length == 0 &&
                                    recipeList.isEmpty) {
                                  stepNum = 1;
                                  info[stepNum - 1] = '';
                                } else {
                                  int i = 0;
                                  for (;
                                      i < recipeList.length &&
                                          !(recipeList[i].stepNum != i + 1);
                                      ++i);
                                  if (i < recipeList.length) {
                                    int j = i;
                                    for (; j < recipeList.length; ++j) {
                                      recipeList[j].stepNum = j + 1;
                                      info[recipeList[j].stepNum] = '';
                                    }
                                  } else {
                                    // 마지막껄 지웠을때
                                    info[recipeList.length] = '';
                                  }
                                  stepNum = recipeList.length + 1;
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 30.0,
                ),
                ...recipeList,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final hintText;
  final onChanged;

  _TextField({this.hintText, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: GestureDetector(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 40.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              30.0,
            ),
            border: Border.all(
              color: Colors.black54,
            ),
          ),
          child: TextField(
            textAlign: TextAlign.start,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              border: UnderlineInputBorder(
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeBox extends StatefulWidget {
  var stepNum;
  final Function callback;
  final value;
  final id;
  final count;
  final bucket;
  ImageProvider provider;

  _RecipeBox(
      {this.stepNum,
      this.callback,
      this.value,
      this.id,
      this.count,
      this.bucket});

  @override
  __RecipeBoxState createState() => __RecipeBoxState();
}

class __RecipeBoxState extends State<_RecipeBox> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.0),
      child: Stack(
        overflow: Overflow.visible,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black54,
              ),
              borderRadius: BorderRadius.circular(
                15.0,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 5.0),
                  child: Text(
                    "STEP ${widget.stepNum}",
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.black,
                  thickness: 0.75,
                ),
                GestureDetector(
                  onTap: () async {
                    FilePickerResult result =
                        await FilePicker.platform.pickFiles();

                    if (result != null) {
                      String filePath = result.files.single.path;
                      var _cmpressed_image;
                      _cmpressed_image =
                      await FlutterImageCompress.compressWithFile(
                          filePath,
                          format: CompressFormat.heic,
                          quality: 70);
                      // if(Platform.isAndroid) {
                      //   _cmpressed_image =
                      //         await FlutterImageCompress.compressWithFile(
                      //             filePath,
                      //             format: CompressFormat.jpeg,
                      //             quality: 70);
                      // }
                      // if(Platform.isIOS) {
                      //   _cmpressed_image =
                      //   await FlutterImageCompress.compressWithFile(
                      //       filePath,
                      //       format: CompressFormat.heic,
                      //       quality: 70);
                      // }
                      _cmpressed_image =
                      await FlutterImageCompress.compressWithFile(
                          filePath,
                          format: CompressFormat.jpeg,
                          quality: 70);
                      // HEIC 코덱은 android가 지원을 안함
                      Map<String, dynamic> image = {
                        "_id":
                            "${widget.id}--STEP${widget.stepNum}-${widget.count}",
                        "data": base64Encode(_cmpressed_image),
                      };

                      var res = await widget.bucket.chunks.insert(image);
                      var img = await widget.bucket.chunks.findOne({
                        "_id":
                            "${widget.id}--STEP${widget.stepNum}-${widget.count}",
                      });
                      setState(() {
                        widget.provider =
                            MemoryImage(base64Decode(img["data"]));
                      });
                    } else {
                      // User canceled the picker
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: widget.provider == null
                        ? Image.asset(
                            'assets/cloud-computing.png',
                          )
                        : Image(
                            image: widget.provider,
                          ),
                  ),
                ),
                SizedBox(
                  height: 30.0,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: SizedBox(
                    height: 40.0,
                    child: TextField(
                      onChanged: (val) {
                        widget.value[widget.stepNum - 1] = val;
                      },
                      decoration: InputDecoration(
                          hintText: "조리 과정에 관한 설명을 적어주세요",
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            child: GestureDetector(
              child: Container(
                height: 25.0,
                width: 25.0,
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30.0)),
              ),
              onTap: () {
                widget?.callback(widget.stepNum);
              },
            ),
          )
        ],
      ),
    );
  }
}
