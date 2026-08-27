import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/live_room.dart';

class LiveRingService {
  final FirebaseAuth auth;
  final FirebaseDatabase db;

  static const databaseUrl =
      'https://flyball-ring-lights-default-rtdb.europe-west1.firebasedatabase.app';

  LiveRingService({
    FirebaseAuth? auth,
    FirebaseDatabase? db,
  })  : auth = auth ?? FirebaseAuth.instance,
        db = db ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: databaseUrl,
            );

  static const roomLifetime = Duration(hours: 3);

  static const _tokens = [
    'ANCHOR',
    'CANNONBALLS',
    'SKULL',
    'PARROT',
    'COMPASS',
    'BLACK FLAG',
    'LANTERN',
    'CUTLASS',
    'SHIP WHEEL',
    'TREASURE CHEST',
  ];

  final _random = Random.secure();

  String newDeviceId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _random.nextInt(1 << 30).toRadixString(36);
    return '${stamp}_$rand';
  }

  Future<User> _ensureAuth() async {
    final current = auth.currentUser;
    if (current != null) return current;

    final cred = await auth.signInAnonymously();
    return cred.user!;
  }

  Future<int> serverOffsetMs() async {
    final event = await db
        .ref('.info/serverTimeOffset')
        .once()
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException(
            'Realtime Database clock check timed out. Check internet access.',
          ),
        );
    final value = event.snapshot.value;
    return value is num ? value.toInt() : 0;
  }

  Stream<bool> connectedStream() {
    return db.ref('.info/connected').onValue.map(
          (event) => event.snapshot.value == true,
        );
  }

  Future<LiveRoomJoin> createRoom({
    required String displayName,
  }) async {
    final user = await _ensureAuth();
    final guestAuth = user.isAnonymous;
    final deviceId = newDeviceId();
    final token = _tokens[_random.nextInt(_tokens.length)];
    final code = await _uniqueCode();
    final roomRef = db.ref('rooms').push();
    final roomId = roomRef.key!;

    final offset = await serverOffsetMs();
    final now = DateTime.now().millisecondsSinceEpoch + offset;
    final expiresAt = now + roomLifetime.inMilliseconds;

    await roomRef.child('meta').set({
      'hostUid': user.uid,
      'code': code,
      'token': token,
      'createdAt': ServerValue.timestamp,
      'expiresAt': expiresAt,
      'ended': false,
    }).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Creating room details timed out.',
      ),
    );

    await roomRef.child('state').set({
      'status': 'ready',
      'zeroAt': 0,
      'stoppedAt': 0,
      'generation': 0,
      'blueFaults': {
        '1': false,
        '2': false,
        '3': false,
        '4': false,
      },
      'redFaults': {
        '1': false,
        '2': false,
        '3': false,
        '4': false,
      },
    }).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Creating initial ring state timed out.',
      ),
    );

    await db.ref('roomCodes/$code').set({
      'roomId': roomId,
      'ownerUid': user.uid,
      'expiresAt': expiresAt,
      'token': token,
    }).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Creating room code timed out.',
      ),
    );

    final hostRef = roomRef.child('roles/host');
    await hostRef.onDisconnect().update({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
    await hostRef.set({
      'uid': user.uid,
      'deviceId': deviceId,
      'name': displayName.trim().isEmpty ? 'Blue Host' : displayName.trim(),
      'online': true,
      'lastSeen': ServerValue.timestamp,
    }).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Registering Blue Host timed out.',
      ),
    );

    return LiveRoomJoin(
      roomId: roomId,
      code: code,
      token: token,
      role: 'host',
      deviceId: deviceId,
      guestAuth: guestAuth,
    );
  }

  Future<LiveRoomJoin> joinRoom({
    required String code,
    required String role,
    required String displayName,
  }) async {
    if (!['red', 'display', 'viewer'].contains(role)) {
      throw StateError('Invalid live-ring role.');
    }

    final user = await _ensureAuth();
    final guestAuth = user.isAnonymous;
    final deviceId = newDeviceId();
    final cleanCode = code.replaceAll(RegExp(r'\D'), '');

    if (cleanCode.length != 6) {
      throw StateError('Enter the 6-digit room code.');
    }

    final codeEvent = await db.ref('roomCodes/$cleanCode').once();
    final raw = codeEvent.snapshot.value;
    if (raw is! Map) {
      throw StateError('That room code was not found.');
    }

    final codeData = Map<String, dynamic>.from(raw);
    final roomId = (codeData['roomId'] ?? '').toString();
    final token = (codeData['token'] ?? '').toString();
    final expiresAt = (codeData['expiresAt'] as num?)?.toInt() ?? 0;

    final offset = await serverOffsetMs();
    final now = DateTime.now().millisecondsSinceEpoch + offset;

    if (roomId.isEmpty || expiresAt <= now) {
      throw StateError('That ring room has expired.');
    }

    final metaEvent = await db.ref('rooms/$roomId/meta').once();
    final metaRaw = metaEvent.snapshot.value;
    if (metaRaw is! Map) {
      throw StateError('That ring room no longer exists.');
    }
    final meta = Map<String, dynamic>.from(metaRaw);
    if (meta['ended'] == true) {
      throw StateError('That ring room has ended.');
    }

    if (role == 'viewer') {
      final ref = db.ref('rooms/$roomId/roles/viewers/$deviceId');
      await ref.onDisconnect().update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
      await ref.set({
        'uid': user.uid,
        'deviceId': deviceId,
        'name': displayName.trim().isEmpty ? 'Viewer' : displayName.trim(),
        'online': true,
        'lastSeen': ServerValue.timestamp,
      });
    } else {
      final ref = db.ref('rooms/$roomId/roles/$role');

      final result = await ref.runTransaction((Object? current) {
        if (current == null) {
          return Transaction.success({
            'uid': user.uid,
            'deviceId': deviceId,
            'name': displayName.trim().isEmpty
                ? (role == 'red' ? 'Red Lane' : 'Main Display')
                : displayName.trim(),
            'online': true,
            'lastSeen': ServerValue.timestamp,
          });
        }

        if (current is Map) {
          final map = Map<String, dynamic>.from(current);
          final online = map['online'] == true;
          final sameUser = (map['uid'] ?? '').toString() == user.uid;
          if (!online || sameUser) {
            return Transaction.success({
              'uid': user.uid,
              'deviceId': deviceId,
              'name': displayName.trim().isEmpty
                  ? (role == 'red' ? 'Red Lane' : 'Main Display')
                  : displayName.trim(),
              'online': true,
              'lastSeen': ServerValue.timestamp,
            });
          }
        }

        return Transaction.abort();
      });

      if (!result.committed) {
        throw StateError(
          role == 'red'
              ? 'The Red Lane position is already occupied.'
              : 'The Main Display position is already occupied.',
        );
      }

      await ref.onDisconnect().update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    }

    return LiveRoomJoin(
      roomId: roomId,
      code: cleanCode,
      token: token,
      role: role,
      deviceId: deviceId,
      guestAuth: guestAuth,
    );
  }

  Stream<Map<String, dynamic>> roomStream(String roomId) {
    return db.ref('rooms/$roomId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <String, dynamic>{};
      return _stringMap(value);
    });
  }

  Future<void> go(String roomId) async {
    final offset = await serverOffsetMs();
    final now = DateTime.now().millisecondsSinceEpoch + offset;

    await db.ref('rooms/$roomId/state').update({
      'status': 'countdown',
      'zeroAt': now + 3000,
      'stoppedAt': 0,
      'generation': ServerValue.increment(1),
    });
  }

  Future<void> stop(String roomId) async {
    final offset = await serverOffsetMs();
    final now = DateTime.now().millisecondsSinceEpoch + offset;

    await db.ref('rooms/$roomId/state').update({
      'status': 'stopped',
      'stoppedAt': now,
    });
  }

  Future<void> reset(String roomId) async {
    await db.ref('rooms/$roomId/state').update({
      'status': 'ready',
      'zeroAt': 0,
      'stoppedAt': 0,
      'generation': ServerValue.increment(1),
      'blueFaults': {
        '1': false,
        '2': false,
        '3': false,
        '4': false,
      },
      'redFaults': {
        '1': false,
        '2': false,
        '3': false,
        '4': false,
      },
    });
  }

  Future<void> setFault({
    required String roomId,
    required String lane,
    required int dogNumber,
    required bool active,
  }) async {
    final path = lane == 'blue' ? 'blueFaults' : 'redFaults';
    final ref = db.ref('rooms/$roomId/state/$path/$dogNumber');

    await ref.set(active).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException(
        'Fault light update timed out. Check the live connection.',
      ),
    );
  }

  Future<void> toggleFault({
    required String roomId,
    required String lane,
    required int dogNumber,
  }) async {
    final path = lane == 'blue' ? 'blueFaults' : 'redFaults';
    final ref = db.ref('rooms/$roomId/state/$path/$dogNumber');

    final event = await ref.once().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException(
        'Could not read the current fault light.',
      ),
    );

    final current = event.snapshot.value == true;

    await setFault(
      roomId: roomId,
      lane: lane,
      dogNumber: dogNumber,
      active: !current,
    );
  }

  Future<void> leaveRoom(LiveRoomJoin join) async {
    final roleBase = 'rooms/${join.roomId}/roles';

    try {
      if (join.role == 'viewer') {
        await db
            .ref('$roleBase/viewers/${join.deviceId}')
            .update({
          'online': false,
          'lastSeen': ServerValue.timestamp,
        });
      } else {
        final ref = db.ref('$roleBase/${join.role}');
        final event = await ref.once();
        final raw = event.snapshot.value;
        if (raw is Map &&
            (raw['deviceId'] ?? '').toString() == join.deviceId) {
          await ref.update({
            'online': false,
            'lastSeen': ServerValue.timestamp,
          });
        }
      }
    } catch (_) {}

    if (join.guestAuth && auth.currentUser?.isAnonymous == true) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }

  Future<void> endRoom(LiveRoomJoin join) async {
    await db.ref('rooms/${join.roomId}/meta').update({
      'ended': true,
      'endedAt': ServerValue.timestamp,
    });

    await db.ref('rooms/${join.roomId}/state').update({
      'status': 'ended',
    });

    await db.ref('roomCodes/${join.code}').remove();
    await leaveRoom(join);
  }

  Future<String> _uniqueCode() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final value = 100000 + _random.nextInt(900000);
      final code = value.toString();
      final event = await db.ref('roomCodes/$code').once();

      if (!event.snapshot.exists) return code;

      final raw = event.snapshot.value;
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final expiresAt = (map['expiresAt'] as num?)?.toInt() ?? 0;
        final offset = await serverOffsetMs();
        final now = DateTime.now().millisecondsSinceEpoch + offset;
        if (expiresAt <= now) {
          await db.ref('roomCodes/$code').remove();
          return code;
        }
      }
    }

    throw StateError('Could not create a room code. Please try again.');
  }

  static Map<String, dynamic> _stringMap(Map raw) {
    final result = <String, dynamic>{};

    raw.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _stringMap(value);
      } else {
        result[key.toString()] = value;
      }
    });

    return result;
  }
}
