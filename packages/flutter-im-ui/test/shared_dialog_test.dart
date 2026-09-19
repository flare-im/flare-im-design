import 'dart:io';
import 'dart:ui' as ui;
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 1024.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'dialog remains usable with constrained height $width $brightness',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 420);
          addTearDown(tester.view.reset);
          final boundaryKey = GlobalKey();
          var submitted = false;
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundaryKey,
              child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: Scaffold(
                  body: FlareDialog(
                    title: const Text('编辑资料'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        8,
                        (i) => FlareFormField(
                          label: '资料项 $i',
                          child: const FlareInput(placeholder: '请输入内容'),
                        ),
                      ),
                    ),
                    actions: [
                      FlareButton(
                        label: '取消',
                        variant: FlareButtonVariant.secondary,
                        onPressed: () {},
                      ),
                      FlareButton(
                        label: '保存修改',
                        onPressed: () => submitted = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getRect(find.text('保存修改')).bottom, lessThan(420));
          await tester.tap(find.text('保存修改'));
          expect(submitted, isTrue);
          if (const bool.fromEnvironment('FLARE_CAPTURE_UI') &&
              width == 320 &&
              brightness == Brightness.light) {
            await tester.runAsync(() async {
              final image =
                  await (boundaryKey.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '/tmp/flare-shared-dialog-mobile.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        },
      );
    }
  }
}
