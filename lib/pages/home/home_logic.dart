import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mood_diary/api/api.dart';
import 'package:mood_diary/pages/home/assistant/assistant_logic.dart';
import 'package:mood_diary/pages/home/diary/diary_logic.dart';
import 'package:mood_diary/router/app_routes.dart';
import 'package:mood_diary/utils/utils.dart';

import 'home_state.dart';

class HomeLogic extends GetxController with GetTickerProviderStateMixin {
  final HomeState state = HomeState();

  //fab动画控制器
  late AnimationController fabAnimationController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

  //fab动画插值器
  late Animation<double> fabAnimation =
      Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: fabAnimationController, curve: Curves.easeInOut));

  //bar动画控制器
  late AnimationController barAnimationController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

  //动画插值器
  late Animation<double> barAnimation =
      Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: barAnimationController, curve: Curves.easeInOut));

  late PageController pageController = PageController();

  late final DiaryLogic diaryLogic = Bind.find<DiaryLogic>();
  late final AssistantLogic assistantLogic = Bind.find<AssistantLogic>();

  @override
  void onReady() {
    unawaited(Utils().updateUtil.checkShouldUpdate(Utils().prefUtil.getValue<String>('appVersion')!.split('+')[0]));
    unawaited(getHitokoto());
    super.onReady();
  }

  @override
  void onClose() {
    fabAnimationController.dispose();
    barAnimationController.dispose();
    pageController.dispose();
    super.onClose();
  }

  //获取一言
  Future<void> getHitokoto() async {
    if (Platform.isWindows) {
      var res = await Utils().cacheUtil.getCacheList('hitokoto', Api().updateHitokoto, maxAgeMillis: 15 * 60000);
      if (res != null) {
        state.hitokoto.value = res.first;
      }
    }
  }

  //打开fab
  Future<void> openFab() async {
    await HapticFeedback.vibrate();
    state.isFabExpanded.value = true;
    await fabAnimationController.forward();
  }

  //关闭fab
  Future<void> closeFab() async {
    await HapticFeedback.selectionClick();
    await fabAnimationController.reverse();
    state.isFabExpanded.value = false;
  }

  //锁定屏幕
  void lockPage() {
    //如果开启密码的同时开启了立即锁定，就直接跳转到锁屏页面
    if (Utils().prefUtil.getValue<bool>('lock') == true && Utils().prefUtil.getValue<bool>('lockNow') == true) {
      Get.toNamed(AppRoutes.lockPage, arguments: 'pause');
    }
  }

  void toUserPage() {
    //如果已经登录
    if (Utils().supabaseUtil.user != null || Utils().supabaseUtil.session != null) {
      Get.toNamed(AppRoutes.userPage);
    } else {
      Get.toNamed(AppRoutes.loginPage);
    }
  }

  //新增一篇日记
  Future<void> toEditPage() async {
    //同时关闭fab
    await HapticFeedback.selectionClick();
    fabAnimationController.reset();
    state.isFabExpanded.value = false;

    /// 需要注意，返回值为 '' 时才是没有选择分类，而返回值为 null 时，是没有进行操作直接返回
    var res = await Get.toNamed(AppRoutes.editPage, arguments: 'new');

    if (res != null) {
      if (res == '') {
        await diaryLogic.updateDiary(null);
      } else {
        await diaryLogic.updateDiary(res);
      }
    }
  }

  Future<void> hideNavigatorBar() async {
    await barAnimationController.forward();
    state.isBarHidden.value = true;
  }

  Future<void> showNavigatorBar() async {
    state.isBarHidden.value = false;
    await barAnimationController.reverse();
  }

  void resetNavigatorBar() {
    barAnimationController.reset();
    state.isBarHidden.value = true;
  }

  // 切换导航栏
  void changeNavigator(int index) {
    state.navigatorIndex.value = index;
    pageController.jumpToPage(index);
  }
}
