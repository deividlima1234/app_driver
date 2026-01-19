import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_driver/providers/auth_provider.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SessionTimeoutManager({
    super.key,
    required this.child,
    this.duration = const Duration(minutes: 10),
  });

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(widget.duration, _handleTimeout);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetTimer() {
    _cancelTimer();
    _startTimer();
  }

  void _handleTimeout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.status == AuthStatus.authenticated) {
      authProvider.logout();
      // Optional: Show snackbar or dialog before navigation happens reactively
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
