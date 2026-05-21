import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';

// 1. CARA BARU (MODERN): Notifier untuk menyimpan ID Proyek yang sedang dibuka
class SelectedProjectIdNotifier extends Notifier<String?> {
  @override
  String? build() => null; // Nilai awal saat aplikasi dibuka adalah null

  // Fungsi kustom untuk mengubah ID proyek yang sedang aktif
  void setProjectId(String? id) {
    state = id;
  }
}

// 2. Provider Global Modern
final selectedProjectIdProvider = NotifierProvider<SelectedProjectIdNotifier, String?>(
  SelectedProjectIdNotifier.new,
);

// Enum untuk menandai peran di dalam proyek
enum CurrentWorkspaceRole { manager, member }

// 🚀 3. Engine utama pembaca peran dinamis (Tetap sama, tidak perlu diubah)
final currentRoleEngineProvider = FutureProvider<CurrentWorkspaceRole?>((ref) async {
  // ref.watch di sini tetap bekerja secara ajaib meskipun provider di atas sudah berubah tipe
  final projectId = ref.watch(selectedProjectIdProvider);
  final supabase = ref.read(supabaseClientProvider);
  final currentUser = supabase.auth.currentUser;

  if (projectId == null || currentUser == null) return null;

  // Query ke database: Ambil data proyek untuk melihat siapa 'pembuat_id' (manajer) nya
  final projectData = await supabase
      .from('projects')
      .select('pembuat_id')
      .eq('id', projectId)
      .single();

  // JIKA id user saat ini sama dengan id pembuat proyek -> Dia bertindak sebagai MANAJER
  if (projectData['pembuat_id'] == currentUser.id) {
    return CurrentWorkspaceRole.manager;
  } else {
    // JIKA berbeda -> Dia bertindak sebagai MEMBER biasa
    return CurrentWorkspaceRole.member;
  }
});