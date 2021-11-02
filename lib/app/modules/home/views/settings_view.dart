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
import 'package:flutter/services.dart';
import 'package:flutter_cupertino_settings/flutter_cupertino_settings.dart';

import 'package:get/get.dart';
import 'package:movie/app/modules/home/controllers/home_controller.dart';
import 'package:movie/config.dart';
import 'package:movie/mirror/m_utils/source_utils.dart';

import 'nsfwtable.dart';

enum GetBackResultType {
  /// 失败
  fail,

  /// 成功
  success
}

enum HandleDiglogTapType {
  /// 清空
  clean,

  /// 获取配置
  kget,
}

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final HomeController home = Get.find<HomeController>();

  Future<String> loadAsset() async {
    return await rootBundle.loadString('assets/data/source_help.txt');
  }

  String sourceHelpText = "";

  bool _isDark = false;

  bool get isDark {
    return _isDark;
  }

  set isDark(bool newVal) {
    home.localStorage.write(ConstDart.ls_isDark, newVal);
    setState(() {
      _isDark = newVal;
    });
    Get.changeTheme(!newVal ? ThemeData.light() : ThemeData.dark());
  }

  @override
  void initState() {
    setState(() {
      _isDark = home.localStorage.read(ConstDart.ls_isDark) ?? false;
    });
    loadSourceHelp();
    super.initState();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  loadSourceHelp() async {
    var data = await loadAsset();
    setState(() {
      sourceHelpText = data;
    });
  }

  bool get showNSFW {
    return (home.isNsfw || nShowNSFW >= 10);
  }

  set showNSFW(newVal) {
    setState(() {
      nShowNSFW = !newVal ? 0 : 10;
    });
  }

  int nShowNSFW = 0;

  TextEditingController _editingController = TextEditingController();

  String get editingControllerValue {
    return _editingController.text.trim();
  }

  set editingControllerValue(String newVal) {
    _editingController.text = newVal;
  }

  handleDiglogTap(HandleDiglogTapType type) async {
    switch (type) {
      case HandleDiglogTapType.clean:
        editingControllerValue = "";
        Get.showSnackbar(
          GetBar(
            message: "解析内容已经清空!",
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case HandleDiglogTapType.kget:
        if (editingControllerValue.isEmpty) {
          Get.showSnackbar(
            GetBar(
              message: "内容为空, 请填入url!",
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        var target = SourceUtils.getSources(editingControllerValue);
        Get.dialog(GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(
                  height: 42,
                ),
                CupertinoButton.filled(
                  child: Text("关闭"),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ],
            ),
          ),
        ));
        var data = await SourceUtils.runTaks(target);
        Get.back();
        if (data.isEmpty) {
          Get.showSnackbar(
            GetBar(
              message: "获取的内容为空!",
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        SourceUtils.mergeMirror(data);
        Get.showSnackbar(
          GetBar(
            message: "获取成功, 已合并资源",
            duration: Duration(seconds: 1),
          ),
        );
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("设置"),
        centerTitle: true,
        elevation: 0,
      ),
      body: CupertinoSettings(
        items: <Widget>[
          const CSHeader('常规设置'),
          CSControl(
            nameWidget: Text('深色'),
            contentWidget: CupertinoSwitch(
              value: isDark,
              onChanged: (bool value) {
                isDark = value;
              },
            ),
            style: const CSWidgetStyle(
              icon: const Icon(
                Icons.settings_brightness,
              ),
            ),
          ),
          GestureDetector(
            child: CSControl(
              nameWidget: Text("视频源管理"),
              style: const CSWidgetStyle(
                icon: const Icon(
                  Icons.video_library,
                ),
              ),
            ),
            onTap: () {
              Get.defaultDialog(
                actions: [
                  CupertinoButton.filled(
                    child: Text("清空"),
                    onPressed: () {
                      handleDiglogTap(HandleDiglogTapType.clean);
                    },
                  ),
                  CupertinoButton.filled(
                    child: Text("获取配置"),
                    onPressed: () {
                      handleDiglogTap(HandleDiglogTapType.kget);
                    },
                  ),
                ],
                titlePadding: EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 12,
                ),
                title: "我的视频源网络地址",
                titleStyle: TextStyle(
                  fontSize: 16,
                ),
                content: Container(
                  height: context.heightTransformer(dividedBy: 1.8),
                  width: context.widthTransformer(dividedBy: 1),
                  child: Card(
                    color: Color.fromRGBO(0, 0, 0, .02),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _editingController,
                        maxLines: 10,
                        decoration: InputDecoration.collapsed(
                          hintText: sourceHelpText,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          showNSFW
              ? CSControl(
                  nameWidget: Text('NSFW'),
                  contentWidget: CupertinoSwitch(
                    value: home.isNsfw,
                    onChanged: (bool value) async {
                      if (value) {
                        GetBackResultType result =
                            await Get.to(() => NsfwTableView());
                        if (result == GetBackResultType.success) {
                          home.isNsfw = true;
                          showNSFW = true;
                          home.update();
                          return;
                        }
                      }
                      showNSFW = false;
                      home.isNsfw = false;
                      home.update();
                    },
                  ),
                  style: const CSWidgetStyle(
                    icon: const Icon(
                      Icons.stop_screen_share,
                    ),
                  ),
                )
              : SizedBox.shrink(),
          GestureDetector(
            onTap: () {
              if (showNSFW) {
                showNSFW = false;
              } else {
                setState(() {
                  nShowNSFW++;
                });
              }
            },
            child: CSDescription(
              "@陈大大哦了",
            ),
          ),
        ],
      ),
    );
  }
}
