import 'package:flutter/material.dart';

class RoutePreloader extends StatefulWidget {
  final List<Widget> preloadWidgets;
  final Widget child;

  const RoutePreloader({
    super.key,
    required this.preloadWidgets,
    required this.child,
  });

  @override
  State<RoutePreloader> createState() => _RoutePreloaderState();
}

class _RoutePreloaderState extends State<RoutePreloader> {
  final List<Widget> _preloadedWidgets = [];
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _startPreloading();
  }

  void _startPreloading() async {
    if (_isPreloading) return;
    
    setState(() {
      _isPreloading = true;
    });

    // Preload widgets in background
    await Future.delayed(const Duration(milliseconds: 100));
    
    for (final widget in widget.preloadWidgets) {
      if (!mounted) break;
      
      try {
        // Create the widget to trigger any initialization
        _preloadedWidgets.add(widget);
        
        // Small delay to prevent blocking UI
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        // Ignore preload errors
        print('Preload error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isPreloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Hidden preloaded widgets
        if (_isPreloading)
          Positioned(
            left: -1000,
            top: -1000,
            child: SizedBox(
              width: 1,
              height: 1,
              child: Column(
                children: _preloadedWidgets,
              ),
            ),
          ),
      ],
    );
  }
}

class PerformanceOptimizer extends StatelessWidget {
  final Widget child;
  final bool enableCache;
  final bool enablePreload;

  const PerformanceOptimizer({
    super.key,
    required this.child,
    this.enableCache = true,
    this.enablePreload = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget optimizedChild = child;

    if (enableCache) {
      optimizedChild = RepaintBoundary(
        child: optimizedChild,
      );
    }

    return optimizedChild;
  }
}

// Global performance settings
class AppPerformanceSettings {
  static bool enableTransitions = true;
  static bool enableAnimations = true;
  static bool enablePreloading = true;
  static Duration transitionDuration = const Duration(milliseconds: 200);
  
  static void setLowPerformanceMode() {
    enableTransitions = false;
    enableAnimations = false;
    enablePreloading = false;
    transitionDuration = Duration.zero;
  }
  
  static void setHighPerformanceMode() {
    enableTransitions = true;
    enableAnimations = true;
    enablePreloading = true;
    transitionDuration = const Duration(milliseconds: 200);
  }
}