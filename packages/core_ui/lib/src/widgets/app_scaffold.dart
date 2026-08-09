import 'package:flutter/material.dart';

/// A wrapper around Flutter's [Scaffold] that provides a consistent structure
/// for all screens in the RMS application.
///
/// Accepts an optional [appBar] and an optional [navigationWidget] (e.g. a
/// [NavigationRail] or [BottomNavigationBar]) that is rendered to the side of
/// / below [body] depending on screen size.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.navigationWidget,
  });

  /// The primary content of the screen.
  final Widget body;

  /// Optional app-bar rendered at the top of the scaffold.
  final PreferredSizeWidget? appBar;

  /// Optional navigation widget (e.g. [NavigationRail], [BottomNavigationBar])
  /// rendered alongside [body].  When provided the layout switches to a [Row]
  /// so that side-navigation sits to the left and the body fills the remainder.
  final Widget? navigationWidget;

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (navigationWidget != null) {
      content = Row(
        children: [
          navigationWidget!,
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      body: content,
    );
  }
}
