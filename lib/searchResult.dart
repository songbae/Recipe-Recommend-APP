import 'dart:async';
import 'dart:convert';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image/network.dart';
import 'package:recipe_app/recipePage.dart';

class SearchResult extends StatefulWidget {
  List<String> searchParam = [];
  String willOrderByFactor;
  int div;

  SearchResult({this.searchParam, this.willOrderByFactor, this.div});

  @override
  _SearchResultState createState() => _SearchResultState();
}

class _SearchResultState extends State<SearchResult> {
  List<List<String>> searchResult = [];
  List<Recipe> recipeListForRender = [];

  List<Recipe> recipeListForRenderOrderedByFactor = [];

  List<int> recommendation = List.filled(500, 0, growable: false);

  @override
  void initState() {
    Future.delayed(
      Duration.zero,
      () {
        final alert = AlertDialog(
          title: Text('App'),
          content: Text('파라미터 값이 없습니다.'),
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
        if (widget.searchParam.length == 0 && widget.div == null) {
          showDialog(
            context: context,
            builder: (_) => alert,
          );
        }
      },
    );
  }

  Future<List<Recipe>> fetchIngredientList() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/recipe.json');
    List<dynamic> recipeDetail = jsonDecode(data); // 파싱
    Map<String, List<String>> ingredients = {};
    int idx = 0;
    for (int i = 0; i < recipeDetail.length; ++i) {
      List<String> main = [], sub = [], sauce = [];
      recipeDetail
          .map((cur) => cur["ingredients"])
          .toList()[i]['주재료']
          .forEach((el) {
        main.add(el.keys.toString().replaceAll(RegExp('[()]'), ''));
      });
      main.sort((a, b) => a.compareTo(b));
      ingredients["주재료-$idx"] = main;
      recipeDetail
          .map((cur) => cur["ingredients"])
          .toList()[i]['부재료']
          .forEach((el) {
        sub.add(el.keys.toString().replaceAll(RegExp('[()]'), ''));
      });
      sub.sort((a, b) => a.compareTo(b));
      ingredients["부재료-$idx"] = sub;
      recipeDetail
          .map((cur) => cur["ingredients"])
          .toList()[i]['양념']
          .forEach((el) {
        sauce.add(el.keys.toString().replaceAll(RegExp('[()]'), ''));
      });
      sauce.sort((a, b) => a.compareTo(b));
      ingredients["양념-$idx"] = sauce;
      // temp.sort((a, b) => a.compareTo(b));
      // ingredients.add(temp);
      idx++;
    }
    for (int i = 0; i < widget.searchParam.length; ++i) {
      for (int k = 0; k < (ingredients.length) / 3; ++k) {
        for (int j = 0; j < ingredients["주재료-$k"].length; ++j) {
          if (widget.searchParam[i] == ingredients["주재료-$k"][j]) {
            recommendation[k] += 100;
          }
        }
        for (int j = 0; j < ingredients["부재료-$k"].length; ++j) {
          if (widget.searchParam[i] == ingredients["부재료-$k"][j]) {
            recommendation[k] += 50;
          }
        }
        for (int j = 0; j < ingredients["양념-$k"].length; ++j) {
          if (widget.searchParam[i] == ingredients["양념-$k"][j]) {
            recommendation[k] += 10;
          }
        }
      }
    }
    for (int i = 0; i < recommendation.length; ++i) {
      if (recommendation[i] != 0) {
        recipeListForRender.add(
          Recipe.fromJson(recipeDetail[i])..recommendation = recommendation[i],
        );
      }
    }

    recipeListForRender
        .sort((a, b) => b.recommendation.compareTo(a.recommendation));
    return recipeListForRender;
  }

  Future<List<Recipe>> fetchRecipeListOrderedByFactor() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/recipe.json');
    List<dynamic> recipeDetail = jsonDecode(data); // 파싱
    Map<String, List<String>> ingredients = {};
    switch (widget.div) {
      case 0:
        List<String> country = [];
        final detail = recipeDetail
            .where((el) => el['nation'] == widget.willOrderByFactor)
            .toList();
        ingredients['나라'] = country;
        detail.forEach((cur) =>
            {recipeListForRenderOrderedByFactor.add(Recipe.fromJson(cur))});
        recipeListForRenderOrderedByFactor
            .sort((a, b) => a.name.compareTo(b.name));
        return recipeListForRenderOrderedByFactor;
        break;
      case 1:
        List<String> category = [];
        final detail = recipeDetail
            .where((el) => el['category'] == widget.willOrderByFactor)
            .toList();
        ingredients['카테고리'] = category;
        detail.forEach((cur) =>
            {recipeListForRenderOrderedByFactor.add(Recipe.fromJson(cur))});
        recipeListForRenderOrderedByFactor
            .sort((a, b) => a.name.compareTo(b.name));
        return recipeListForRenderOrderedByFactor;
        break;
      case 2:
        List<String> level = [];
        final detail = recipeDetail
            .where((el) => el['level'] == widget.willOrderByFactor)
            .toList();
        ingredients['난이도'] = level;
        detail.forEach((cur) =>
            {recipeListForRenderOrderedByFactor.add(Recipe.fromJson(cur))});
        recipeListForRenderOrderedByFactor
            .sort((a, b) => a.name.compareTo(b.name));
        return recipeListForRenderOrderedByFactor;
        break;
    }
    return List<Recipe>();
  }

  @override
  Widget build(BuildContext context) {
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
            actions: <Widget>[
              Transform(
                transform: Matrix4.translationValues(-10, 0, 0),
                child: Container(
                  width: 30.0,
                  child: widget.willOrderByFactor == null
                      ? MaterialButton(
                          padding: EdgeInsets.all(0),
                          onPressed: () {
                            Flushbar(
                              flushbarPosition: FlushbarPosition.BOTTOM,
                              backgroundColor: Colors.blueAccent,
                              title: "선택된 재료",
                              message: "${widget.searchParam}",
                              duration: Duration(seconds: 2),
                            ).show(context);
                          },
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.black45,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
      body: widget.searchParam.length != 0 && widget.willOrderByFactor == null
          ? FutureBuilder<List<Recipe>>(
              future: fetchIngredientList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: recipeListForRender.length,
                    itemBuilder: (context, idx) {
                      return Column(
                        children: [
                          idx == 0 || idx == 1 ? SizedBox() : Divider(),
                          MaterialButton(
                            padding: EdgeInsets.all(0),
                            child: Container(
                              height: 100,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 10.0,
                                    ),
                                    child: Image(
                                      width: 80,
                                      fit: BoxFit.fitWidth,
                                      image: NetworkImageWithRetry(
                                        recipeListForRender[idx].picture,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                              '${recipeListForRender[idx].name}'),
                                          SizedBox(
                                            width: 5.0,
                                          ),
                                          idx >= 0 && idx < 10
                                              ? SubTitle(
                                                  title: "추천",
                                                  color: Colors.redAccent,
                                                )
                                              : SizedBox(),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10.0,
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            size: 12.0,
                                          ),
                                          Text(
                                              " ${recipeListForRender[idx].recommendation}")
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                            onPressed: () {
                              var searchParam = [
                                ...?recipeListForRender[idx].ingredients['주재료'],
                                ...?recipeListForRender[idx].ingredients['부재료'],
                                ...?recipeListForRender[idx].ingredients['양념'],
                              ]
                                  .map((cur) => Map.from(cur)
                                      .keys
                                      .toString()
                                      .replaceAll(RegExp('[()]'), ''))
                                  .toList();
                              searchParam.sort((a, b) => a.compareTo(b));
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipePage(
                                    ingredientsForSearch: searchParam,
                                  ),
                                ),
                              );
                            },
                          ),
                          idx == recipeListForRender.length
                              ? Divider()
                              : SizedBox()
                        ],
                      );
                    },
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )
          : FutureBuilder<List<Recipe>>(
              future: fetchRecipeListOrderedByFactor(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: recipeListForRenderOrderedByFactor.length,
                    itemBuilder: (context, idx) {
                      return Column(
                        children: [
                          idx == 0 || idx == 1 ? SizedBox() : Divider(),
                          MaterialButton(
                            padding: EdgeInsets.all(0),
                            child: Container(
                              height: 100,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 10.0,
                                    ),
                                    child: Image(
                                      width: 80,
                                      fit: BoxFit.fitWidth,
                                      image: NetworkImageWithRetry(
                                        recipeListForRenderOrderedByFactor[idx]
                                            .picture,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                              '${recipeListForRenderOrderedByFactor[idx].name}'),
                                          SizedBox(
                                            width: 5.0,
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10.0,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            onPressed: () {
                              var searchParam = [
                                ...?recipeListForRenderOrderedByFactor[idx]
                                    .ingredients['주재료'],
                                ...?recipeListForRenderOrderedByFactor[idx]
                                    .ingredients['부재료'],
                                ...?recipeListForRenderOrderedByFactor[idx]
                                    .ingredients['양념'],
                              ]
                                  .map((cur) => Map.from(cur)
                                      .keys
                                      .toString()
                                      .replaceAll(RegExp('[()]'), ''))
                                  .toList();
                              searchParam.sort((a, b) => a.compareTo(b));
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipePage(
                                    ingredientsForSearch: searchParam,
                                  ),
                                ),
                              );
                            },
                          ),
                          idx == recipeListForRender.length
                              ? Divider()
                              : SizedBox()
                        ],
                      );
                    },
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
    );
  }
}
