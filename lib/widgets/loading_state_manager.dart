import 'package:flutter/material.dart';

class LoadingStateManager extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final bool maintainSize;

  const LoadingStateManager({
    super.key,
    required this.child,
    this.isLoading = false,
    this.loadingText,
    this.maintainSize = true,
  });

  @override
  State<LoadingStateManager> createState() => _LoadingStateManagerState();
}

class _LoadingStateManagerState extends State<LoadingStateManager>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (!widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingStateManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
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
      builder: (context, child) {
        return Stack(
          children: [
            // Main content with fade
            Opacity(
              opacity: _animation.value,
              child: widget.child,
            ),
            
            // Loading overlay
            if (widget.isLoading || _animation.value < 1.0)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        if (widget.loadingText != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.loadingText!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SmoothPageTransition extends StatefulWidget {
  final Widget child;
  final String routeKey;

  const SmoothPageTransition({
    super.key,
    required this.child,
    required this.routeKey,
  });

  @override
  State<SmoothPageTransition> createState() => _SmoothPageTransitionState();
}

class _SmoothPageTransitionState extends State<SmoothPageTransition>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late String _currentRouteKey;

  @override
  void initState() {
    super.initState();
    _currentRouteKey = widget.routeKey;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start with full opacity
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(SmoothPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeKey != widget.routeKey) {
      _currentRouteKey = widget.routeKey;
      // Quick fade transition
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}