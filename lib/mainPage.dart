import 'dart:convert';
import 'dart:collection';
import 'dart:core';

import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:recipe_app/amendingIng.dart';
import 'package:recipe_app/changeDate.dart';
import 'package:recipe_app/infoPage.dart';
import 'package:recipe_app/more.dart';
import 'package:recipe_app/searchResult.dart';
import 'package:recipe_app/recipePage.dart';
import 'package:recipe_app/whatIwritten.dart';
import 'package:recipe_app/write.dart';
import 'package:recipe_app/individualRecipe.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class recipeAndImg<T1, T2> {
  final T1 recipeList;
  final T2 imgList;

  recipeAndImg({
    this.recipeList,
    this.imgList,
  });

  factory recipeAndImg.fromJson(Map<dynamic, dynamic> json) {
    return recipeAndImg(
      recipeList: json['recipeList'],
      imgList: json['imgList'],
    );
  }
}

class MainPage extends StatefulWidget {
  static const id = 'main_page';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isVisible = true;
  Map<String, String> materialList = {};
  Map<String, bool> ingredientExists = {};
  List<String> ingredientsName = [];
  List<dynamic> ingredientList;
  String searchItem = '';
  String searchParam = '';

  List<String> nations = [];
  List<String> categories = [];
  List<String> levels = ['초보환영', '보통', '어려움'];

  List<Recipe> recipeList = [];
  TextEditingController _controller = TextEditingController();
  TextEditingController _controller2 = TextEditingController();

  LocalStorage _storage;
  LocalStorage _storage2;

  mongo.Db db;
  mongo.DbCollection collection;
  mongo.DbCollection collection2;
  mongo.GridFS bucket;

  List<Map<String, dynamic>> _recipeList = [];
  Future _recipeAndImgListAfterFetch;
  List<ImageProvider> _imgList = [];

  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _willUseSpeechRecognize = false;

  Map<String, dynamic> parsedInfo;

  @override
  void initState() {
    _storage = LocalStorage('login_info');
    _storage2 = LocalStorage('reipce_info');
    fetchIngredients();
    fetchRecipe();
    db = mongo.Db('mongodb://songbae:dotslab1234@'
        'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
        'toy_project?authSource=admin&compressors=disabled'
        '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
        '&ssl=true');
    collection = db.collection('users');
    collection2 = db.collection('recipe');
    _recipeAndImgListAfterFetch = fetchRecipeAndImgList();
    parsedInfo =
    Map<String, dynamic>.from(jsonDecode(_storage.getItem('info')));
  }

  refreshInfo() async {
    setState(() {
      parsedInfo =
          Map<String, dynamic>.from(jsonDecode(_storage.getItem('info')));
    });
  }

  refreshState() async {
    setState(() {
      _recipeAndImgListAfterFetch = fetchRecipeAndImgList();
    });
  }

  Future<recipeAndImg> fetchRecipeAndImgList() async {
    await db.open(secure: true);
    final _localStorage = jsonDecode(_storage.getItem('info'));
    await collection.find({"id": _localStorage["id"]}).forEach((element) async {
      if (element['recipeCnt'] == null) {
        await collection.update({
          "id": _localStorage["id"]
        }, {
          "\$set": {
            "recipeCnt": 0,
          }
        });
      }
    });
    _recipeList.clear();
    _imgList.clear();
    await collection2.find().forEach((element) async {
      // 전부 불러옴
      _recipeList.add(element);
    });
    _recipeList.sort((a, b) => -a['likes'].length.compareTo(b['likes'].length));
    bucket = mongo.GridFS(db, "image");
    for (var i = 0; i < _recipeList.length; ++i) {
      var img = await bucket.chunks.findOne({
        "_id": _recipeList[i]["picture"],
      });
      _imgList.add(MemoryImage(base64Decode(img["data"])));
    }

    recipeAndImg ret = recipeAndImg.fromJson({
      'recipeList': _recipeList,
      'imgList': _imgList,
    });
    await db.close();
    return Future.value(ret);
  }

  void runEverytimeToMatch() {
    ingredientsName = materialList.entries.map((e) => e.key).toList();
  }

  void fetchIngredients() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/ingredient.json');
    _storage.setItem('ing', data);
    ingredientList = jsonDecode(data).map((cur) => cur["name"]).toList();
    _storage2?.setItem('ing', ingredientList);
  }

  void fetchRecipe() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/recipe.json');
    _storage.setItem('recipe', data);
    List<dynamic> recipeDetail = jsonDecode(data);

    recipeDetail.map((cur) => cur["nation"]).toList().forEach((element) {
      nations.add(element.toString().replaceAll(RegExp('[()]'), ''));
    });
    nations = LinkedHashSet<String>.from(nations).toList();
    nations.sort((a, b) => a.compareTo(b));

    recipeDetail.map((cur) => cur["category"]).toList().forEach((element) {
      categories.add(element.toString().replaceAll(RegExp('[()]'), ''));
    });
    categories = LinkedHashSet<String>.from(categories).toList();
    categories.sort((a, b) => a.compareTo(b));

    recipeList =
        List<Recipe>.from(recipeDetail.map((cur) => Recipe.fromJson(cur)));

    _storage2?.setItem('nations', nations);
    _storage2?.setItem('categories', categories);
    _storage2?.setItem('levels', levels);
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
              if (_isVisible) {
                _controller.text = val.recognizedWords;
                searchItem = val.recognizedWords;
              } else if (!_isVisible) {
                _controller2.text = val.recognizedWords;
                searchParam = val.recognizedWords;
              }
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
    double width = !_isVisible ? MediaQuery.of(context).size.width - 30 : 0;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        endDrawerEnableOpenDragGesture: false,
        endDrawer: Builder(
          builder: (context) {
            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    child: Column(
                      children: [
                        Text(
                          '로그인 정보',
                          style: TextStyle(
                            fontSize: 18.0,
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
                                  "내 냉장고속 재료: ${parsedInfo['userFavor']}",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                    ),
                  ),
                  ListTile(
                    title: Text("재료 추가 / 삭제"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AmendingIng(),
                        ),
                      ).then((value) => refreshInfo());
                    },
                  ),
                  ListTile(
                    title: Text("유통기한 확인"),
                    onTap: () {
                      Navigator.pushNamed(context, ChangeDate.id);
                    },
                  ),
                  ListTile(
                    title: Text("내가 쓴 글"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WhatIWritten(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text("로그아웃"),
                    onTap: () {
                      _storage.deleteItem('info');
                      Scaffold.of(context)
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
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _willUseSpeechRecognize ? 1.0 : 0.0,
          duration: Duration(milliseconds: 500),
          child: Visibility(
            visible: _willUseSpeechRecognize,
            child: AvatarGlow(
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
          ),
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(45.0),
          child: Transform(
            transform: Matrix4.translationValues(0, -5.0, 0),
            child: AppBar(
              leading: MaterialButton(
                padding: EdgeInsets.all(0),
                child: _isVisible
                    ? Icon(
                        Icons.search,
                        color: Colors.black45,
                      )
                    : ImageIcon(
                        AssetImage('assets/cutlery.png'),
                      ),
                onPressed: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
              ),
              backgroundColor: Colors.white,
              elevation: 5.0,
              centerTitle: true,
              title: Text(
                '오늘뭐먹지?',
                style: TextStyle(color: Colors.black45),
              ),
              actions: [
                Container(
                  width: 30.0,
                  child: MaterialButton(
                    padding: EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.push(context,
                              MaterialPageRoute(builder: (context) => Write()))
                          .then((_) async => refreshState());
                    },
                    child: SizedBox(
                      width: 20.0,
                      child: Image.asset(
                        'assets/pencil.png',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 30.0,
                  child: MaterialButton(
                    padding: EdgeInsets.all(0),
                    onPressed: () {
                      setState(() {
                        _willUseSpeechRecognize = !_willUseSpeechRecognize;
                      });
                    },
                    child: Icon(
                      Icons.record_voice_over_outlined,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Container(
                  width: 30.0,
                  child: MaterialButton(
                    padding: EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.pushNamed(context, InfoPage.id);
                    },
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Builder(
                  builder: (context) => Container(
                    width: 30.0,
                    child: MaterialButton(
                      padding: EdgeInsets.all(0),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      child: Icon(
                        Icons.menu,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: <Widget>[
            AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: Center(
                child: Column(
                  children: <Widget>[
                    MaterialButton(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.0,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 30,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            borderRadius: BorderRadius.circular(
                              10.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "레시피 검색",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      padding: EdgeInsets.all(0),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchResult(
                              searchParam: materialList.entries
                                  .map((e) => e.key)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 30,
                      height: 30.0,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                searchItem = val;
                              },
                            ),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 30.0,
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent,
                                borderRadius: BorderRadius.circular(
                                  5.0,
                                ),
                              ),
                              child: MaterialButton(
                                child: Center(
                                  child: Text(
                                    "재료 넣기",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  const fs = LocalFileSystem();
                                  setState(() {
                                    if (fs
                                        .file(
                                            '/Users/babosangjamk4/workspace/외주/recipe-app/assets/ingredients/$searchItem.png')
                                        .existsSync()) {
                                      materialList[searchItem] =
                                          'assets/ingredients/$searchItem.png';
                                      ingredientExists[searchItem] = false;
                                    } else {
                                      if (ingredientList.contains(searchItem)) {
                                        materialList[searchItem] =
                                            'assets/dish.png';
                                        ingredientExists[searchItem] = true;
                                      } else {
                                        final alert = AlertDialog(
                                          title: Text('App'),
                                          content: Text('해당 재료가 없습니다.'),
                                          actions: <Widget>[
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
                                      }
                                    }
                                    _controller.clear();
                                    runEverytimeToMatch();
                                  });
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ),
                        child: CustomScrollView(
                          slivers: [
                            SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.0,
                                mainAxisSpacing: 10.0,
                                crossAxisSpacing: 10.0,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return InkWell(
                                    child: Container(
                                      color: Colors.grey[200],
                                      width: 80,
                                      child: Center(
                                        child: ingredientExists[
                                                ingredientsName[index]]
                                            ? Stack(
                                                children: [
                                                  Opacity(
                                                    opacity: 0.5,
                                                    child: Image.asset(
                                                      'assets/dish.png',
                                                      height: 80.0,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  Positioned.fill(
                                                    child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        ingredientsName[index],
                                                        style: TextStyle(
                                                          fontSize: 20.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Image.asset(
                                                materialList.values
                                                    .toList()[index],
                                                height: 80.0,
                                              ),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        ingredientExists.removeWhere(
                                            (key, value) =>
                                                key == ingredientsName[index]);
                                        materialList.removeWhere((key, value) =>
                                            key == ingredientsName[index]);
                                        runEverytimeToMatch();
                                      });
                                    },
                                  );
                                },
                                childCount: materialList.length,
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.only(bottom: 80.0),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 5.0,
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 70.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: !_isVisible,
                          child: Text(
                            "레시피 검색",
                            style: TextStyle(
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 9,
                              child: Visibility(
                                visible: !_isVisible,
                                child: AnimatedContainer(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: !_isVisible
                                          ? Colors.black54
                                          : Colors.transparent,
                                    ),
                                  ),
                                  duration: Duration(milliseconds: 800),
                                  height: 40,
                                  width: !_isVisible ? width : 0,
                                  curve: Curves.easeOut,
                                  child: Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: TextField(
                                      controller: _controller2,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                      ),
                                      onChanged: (val) {
                                        searchParam = val;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                                flex: 1,
                                child: Visibility(
                                  visible: !_isVisible,
                                  child: AnimatedOpacity(
                                    opacity: _isVisible ? 0.0 : 1.0,
                                    duration: Duration(milliseconds: 800),
                                    child: IconButton(
                                      icon: Icon(Icons.search),
                                      onPressed: () {
                                        try {
                                          Recipe search = recipeList
                                              .where((cur) =>
                                                  cur.name == searchParam)
                                              .toList()[0];
                                          if (search != null) {
                                            var parsedSearchParam = [
                                              ...?search.ingredients['주재료'],
                                              ...?search.ingredients['부재료'],
                                              ...?search.ingredients['양념'],
                                            ]
                                                .map((cur) => Map.from(cur)
                                                    .keys
                                                    .toString()
                                                    .replaceAll(
                                                        RegExp('[()]'), ''))
                                                .toList();
                                            parsedSearchParam
                                                .sort((a, b) => a.compareTo(b));
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    RecipePage(
                                                  ingredientsForSearch:
                                                      parsedSearchParam,
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          final alert = AlertDialog(
                                            title: Text('App'),
                                            content: Text('검색 결과가 존재하지 않습니다.'),
                                            actions: <Widget>[
                                              FlatButton(
                                                  onPressed: () {
                                                    var count = 0;
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('OK'))
                                            ],
                                          );
                                          showDialog(
                                            context: context,
                                            builder: (_) => alert,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 15,
                    child: Visibility(
                      visible: !_isVisible,
                      child: AnimatedOpacity(
                        opacity: _isVisible ? 0.0 : 1.0,
                        duration: Duration(milliseconds: 800),
                        child: FutureBuilder(
                          future: _recipeAndImgListAfterFetch,
                          // snapshot.data.recipeList, snapshot.data.imgList
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return CustomScrollView(
                                slivers: <Widget>[
                                  SliverToBoxAdapter(
                                    child: GestureDetector(
                                      onTap: () {
                                        int i = 0;
                                        for (;
                                            i <
                                                    snapshot
                                                        .data
                                                        .recipeList[0]['likes']
                                                        .length &&
                                                !(snapshot.data.recipeList[0]
                                                        ['likes'][i] ==
                                                    jsonDecode(_storage.getItem(
                                                        'info'))['id']);
                                            ++i) {}
                                        if (i <
                                            snapshot.data.recipeList[0]['likes']
                                                .length) {
                                          // 좋아요 기록이 있을경우
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  IndividualRecipe(
                                                recipeList:
                                                    snapshot.data.recipeList[0],
                                                like: true,
                                              ),
                                            ),
                                          ).then((_) async => refreshState());
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  IndividualRecipe(
                                                recipeList:
                                                    snapshot.data.recipeList[0],
                                                like: false,
                                              ),
                                            ),
                                          ).then((_) async => refreshState());
                                          ;
                                        }
                                      },
                                      child: snapshot.data.recipeList.length !=
                                                  0 &&
                                              snapshot
                                                  .data.recipeList.isNotEmpty
                                          ? Container(
                                              width: double.infinity,
                                              color: Colors.grey[100],
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "유저 최고 인기메뉴",
                                                    style: TextStyle(
                                                      fontSize: 18.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 10.0,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Image(
                                                          image: snapshot
                                                              .data.imgList[0],
                                                          width: 100.0,
                                                        ),
                                                        SizedBox(
                                                          width: 10.0,
                                                        ),
                                                        SizedBox(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                snapshot.data
                                                                        .recipeList[
                                                                    0]['name'],
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      20.0,
                                                                ),
                                                              ),
                                                              Text(snapshot.data
                                                                      .recipeList[
                                                                  0]['summary']),
                                                              Row(
                                                                children: [
                                                                  Image.asset(
                                                                    'assets/like.png',
                                                                    width: 15,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 8.0,
                                                                  ),
                                                                  Text(snapshot
                                                                      .data
                                                                      .recipeList[
                                                                          0][
                                                                          'likes']
                                                                      .length
                                                                      .toString())
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : SizedBox(),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: MaterialButton(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10.0,
                                        ),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              30,
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[400],
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "내 냉장고 재료 기반 검색",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      padding: EdgeInsets.all(0),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SearchResult(
                                              searchParam: List<String>.from(
                                                  jsonDecode(_storage.getItem(
                                                      'info'))['userFavor']),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Container(
                                      height: 40.0,
                                      width: double.infinity,
                                      color: Colors.grey[100],
                                      child: Column(
                                        children: [
                                          Text(
                                            "Country",
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Divider(
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 5.0,
                                      mainAxisSpacing: 10.0,
                                      crossAxisSpacing: 10.0,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SearchResult(
                                                  willOrderByFactor:
                                                      nations[index],
                                                  div: 0,
                                                  searchParam: [],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 80,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 1.0,
                                                  spreadRadius: 0.0,
                                                  offset: Offset(0.0,
                                                      2.0), // shadow direction: bottom right
                                                )
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(nations[index]),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: nations.length,
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.only(bottom: 40.0),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Container(
                                      height: 40.0,
                                      width: double.infinity,
                                      color: Colors.grey[100],
                                      child: Column(
                                        children: [
                                          Text(
                                            "Category",
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Divider(
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 5.0,
                                      mainAxisSpacing: 10.0,
                                      crossAxisSpacing: 10.0,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SearchResult(
                                                  willOrderByFactor:
                                                      categories[index],
                                                  div: 1,
                                                  searchParam: [],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 80,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 1.0,
                                                  spreadRadius: 0.0,
                                                  offset: Offset(0.0,
                                                      2.0), // shadow direction: bottom right
                                                )
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(categories[index]),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: categories.length,
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.only(bottom: 40.0),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Container(
                                      height: 40.0,
                                      width: double.infinity,
                                      color: Colors.grey[100],
                                      child: Column(
                                        children: [
                                          Text(
                                            "Level",
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Divider(
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 5.0,
                                      mainAxisSpacing: 10.0,
                                      crossAxisSpacing: 10.0,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SearchResult(
                                                  willOrderByFactor:
                                                      levels[index],
                                                  div: 2,
                                                  searchParam: [],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 80,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 1.0,
                                                  spreadRadius: 0.0,
                                                  offset: Offset(0.0,
                                                      2.0), // shadow direction: bottom right
                                                )
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(levels[index]),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: levels.length,
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.only(bottom: 30.0),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 10.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "사용자 인기 레시피",
                                            style: TextStyle(
                                                fontSize: 20.0,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          GestureDetector(
                                            child: Container(
                                              width: 60.0,
                                              height: 30.0,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                color: Colors.transparent,
                                                border: Border.all(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "더 보기",
                                                ),
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => More(
                                                    recipeList: snapshot
                                                        .data.recipeList,
                                                    imgList:
                                                        snapshot.data.imgList,
                                                  ),
                                                ),
                                              ).then(
                                                  (_) async => refreshState());
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5.0),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 3.5,
                                        mainAxisSpacing: 10.0,
                                        crossAxisSpacing: 10.0,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              int i = 0;
                                              for (;
                                                  i <
                                                          snapshot
                                                              .data
                                                              .recipeList[index]
                                                                  ['likes']
                                                              .length &&
                                                      !(snapshot.data.recipeList[
                                                                  index]
                                                              ['likes'][i] ==
                                                          jsonDecode(_storage
                                                                  .getItem(
                                                                      'info'))[
                                                              'id']);
                                                  ++i) {}
                                              if (i <
                                                  snapshot
                                                      .data
                                                      .recipeList[index]
                                                          ['likes']
                                                      .length) {
                                                // 좋아요 기록이 있을경우
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        IndividualRecipe(
                                                      recipeList: snapshot.data
                                                          .recipeList[index],
                                                      like: true,
                                                    ),
                                                  ),
                                                ).then((_) async =>
                                                    refreshState());
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        IndividualRecipe(
                                                      recipeList: snapshot.data
                                                          .recipeList[index],
                                                      like: false,
                                                    ),
                                                  ),
                                                ).then((_) async =>
                                                    refreshState());
                                              }
                                            },
                                            child: Container(
                                              width: 80,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 1.0,
                                                    spreadRadius: 0.0,
                                                    offset: Offset(0.0,
                                                        2.0), // shadow direction: bottom right
                                                  )
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 10.0,
                                                  ),
                                                  Image(
                                                      image: snapshot
                                                          .data.imgList[index]),
                                                  SizedBox(
                                                    width: 10.0,
                                                  ),
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        snapshot.data
                                                                .recipeList[
                                                            index]['name'],
                                                        style: TextStyle(
                                                          fontSize: 18.0,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                            'assets/like.png',
                                                            width: 15,
                                                          ),
                                                          SizedBox(
                                                            width: 8.0,
                                                          ),
                                                          Text(snapshot
                                                              .data
                                                              .recipeList[index]
                                                                  ['likes']
                                                              .length
                                                              .toString())
                                                        ],
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: snapshot
                                                    .data.recipeList.length >
                                                4
                                            // 최대 4개
                                            ? 4
                                            : snapshot.data.recipeList.length,
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.only(bottom: 50.0),
                                  ),
                                ],
                              );
                            }
                            return Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
