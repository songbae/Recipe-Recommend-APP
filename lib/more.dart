import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:recipe_app/individualRecipe.dart';

class More extends StatefulWidget {
  final recipeList;
  final imgList;

  More({this.recipeList, this.imgList});

  @override
  _MoreState createState() => _MoreState();
}

class _MoreState extends State<More> {

  LocalStorage _storage;

  @override
  void initState() {
    _storage = LocalStorage('login_info');
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
            MaterialButton(onPressed: () {
              print(widget.imgList);
            })
          ],
        ),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.0),
              border: Border.all(
                color: Colors.black54,
                width: 0.2,
              )
            ),
            child: GestureDetector(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0
                ),
                child: ListTile(
                  title: Text(widget.recipeList[index]['name']),
                  leading: Image(
                    image: widget.imgList[index]
                  ),
                ),
              ),
              onTap: () {
                int i = 0;
                for (;
                i <widget.recipeList[index]
                    ['likes']
                        .length &&
                    !(widget.recipeList[
                    index]
                    ['likes'][i] ==
                        jsonDecode(_storage
                            .getItem(
                            'info'))[
                        'id']);
                ++i) {}
                if (i <
                    widget.recipeList[index]
                    ['likes']
                        .length) {
                  // 좋아요 기록이 있을경우
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          IndividualRecipe(
                            recipeList: widget.recipeList[index],
                            like: true,
                          ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          IndividualRecipe(
                            recipeList:
                                widget.recipeList[index],
                            like: false,
                          ),
                    ),
                  );
                }
              },
            ),
          );
        },
        itemCount: widget.recipeList.length,
      ),
    );
  }
}
