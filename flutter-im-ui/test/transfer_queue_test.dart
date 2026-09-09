import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
void main() {
  const retry={FlareTransferAction.retry:'重试'};
  const items=[
    FlareTransferQueueItem(id:'a',name:'失败文件.pdf',state:FlareTransferState.failed,statusText:'网络中断',actionLabels:retry),
    FlareTransferQueueItem(id:'b',name:'操作中.pdf',state:FlareTransferState.failed,statusText:'正在重试',actionLabels:retry,busy:true),
    FlareTransferQueueItem(id:'c',name:'取消.pdf',state:FlareTransferState.cancelled,statusText:'已取消',actionLabels:retry),
    FlareTransferQueueItem(id:'d',name:'完成.pdf',state:FlareTransferState.completed,statusText:'已完成',actionLabels:retry),
    FlareTransferQueueItem(id:'e',name:'无权限.pdf',state:FlareTransferState.failed,statusText:'无权限',actionLabels:{FlareTransferAction.retry:' '}),
  ];
  test('batch targets failures with available capability only',(){expect(retryableTransferIds(items),['a']); expect(retryableTransferIds([]),isEmpty);});
  testWidgets('large text, cached queue on error and individual/batch recovery', (tester) async {
    tester.view.physicalSize=const Size(320,1800); tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    var batches=<List<String>>[]; var actions=<String>[];
    await tester.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(textScaler:TextScaler.linear(2)),child:Scaffold(body:FlareTransferQueue(items:items,error:'队列刷新失败，已有任务保留',onRetryFailed:batches.add,onAction:(id,a)=>actions.add(id))))));
    await tester.tap(find.text('重试失败任务 (1)')); await tester.pump(); expect(batches,[['a']]);
    await tester.tap(find.text('重试').first); await tester.pump(); expect(actions,['a']);
    expect(find.text('队列刷新失败，已有任务保留'),findsOneWidget);
    expect(find.text('失败文件.pdf'),findsOneWidget); expect(tester.takeException(),isNull);
  });
}
