import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_image/network.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class _Recipe {
  String name;
  String summary;
  String nation;
  String qnt;
  String cal;
  String level;
  String picture;
  String category;
  List<String> ingredients;
  List<dynamic> info;
  List<String> likes;

  _Recipe(this.name, this.summary, this.nation, this.qnt, this.cal, this.level,
      this.picture, this.category, this.ingredients, this.info);

  _Recipe.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        summary = json['summary'],
        nation = json['nation'],
        qnt = json['qnt'],
        cal = json['cal'],
        level = json['level'],
        picture = json['picture'],
        category = json['category'],
        ingredients = List<String>.from(jsonDecode(json['ingredients'])),
        info = jsonDecode(json['info']),
        likes = List<String>.from(json['likes']);
}

class Ing {
  String name;
  String quantity;

  Ing(this.name, this.quantity);
}

class IndividualRecipe extends StatefulWidget {
  final Map<String, dynamic> recipeList;
  final List<ImageProvider> imgList;
  bool like = false;

  IndividualRecipe({this.recipeList, this.like, this.imgList});

  @override
  _IndividualRecipeState createState() => _IndividualRecipeState();
}

class _IndividualRecipeState extends State<IndividualRecipe> {
  String mainIng = '';
  String subIng = '';
  String sauceIng = '';
  _Recipe renderParam;
  List<ImageProvider> imageList = [];
  Future providers;
  mongo.GridFS bucket;
  mongo.DbCollection collection;
  mongo.Db _db;
  LocalStorage _storage;
  int like;
  List<FutureBuilder> recipeProcess = [];

  Future<List<ImageProvider>> fetchImage() async {
    await _db.open(secure: true);
    bucket = mongo.GridFS(_db, 'image');
    var img = await bucket.chunks.findOne({"_id": renderParam.picture});
    imageList.add(MemoryImage(base64Decode(img["data"])));

    for (var i = 0; i < renderParam.info.length; ++i) {
      var img = await bucket.chunks.findOne({
        "_id": renderParam.info[i]['picture'],
      });
      imageList.add(MemoryImage(base64Decode(img["data"])));
    }

    return Future.value(imageList);
  }

  @override
  void dispose() {
    recipeProcess.clear();
    imageList.clear();
    super.dispose();
  }

  @override
  void initState() {
    renderParam = _Recipe.fromJson(widget.recipeList);
    renderParam.ingredients.forEach((cur) {
      mainIng += "$cur ";
    });
    _db = mongo.Db('mongodb://songbae:dotslab1234@'
        'cluster0-shard-00-00.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-01.isb9a.mongodb.net:27017,'
        'cluster0-shard-00-02.isb9a.mongodb.net:27017/'
        'toy_project?authSource=admin&compressors=disabled'
        '&gssapiServiceName=mongodb&retryWrites=true&w=majority'
        '&ssl=true');
    collection = _db.collection('recipe');
    providers = fetchImage();
    for (int i = 0; i < renderParam.info.length; ++i) {
      recipeProcess.add(
        FutureBuilder(
          // 없는 경우도 있음
          future: providers,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step ${i + 1}",
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      child: Image(
                        width: MediaQuery.of(context).size.width - 20,
                        fit: BoxFit.fitWidth,
                        image: snapshot.data[i + 1],
                      ),
                    ),
                    Text(renderParam.info[i]["content"]),
                    SizedBox(
                      height: 20.0,
                    ),
                  ],
                ),
              );
            }
            return Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step ${i + 1}",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(renderParam.info[i]["content"]),
                  SizedBox(
                    height: 20.0,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    like = renderParam.likes.length;
    _storage = LocalStorage("login_info");
  }

  @override
  Widget build(BuildContext context) {
    final ingTextStyle = TextStyle(fontSize: 16.0);
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
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
            title: Text(
              '오늘뭐먹지?',
              style: TextStyle(color: Colors.black45),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                children: [
                  FutureBuilder(
                    future: providers,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image(
                          image: snapshot.data[0],
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.fitWidth,
                        );
                      }
                      return CircularProgressIndicator();
                    },
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: 10.0,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 30,
                          color: Colors.pinkAccent.withOpacity(0.6),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 15.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                renderParam?.summary != null
                                    ? Text(
                                        renderParam.summary,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15.0),
                                      )
                                    : CircularProgressIndicator(),
                                SizedBox(
                                  height: 10.0,
                                ),
                                renderParam?.name != null
                                    ? Text(
                                        renderParam.name,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 23.0),
                                      )
                                    : CircularProgressIndicator()
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Row(
                      children: [
                        GestureDetector(
                          child: Icon(
                            widget.like == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 40,
                            color: Colors.pinkAccent,
                          ),
                          onTap: () {
                            //TODO: add my id to the db
                            setState(() {
                              widget.like = !widget.like;
                            });
                            if (!widget.like) {
                              collection.update({
                                "_id": widget.recipeList["_id"]
                              }, {
                                "\$pull": {
                                  "likes":
                                      jsonDecode(_storage.getItem('info'))['id'],
                                },
                              }, upsert: true);
                              setState(() {
                                like--;
                              });
                            } else {
                              collection.update({
                                "_id": widget.recipeList["_id"]
                              }, {
                                "\$push": {
                                  "likes":
                                      jsonDecode(_storage.getItem('info'))['id'],
                                }
                              });
                              setState(() {
                                like++;
                              });
                            }
                          },
                        ),
                        Text(
                          like.toString(),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20.0,
              ),
              Center(
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  color: Colors.pinkAccent,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/synthetic-material.png',
                                width: 30.0,
                              ),
                              Text(
                                "재료 정보",
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),
                        Divider(
                          thickness: 1.0,
                          indent: 20.0,
                          endIndent: 20.0,
                          color: Colors.black54,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 20.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              renderParam?.qnt != null
                                  ? Text(
                                      "${renderParam.qnt} 기준",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : CircularProgressIndicator(),
                              SizedBox(
                                height: 20.0,
                              ),
                              SubTitle(
                                title: "주재료",
                                color: Colors.pinkAccent,
                              ),
                              Text(
                                mainIng,
                                style: ingTextStyle,
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              SubTitle(
                                title: "부재료",
                                color: Colors.blueAccent,
                              ),
                              Text(
                                subIng,
                                style: ingTextStyle,
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              SubTitle(
                                title: "양념",
                                color: Colors.yellow,
                              ),
                              Text(
                                sauceIng,
                                style: ingTextStyle,
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          thickness: 1.0,
                          indent: 20.0,
                          endIndent: 20.0,
                          color: Colors.black54,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Center(
                            child: Text(
                              "*재료 계측량은 개인 취향에 따라 차이가 있을 수 있습니다.",
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Center(
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  color: Colors.pinkAccent,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/cookbook.png',
                                width: 30.0,
                              ),
                              Text(
                                "레시피 정보",
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),
                        Divider(
                          thickness: 1.0,
                          indent: 20.0,
                          endIndent: 20.0,
                          color: Colors.black54,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 15.0,
                            horizontal: 20.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              renderParam?.cal != null
                                  ? Text(
                                      "칼로리: ${renderParam.cal}",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : CircularProgressIndicator(),
                              SizedBox(
                                height: 25.0,
                              ),
                              renderParam?.level != null
                                  ? Text(
                                      "난이도: ${renderParam.level}",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : CircularProgressIndicator(),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Center(
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  color: Colors.pinkAccent,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/soup.png',
                                width: 30.0,
                              ),
                              Text(
                                "레시피 과정",
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),
                        Divider(
                          thickness: 1.0,
                          indent: 20.0,
                          endIndent: 20.0,
                          color: Colors.black54,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 15.0,
                            horizontal: 20.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recipeProcess,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubTitle extends StatelessWidget {
  final title;
  final color;

  SubTitle({
    @required this.title,
    @required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 3.0,
          horizontal: 2.0,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.0,
            color: color,
          ),
        ),
      ),
      decoration: BoxDecoration(
          border: Border.all(
            color: color,
          ),
          borderRadius: BorderRadius.circular(8.0)),
    );
  }
}
