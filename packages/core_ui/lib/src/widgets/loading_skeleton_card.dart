import 'package:flutter/material.dart';

/// An animated shimmer placeholder card used as a loading skeleton.
///
/// The shimmer effect is produced by an [AnimationController] that drives a
/// gradient sweep from left to right.  [height] and [width] default to 80 and
/// double.infinity respectively.
class LoadingSkeletonCard extends StatefulWidget {
  const LoadingSkeletonCard({
    super.key,
    this.height,
    this.width,
  });

  /// Optional explicit height of the card.  Defaults to 80 dp.
  final double? height;

  /// Optional explicit width of the card.  Defaults to [double.infinity].
  final double? width;

  @override
  State<LoadingSkeletonCard> createState() => _LoadingSkeletonCardState();
}

class _LoadingSkeletonCardState extends State<LoadingSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Card(
          elevation: 1,
          child: SizedBox(
            height: widget.height ?? 80,
            width: widget.width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment(_animation.value - 1, 0),
                  end: Alignment(_animation.value, 0),
                  colors: const [
                    Color(0xFFE0E0E0),
                    Color(0xFFF5F5F5),
                    Color(0xFFE0E0E0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
