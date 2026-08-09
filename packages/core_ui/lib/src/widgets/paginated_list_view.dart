import 'package:flutter/material.dart';

/// A generic scrollable list that fires [onEndReached] when the user scrolls
/// near the bottom (within [endReachedThreshold] pixels of the end).
///
/// When [isLoading] is `true` a [CircularProgressIndicator] is appended after
/// the last item to indicate that more data is being fetched.
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    required this.items,
    required this.itemBuilder,
    super.key,
    this.onEndReached,
    this.isLoading = false,
    this.endReachedThreshold = 200.0,
  });

  /// The list of items to display.
  final List<T> items;

  /// Builder for each item in [items].
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Callback fired when the user scrolls within [endReachedThreshold] pixels
  /// of the bottom of the list.
  final VoidCallback? onEndReached;

  /// When `true` a loading indicator is shown at the bottom of the list.
  final bool isLoading;

  /// Distance from the bottom of the list (in logical pixels) at which
  /// [onEndReached] is triggered.  Defaults to 200 dp.
  final double endReachedThreshold;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onEndReached == null) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - widget.endReachedThreshold) {
      widget.onEndReached!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length + (widget.isLoading ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (ctx, index) {
        if (index == widget.items.length) {
          // Loading indicator at the bottom.
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(ctx, widget.items[index]);
      },
    );
  }
}
