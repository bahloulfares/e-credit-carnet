import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

typedef SyncChange = Map<String, dynamic>;

final syncQueueProvider =
    StateNotifierProvider<SyncQueueNotifier, List<SyncChange>>((ref) {
      return SyncQueueNotifier();
    });

class SyncQueueNotifier extends StateNotifier<List<SyncChange>> {
  static const _storageKey = 'pending_sync_queue_v1';
  final FlutterSecureStorage _storage;
  late final Future<void> _ready;

  SyncQueueNotifier({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(const []) {
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      final loaded = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

      // Merge with any in-memory changes that may have been queued before init completed.
      if (state.isEmpty) {
        state = loaded;
      } else {
        state = [...loaded, ...state];
      }
    } catch (_) {
      // Keep queue usable even if local persistence fails.
    }
  }

  Future<void> _persist() async {
    await _ready;
    try {
      await _storage.write(key: _storageKey, value: jsonEncode(state));
    } catch (_) {
      // Ignore persistence errors; queue still works in-memory.
    }
  }

  Future<List<SyncChange>> snapshot() async {
    await _ready;
    return List<SyncChange>.from(state);
  }

  void enqueue(SyncChange change) {
    state = [...state, change];
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}
