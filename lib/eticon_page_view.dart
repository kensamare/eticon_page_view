library eticon_page_view;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/gestures.dart';

class CustomPageView extends StatefulWidget {

  final bool allowImplicitScrolling;

  final String? restorationId;
  final Axis scrollDirection;

  final bool reverse;
  final bool pageCenter;

  final PageController? controller;
  final ScrollPhysics? physics;

  final bool pageSnapping;
  final ValueChanged<int>? onPageChanged;

  final SliverChildDelegate childrenDelegate;

  final DragStartBehavior dragStartBehavior;

  CustomPageView({
    Key? key,
    required List<Widget> children,
    PageController? controller,
    this.pageCenter = false,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    this.restorationId,
  })  : controller = controller ?? _defaultPageController,
        childrenDelegate = SliverChildListDelegate(children),
        super(key: key);

  CustomPageView.builder({
    Key? key,
    required int itemCount,
    this.pageCenter = false,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    PageController? controller,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    this.restorationId,
  })  : controller = controller ?? _defaultPageController,
        childrenDelegate =
        SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
        super(key: key);

  @override
  _CustomPageViewState createState() => _CustomPageViewState();
}

class _CustomPageViewState extends State<CustomPageView> {
  int _lastPage = 0;

  @override
  void initState() {
    super.initState();
    _lastPage = widget.controller!.initialPage;
  }

  AxisDirection? _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection =
        textDirectionToAxisDirection(textDirection);
        return widget.reverse
            ? flipAxisDirection(axisDirection)
            : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection? axisDirection = _getDirection(context);
    final ScrollPhysics physics = _ForceImplicitScrollPhysics(
      allowImplicitScrolling: widget.allowImplicitScrolling,
    ).applyTo(widget.pageSnapping
        ? _kPagePhysics.applyTo(widget.physics)
        : widget.physics ?? _kPagePhysics);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 &&
            widget.onPageChanged != null &&
            notification is ScrollUpdateNotification) {
          final PageMetrics metrics = notification.metrics as PageMetrics;
          final int currentPage = metrics.page!.round();
          if (currentPage != _lastPage) {
            _lastPage = currentPage;
            widget.onPageChanged!(currentPage);
          }
        }
        return false;
      },
      child: Scrollable(
        dragStartBehavior: widget.dragStartBehavior,
        axisDirection: axisDirection ?? AxisDirection.down,
        controller: widget.controller,
        physics: physics,
        restorationId: widget.restorationId,
        viewportBuilder: (BuildContext context, ViewportOffset position) {
          return Viewport(
            cacheExtent: widget.allowImplicitScrolling ? 1.0 : 0.0,
            cacheExtentStyle: CacheExtentStyle.viewport,
            axisDirection: axisDirection ?? AxisDirection.down,
            offset: position,
            slivers: [
              SliverFillViewport(
                viewportFraction: widget.controller!.viewportFraction,
                delegate: widget.childrenDelegate,
                padEnds: widget.pageCenter,
              ),
            ],
          );
        },
      ),
    );
  }
}

final PageController _defaultPageController = PageController();
const PageScrollPhysics _kPagePhysics = PageScrollPhysics();

class _ForceImplicitScrollPhysics extends ScrollPhysics {
  const _ForceImplicitScrollPhysics({
    required this.allowImplicitScrolling,
    ScrollPhysics? parent,
  })  : assert(allowImplicitScrolling != null),
        super(parent: parent);

  @override
  _ForceImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForceImplicitScrollPhysics(
      allowImplicitScrolling: allowImplicitScrolling,
      parent: buildParent(ancestor),
    );
  }

  @override
  final bool allowImplicitScrolling;
}