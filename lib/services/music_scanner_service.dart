import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';
import 'database_service.dart';

enum ScanPermissionResult { granted, denied, permanentlyDenied }

class ScanResult {
  final int totalFound;
  final int newlyAdded;
  ScanResult({required this.totalFound, required this.newlyAdded});
}

/// Wraps on_audio_query (Android MediaStore access) + the permission
/// request flow, and hands parsed songs off to [DatabaseService] to persist.
/// No audio bytes are ever read or copied here — only metadata.
class MusicScannerService {
  MusicScannerService._internal();
  static final MusicScannerService instance = MusicScannerService._internal();

  final oaq.OnAudioQuery _audioQuery = oaq.OnAudioQuery();

  /// Requests READ_MEDIA_AUDIO (Android 13+) / READ_EXTERNAL_STORAGE
  /// (Android <13) — on_audio_query's own permission call picks the right
  /// one for the running OS version.
  Future<ScanPermissionResult> requestPermission() async {
    final granted = await _audioQuery.permissionsRequest();
    if (granted) return ScanPermissionResult.granted;

    final status = await Permission.audio.status;
    if (status.isPermanentlyDenied) return ScanPermissionResult.permanentlyDenied;
    return ScanPermissionResult.denied;
  }

  Future<bool> hasPermission() => _audioQuery.permissionsStatus();

  /// Queries every audio file the OS exposes, converts each to our [Song]
  /// model, then upserts into SQLite (see DatabaseService.upsertScannedSongs
  /// for why existing play counts/favorites are preserved on rescan).
  ///
  /// Filters out files under ~2 seconds — these are almost always
  /// notification/ringtone assets rather than real songs, not user music.
  Future<ScanResult> scanLibrary() async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw StateError('Audio permission not granted — call requestPermission() first.');
    }

    final List<oaq.SongModel> rawSongs = await _audioQuery.querySongs(
      sortType: oaq.SongSortType.DATE_ADDED,
      orderType: oaq.OrderType.DESC_OR_GREATER,
      uriType: oaq.UriType.EXTERNAL,
      ignoreCase: true,
    );

    final songs = rawSongs
        .where((s) => (s.duration ?? 0) > 2000)
        .map(Song.fromAudioModel)
        .toList();

    final inserted = await DatabaseService.instance.upsertScannedSongs(songs);

    return ScanResult(totalFound: songs.length, newlyAdded: inserted);
  }
}
