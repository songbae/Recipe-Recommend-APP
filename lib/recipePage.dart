import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_image/network.dart';

class Recipe {
  String name;
  String summary;
  String nation;
  String qnt;
  String cal;
  String level;
  String picture;
  String category;
  Map<String, dynamic> ingredients;
  List<dynamic> info;
  int recommendation;

  Recipe(this.name, this.summary, this.nation, this.qnt, this.cal, this.level,
      this.picture, this.category, this.ingredients, this.info);

  Recipe.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        summary = json['summary'],
        nation = json['nation'],
        qnt = json['qnt'],
        cal = json['cal'],
        level = json['level'],
        picture = json['picture'],
        category = json['category'],
        ingredients = json['ingredients'],
        info = json['info'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'summary': summary,
        'nation': nation,
        'qnt': qnt,
        'cal': cal,
        'level': level,
        'picture': picture,
        'category': category,
        'ingredients': ingredients,
        'info': info,
      };
}

class Ing {
  String name;
  String quantity;

  Ing(this.name, this.quantity);
}

class RecipePage extends StatefulWidget {
  var ingredientsForSearch = [];

  RecipePage({this.ingredientsForSearch});

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  Recipe recipe;
  bool isRecipeAvailable = false;
  String mainIng = '';
  String subIng = '';
  String sauceIng = '';
  List<Container> recipeProcess = [];

  @override
  void initState() {
    fetchRecipe();
  }

  void fetchRecipe() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/recipe.json');
    List<dynamic> recipeDetail = jsonDecode(data);
    List<List<String>> ingredients = [];
    for (int i = 0; i < recipeDetail.length; ++i) {
      List<String> temp = [];
      [
        ...?recipeDetail.map((cur) => cur["ingredients"]).toList()[i]['주재료'],
        ...?recipeDetail.map((cur) => cur["ingredients"]).toList()[i]['부재료'],
        ...?recipeDetail.map((cur) => cur["ingredients"]).toList()[i]['양념']
      ].forEach((element) {
        temp.add(element.keys.toString().replaceAll(RegExp('[()]'), ''));
      });
      temp.sort((a, b) => a.compareTo(b));
      ingredients.add(temp);
    }
    widget.ingredientsForSearch.sort((a, b) => a.compareTo(b));
    Function eq = ListEquality().equals;
    int idx = 0;
    for (;
        idx < ingredients.length &&
            !(eq(ingredients[idx], widget.ingredientsForSearch));
        ++idx);
    if (idx < ingredients.length) {
      recipe = Recipe.fromJson(recipeDetail[idx]);
      setState(() {
        isRecipeAvailable = true;
      });
    } else {
      final alert = AlertDialog(
        title: Text('App'),
        content: Text('해당 레시피가 없습니다.'),
        actions: <Widget>[
          FlatButton(
              onPressed: () {
                var count = 0;
                Navigator.popUntil(context, (route) {
                  return count++ == 2;
                });
              },
              child: Text('OK'))
        ],
      );
      showDialog(
        context: context,
        builder: (_) => alert,
      );
    }

    // 주재료 파싱

    for (int i = 0; i < recipe.ingredients["주재료"].length; ++i) {
      recipe.ingredients['주재료'][i].forEach((key, value) => {
            mainIng += "$key $value / ",
          });
    }
    mainIng = mainIng != '' ? mainIng.substring(0, mainIng.length - 2) : '';
    for (int i = 0; i < recipe.ingredients["부재료"].length; ++i) {
      recipe.ingredients['부재료'][i].forEach((key, value) => {
            subIng += "$key $value / ",
          });
    }
    subIng = subIng != '' ? subIng.substring(0, subIng.length - 2) : '';
    for (int i = 0; i < recipe.ingredients["양념"].length; ++i) {
      recipe.ingredients['양념'][i].forEach((key, value) => {
            sauceIng += "$key $value / ",
          });
    }
    sauceIng = sauceIng != '' ? sauceIng.substring(0, sauceIng.length - 2) : '';
    // 레시피 과정
    for (int i = 0; i < recipe.info.length; ++i) {
      recipeProcess.add(
        Container(
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
              recipe?.info[i]["picture"] != ""
                  ? SizedBox(
                      child: Image(
                        width: MediaQuery.of(context).size.width - 20,
                        fit: BoxFit.fitWidth,
                        image: NetworkImageWithRetry(
                          recipe.info[i]["picture"],
                        ),
                      ),
                    )
                  : SizedBox(),
              Text(recipe.info[i]["content"]),
              SizedBox(
                height: 20.0,
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingTextStyle = TextStyle(fontSize: 16.0);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0),
        child: Transform(
          transform: Matrix4.translationValues(0, -5.0, 0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 5.0,
            title: Text(
              '오늘뭐먹지?',
              style: TextStyle(color: Colors.black45),
            ),
          ),
        ),
      ),
      body: Visibility(
        visible: isRecipeAvailable,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                children: [
                  recipe?.picture != null
                      ? Image(
                          image: NetworkImageWithRetry(
                            recipe.picture,
                          ),
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.fitWidth,
                        )
                      : CircularProgressIndicator(),
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
                                recipe?.summary != null
                                    ? Text(
                                        recipe.summary,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.0),
                                      )
                                    : CircularProgressIndicator(),
                                SizedBox(
                                  height: 10.0,
                                ),
                                recipe?.name != null
                                    ? Text(
                                        recipe.name,
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
                  )
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
                              recipe?.qnt != null
                                  ? Text(
                                      "${recipe.qnt} 기준",
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
                              mainIng != ''
                                  ? Text(
                                      mainIng,
                                      style: ingTextStyle,
                                    )
                                  : Container(),
                              SizedBox(
                                height: 20.0,
                              ),
                              SubTitle(
                                title: "부재료",
                                color: Colors.blueAccent,
                              ),
                              subIng != ''
                                  ? Text(
                                      subIng,
                                      style: ingTextStyle,
                                    )
                                  : Container(),
                              SizedBox(
                                height: 20.0,
                              ),
                              SubTitle(
                                title: "양념",
                                color: Colors.yellow,
                              ),
                              sauceIng != ''
                                  ? Text(
                                      sauceIng,
                                      style: ingTextStyle,
                                    )
                                  : Container(),
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
                              recipe?.cal != null ? Text(
                                "칼로리: ${recipe.cal}",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ) : CircularProgressIndicator(),
                              SizedBox(
                                height: 25.0,
                              ),
                              recipe?.level != null ? Text(
                                "난이도: ${recipe.level}",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ) : CircularProgressIndicator(),
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
