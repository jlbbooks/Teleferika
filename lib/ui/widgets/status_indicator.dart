import 'dart:async';

import 'package:flutter/material.dart';

enum StatusType { success, error, info, loading }

class StatusInfo {
  final StatusType type;
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;

  StatusInfo({
    required this.type,
    required this.message,
    required this.icon,
    required this.color,
    this.duration = const Duration(seconds: 3),
  });
}

class StatusManager {
  static StatusInfo success(String message) => StatusInfo(
    type: StatusType.success,
    message: message,
    icon: Icons.check_circle,
    color: Colors.green,
  );

  static StatusInfo error(String message) => StatusInfo(
    type: StatusType.error,
    message: message,
    icon: Icons.error,
    color: Colors.red,
  );

  static StatusInfo info(String message) => StatusInfo(
    type: StatusType.info,
    message: message,
    icon: Icons.info,
    color: Colors.blue,
  );

  static StatusInfo loading(String message) => StatusInfo(
    type: StatusType.loading,
    message: message,
    icon: Icons.hourglass_empty,
    color: Colors.orange,
    duration: const Duration(seconds: 0), // No auto-hide for loading
  );
}

class StatusIndicator extends StatefulWidget {
  final StatusInfo? status;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  final double? maxWidth;
  final bool autoHide;

  const StatusIndicator({
    super.key,
    this.status,
    this.onDismiss,
    this.margin,
    this.maxWidth = 320,
    this.autoHide = true,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  late final ValueNotifier<bool> _visible = ValueNotifier(false);
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _visible.value = false;
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.status != oldWidget.status) {
      if (widget.status != null) {
        _showStatus();
      } else {
        _hideStatus();
      }
    }
  }

  void _showStatus() {
    _visible.value = true;

    // Clear any existing timer
    _hideTimer?.cancel();

    // Set up auto-hide timer (except for loading status or if autoHide is false)
    if (widget.autoHide &&
        widget.status?.type != StatusType.loading &&
        widget.status?.duration.inSeconds != 0) {
      _hideTimer = Timer(widget.status!.duration, () {
        if (mounted) {
          _hideStatus();
        }
      });
    }
  }

  void _hideStatus() {
    _hideTimer?.cancel();
    if (mounted) {
      _visible.value = false;
    }
  }

  void _handleDismiss() {
    widget.onDismiss?.call();
    _hideStatus();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _visible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _visible,
      builder: (context, visible, child) {
        return AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0.2, 0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible && widget.status != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: widget.status == null
                ? const SizedBox.shrink()
                : Container(
                    margin: widget.margin,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: widget.status!.color.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: widget.maxWidth ?? 320,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.status!.type == StatusType.loading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                widget.status!.icon,
                                color: Colors.white,
                                size: 18,
                              ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Tooltip(
                                message: widget.status!.message,
                                child: Text(
                                  widget.status!.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (widget.status!.type != StatusType.loading)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: _handleDismiss,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// Mixin for easy status management in StatefulWidgets
mixin StatusMixin<T extends StatefulWidget> on State<T> {
  StatusInfo? _currentStatus;
  Timer? _statusTimer;

  void showStatus(StatusInfo status) {
    setState(() {
      _currentStatus = status;
    });

    // Clear any existing timer
    _statusTimer?.cancel();

    // Set up auto-hide timer (except for loading status)
    if (status.type != StatusType.loading && status.duration.inSeconds > 0) {
      _statusTimer = Timer(status.duration, () {
        if (mounted) {
          setState(() {
            _currentStatus = null;
          });
        }
      });
    }
  }

  void hideStatus() {
    _statusTimer?.cancel();
    if (mounted) {
      setState(() {
        _currentStatus = null;
      });
    }
  }

  void showSuccessStatus(String message) {
    showStatus(StatusManager.success(message));
  }

  void showErrorStatus(String message) {
    showStatus(StatusManager.error(message));
  }

  void showInfoStatus(String message) {
    showStatus(StatusManager.info(message));
  }

  void showLoadingStatus(String message) {
    showStatus(StatusManager.loading(message));
  }

  StatusInfo? get currentStatus => _currentStatus;

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}
