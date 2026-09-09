import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
void main(){
 Widget host(Widget child)=>MaterialApp(home:Scaffold(body:SingleChildScrollView(child:child)));
 testWidgets('current device cannot be revoked; stale media cannot be opened',(tester)async{
  var ids=<String>[];
  await tester.pumpWidget(host(FlareDeviceSessions(items:const [FlareDeviceSessionEntry(id:'self',title:'本机',detail:'当前会话',current:true,actions:[FlareSceneAction(id:'revoke',label:'退出')]),FlareDeviceSessionEntry(id:'other',title:'其他设备',detail:'会话',actions:[FlareSceneAction(id:'revoke',label:'退出')])],onAction:(id,a)=>ids.add(id))));
  expect(find.text('退出'),findsOneWidget);await tester.tap(find.text('退出'));expect(ids,['other']);
  await tester.pumpWidget(host(FlareMediaCenter(items:const [FlareMediaEntry(id:'file',title:'文件',detail:'地址过期',kind:FlareMediaKind.file,availability:FlareMediaAvailability.expired,actions:[FlareSceneAction(id:'open',label:'打开'),FlareSceneAction(id:'refresh',label:'更新地址')])],onAction:(id,a)=>ids.add(a))));
  expect(find.text('打开'),findsNothing);await tester.tap(find.text('更新地址'));expect(ids.last,'refresh');
 });
 testWidgets('permission gate hides optional UI and disables preferences',(tester)async{
  await tester.pumpWidget(host(const FlareCapabilityBoundary(state:FlareCapabilityState.denied,text:'无权限',child:Text('插件内容'))));expect(find.text('插件内容'),findsNothing);expect(find.text('无权限'),findsOneWidget);
  await tester.pumpWidget(host(FlareNotificationPreferences(items:const [FlareNotificationPreference(id:'preview',title:'预览',detail:'正文',value:true,enabled:true)],permission:FlareCapabilityState.denied,permissionText:'无权限',onChange:(_,__)=>fail('must stay disabled'))));
  expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,isNull);
 });
 testWidgets('small screen large text and busy confirmation remain usable',(tester)async{
  tester.view.physicalSize=const Size(320,1000);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(textScaler:TextScaler.linear(2)),child:Scaffold(body:FlareDangerConfirm(title:'移除成员',description:'确认移除这个成员的访问权限',target:'很长的成员名称和具体操作对象',error:'操作失败，可以重试',busy:true,onConfirm:()=>fail('busy'),onCancel:()=>fail('busy'))))));
  for(final b in tester.widgetList<TextButton>(find.byType(TextButton))){expect(b.onPressed,isNull);}expect(tester.takeException(),isNull);
 });
}
