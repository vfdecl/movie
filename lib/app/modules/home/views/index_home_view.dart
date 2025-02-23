// Copyright (C) 2021 d1y <chenhonzhou@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:movie/app/modules/home/controllers/home_controller.dart';
import 'package:movie/app/modules/home/views/home_config.dart';
import 'package:movie/app/routes/app_pages.dart';
import 'package:movie/app/widget/k_body.dart';
import 'package:movie/app/widget/movie_card_item.dart';
import 'package:movie/app/widget/window_appbar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class IndexHomeView extends StatefulWidget {
  const IndexHomeView({Key? key}) : super(key: key);

  @override
  _IndexHomeViewState createState() => _IndexHomeViewState();
}

class _IndexHomeViewState extends State<IndexHomeView> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return IndexHomeViewPage();
  }

  @override
  bool get wantKeepAlive => true;
}

class IndexHomeViewPage extends GetView {
  final HomeController home = Get.find();

  int get cardCount {
    bool isLandscape = Get.context!.isLandscape;
    if (GetPlatform.isMobile && !isLandscape) return 3;
    var w = home.windowLastSize.width;
    if (w >= 1000) return 5;
    return 3;
  }

  double get childAspectRatio {
    return home.windowLastSize.aspectRatio;
    // return (Get.width / cardCount) / (Get.height / cardCount);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (homeview) => Scaffold(
        appBar: WindowAppBar(
          iosBackStyle: true,
          title: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 9,
            ),
            child: Text(
              "YY播放器",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
          actions: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CupertinoButton(
                child: Icon(
                  Icons.movie,
                  color: Colors.white,
                ),
                onPressed: () {
                  homeview.showMirrorModel(context);
                },
              ),
            ),
          ],
        ),
        body: KBody(
          child: SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            header: WaterDropHeader(
              refresh: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(
                    width: 12,
                  ),
                  Text("加载中"),
                ],
              ),
              complete: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.smiley),
                  SizedBox(
                    width: 12,
                  ),
                  Text("加载完成"),
                ],
              ),
            ),
            footer: CustomFooter(
              builder: (BuildContext context, LoadStatus? mode) {
                Widget body;
                if (mode == LoadStatus.idle) {
                  body = Text("上划加载更多");
                } else if (mode == LoadStatus.loading) {
                  body = CupertinoActivityIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = Text("加载失败, 请重试");
                } else if (mode == LoadStatus.canLoading) {
                  body = Text("释放以加载更多");
                } else {
                  body = Text("没有更多数据");
                }
                return Center(
                  child: body,
                );
              },
            ),
            controller: homeview.refreshController,
            onLoading: homeview.refreshOnLoading,
            onRefresh: homeview.refreshOnRefresh,
            child: Builder(
              builder: (_) {
                if (homeview.isLoading) {
                  return Center(child: CupertinoActivityIndicator());
                }
                return SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: Builder(
                    builder: (context) {
                      if (homeview.homedata.isEmpty)
                        return Container(
                          // height: Get.height - Get.height * .2,
                          child: Center(
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/images/empty.png",
                                  fit: BoxFit.cover,
                                  width: Get.width * .8,
                                  height: Get.height * .4,
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                CupertinoButton.filled(
                                  child: Text("重新加载"),
                                  onPressed: () {
                                    homeview.updateHomeData(isFirst: true);
                                  },
                                ),
                                SizedBox(height: 12,),
                                Builder(builder: (context) {
                                  var msg =
                                      homeview.indexHomeLoadDataErrorMessage;
                                  if (msg == "") return SizedBox.shrink();
                                  return Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(Get.width * .05),
                                      child: Text(
                                        msg,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      return Column(
                        children: [
                          SizedBox(
                            height: 24,
                          ),
                          GridView.count(
                            shrinkWrap: true,
                            controller: new ScrollController(
                              keepScrollOffset: false,
                            ),
                            crossAxisCount: cardCount,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                            padding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                            children: [
                              ...homeview.homedata
                                  .map(
                                    (subItem) => MovieCardItem(
                                      imageUrl: subItem.smallCoverImage,
                                      title: subItem.title,
                                      onTap: () async {
                                        var data = subItem;
                                        if (subItem.videos.isEmpty) {
                                          var id = subItem.id;
                                          Get.dialog(
                                            Center(
                                              child:
                                                  CupertinoActivityIndicator(),
                                            ),
                                          );
                                          data = await homeview
                                              .currentMirrorItem
                                              .getDetail(id);
                                          Get.back();
                                        }
                                        Get.toNamed(
                                          Routes.PLAY,
                                          arguments: data,
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            ],
                          ),
                          kBarHeightWidget,
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
