import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.loading,
    this.errorBuilder,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) dataBuilder;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: dataBuilder,
      loading:
          loading ?? () => const Center(child: CircularProgressIndicator()),
      error:
          errorBuilder ??
          (error, _) => Center(child: Text('데이터를 불러오지 못했습니다.\n$error')),
    );
  }
}
