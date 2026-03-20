class SimpleResult<S, F> {
  const SimpleResult._({
    this.successData,
    this.failureData,
    required this.isSuccess,
  });

  final S? successData;
  final F? failureData;
  final bool isSuccess;

  bool get isFailure => !isSuccess;

  static SimpleResult<S, F> success<S, F>(S data) {
    return SimpleResult<S, F>._(successData: data, isSuccess: true);
  }

  static SimpleResult<S, F> failure<S, F>(F data) {
    return SimpleResult<S, F>._(failureData: data, isSuccess: false);
  }
}
