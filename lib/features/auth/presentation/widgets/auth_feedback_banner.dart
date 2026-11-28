import 'package:material_ui/material_ui.dart';

/// Auto-dismissing inline feedback banner for auth and profile messages.
///
/// Renders either an informational notice or an error notice with a manual
/// dismiss button and smooth size transition when cleared automatically.
class AuthFeedbackBanner extends StatelessWidget {
  const AuthFeedbackBanner({
    super.key,
    this.infoMessage,
    this.errorMessage,
    this.infoKey,
    this.errorKey,
    this.onDismiss,
  });

  final String? infoMessage;
  final String? errorMessage;
  final Key? infoKey;
  final Key? errorKey;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = errorMessage != null;
    final message = errorMessage ?? infoMessage;

    if (message == null) {
      return const SizedBox.shrink();
    }

    final Color bgColor = isError
        ? theme.colorScheme.errorContainer.withAlpha(180)
        : theme.colorScheme.tertiary.withAlpha(26);
    final Color borderColor = isError
        ? theme.colorScheme.error.withAlpha(110)
        : theme.colorScheme.tertiary.withAlpha(90);
    final Color fgColor = isError
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;

    return Container(
      key: isError ? errorKey : infoKey,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: fgColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: fgColor),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.close_rounded, size: 16, color: fgColor),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
