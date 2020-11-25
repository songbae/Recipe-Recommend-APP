import 'dart:convert';
import 'dart:collection';

import 'package:file/local.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:recipe_app/infoPage.dart';
import 'package:recipe_app/searchResult.dart';
import 'package:recipe_app/recipePage.dart';
import 'package:recipe_app/write.dart';
import 'searchResult.dart';
import 'package:recipe_app/Voice.dart';

class MainPage extends StatefulWidget {
  static const id = 'main_page';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isVisible = true;
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

  LocalStorage storage;

  @override
  void initState() {
    fetchIngredients();
    fetchRecipe();
    storage = LocalStorage('login_info');
  }

  void runEverytimeToMatch() {
    ingredientsName = materialList.entries.map((e) => e.key).toList();
  }

  void fetchIngredients() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/ingredient.json');
    storage.setItem('ing', data);
    ingredientList = jsonDecode(data).map((cur) => cur["name"]).toList();
  }

  void fetchRecipe() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/recipe.json');
    storage.setItem('recipe', data);
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
  }


  @override
  Widget build(BuildContext context) {
    double width = !isVisible ? MediaQuery.of(context).size.width - 30 : 0;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(

        floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
            context,
            CupertinoPageRoute(builder:(context)=>Voice()),
          );
        },
        child: Icon(Icons.keyboard_voice),
          backgroundColor: Colors.black,
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(45.0),
          child: Transform(
            transform: Matrix4.translationValues(0, -5.0, 0),
            child: AppBar(
              leading: MaterialButton(
                padding: EdgeInsets.all(0),
                child: isVisible
                    ? Icon(
                        Icons.search,
                        color: Colors.black45,
                      )
                    : ImageIcon(
                        AssetImage('assets/cutlery.png'),
                      ),
                onPressed: () {
                  setState(() {
                    isVisible = !isVisible;
                  });
                },
              ),
              backgroundColor: Colors.white,
              elevation: 5.0,
              title: Padding(
                padding: EdgeInsets.only(left: 70.0),
                child: Text(
                  '오늘뭐먹지?',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
              actions: [
                Container(
                  width: 30.0,
                  child: MaterialButton(
                    padding: EdgeInsets.all(0),
                    onPressed: () {
                      Navigator.pushNamed(context, Write.id);
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
                      Navigator.pushNamed(context, InfoPage.id);
                    },
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.black45,
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
              opacity: isVisible ? 1.0 : 0.0,
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
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(
                              10.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "내 냉장고 재료 기반 검색",
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
                              searchParam: List<String>.from(jsonDecode(
                                  storage.getItem('info'))['userFavor']),
                            ),
                          ),
                        );
                      },
                    ),
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
                                onPressed: () {
                                  const fs = LocalFileSystem();
                                  setState(() {
                                    if (fs
                                        .file(
                                            '/recipe-app/recipe-app/assets/ingredients/$searchItem.png')
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
                    child: Row(
                      children: [
                        Expanded(
                          flex: 9,
                          child: Visibility(
                            visible: !isVisible,
                            child: AnimatedContainer(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: !isVisible
                                      ? Colors.black54
                                      : Colors.transparent,
                                ),
                              ),
                              duration: Duration(milliseconds: 800),
                              height: 40,
                              width: width,
                              curve: Curves.easeOut,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: TextField(
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
                              visible: !isVisible,
                              child: AnimatedOpacity(
                                opacity: isVisible ? 0.0 : 1.0,
                                duration: Duration(milliseconds: 800),
                                child: IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: () {
                                    try {
                                      Recipe search = recipeList
                                          .where(
                                              (cur) => cur.name == searchParam)
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
                                                .replaceAll(RegExp('[()]'), ''))
                                            .toList();
                                        parsedSearchParam
                                            .sort((a, b) => a.compareTo(b));
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RecipePage(
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
                  ),
                  Expanded(
                    flex: 15,
                    child: Visibility(
                      visible: !isVisible,
                      child: AnimatedOpacity(
                        opacity: isVisible ? 0.0 : 1.0,
                        duration: Duration(milliseconds: 800),
                        child: CustomScrollView(
                          slivers: <Widget>[
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
                                          builder: (context) => SearchResult(
                                            willOrderByFactor: nations[index],
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
                                          builder: (context) => SearchResult(
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
                                          builder: (context) => SearchResult(
                                            willOrderByFactor: levels[index],
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
                              padding: EdgeInsets.only(bottom: 80.0),
                            ),
                          ],
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
