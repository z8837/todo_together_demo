import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NativeAdPlacement { projectList }

class NativeAdCache {
  const NativeAdCache();

  void prefetchNext(NativeAdPlacement placement) {}

  void swapInPrefetched(NativeAdPlacement placement) {}
}

final nativeAdCacheProvider = Provider<NativeAdCache>((ref) {
  return const NativeAdCache();
});
