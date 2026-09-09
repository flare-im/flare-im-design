import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('time bounds travel with type changes and stale snapshots stay hidden', (tester) async {
    final requests = <FlareSearchCriteria>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FlareSearchPanel(
      snapshot: const FlareSearchSnapshot(criteria: FlareSearchCriteria(query: 'x', filterId: 'all'), state: FlareSearchState.success),
      filters: const {'all':'全部', 'file':'文件'},
      timeRanges: const [FlareSearchRangeOption(id:'range', label:'指定日期', fromTime:0, toTime:100), FlareSearchRangeOption(id:'bad', label:'无效', fromTime:2, toTime:1)],
      onSearch: requests.add,
    ))));
    await tester.tap(find.text('指定日期')); await tester.pump();
    expect(requests.single, const FlareSearchCriteria(query:'x',filterId:'all',fromTime:0,toTime:100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('文件')); await tester.pump();
    expect(requests.last, const FlareSearchCriteria(query:'x',filterId:'file',fromTime:0,toTime:100));
    await tester.tap(find.text('无效')); await tester.pump();
    expect(requests.length,2);
  });
}
