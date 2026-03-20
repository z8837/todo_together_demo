part of 'schedule_fragment.dart';

class _ScheduleErrorState extends StatelessWidget {
  const _ScheduleErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          AppGap.h12,
          Padding(
            padding: AppInsets.h24,
            child: Text(message, textAlign: TextAlign.center),
          ),
          AppGap.h12,
          FilledButton(onPressed: onRetry, child: Text('다시 시도'.tr())),
        ],
      ),
    );
  }
}
