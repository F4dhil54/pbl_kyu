import 'package:flutter_riverpod/legacy.dart';

/// Provider to track current navigation index (0: Beranda, 1: Kotak Masuk, 2: Kolaborasi, 3: Proyek)
final navigationIndexProvider = StateProvider<int>((ref) => 0);
