class LiveRoomJoin {
  final String roomId;
  final String code;
  final String token;
  final String role;
  final String deviceId;
  final bool guestAuth;

  const LiveRoomJoin({
    required this.roomId,
    required this.code,
    required this.token,
    required this.role,
    required this.deviceId,
    required this.guestAuth,
  });

  bool get isHost => role == 'host';
  bool get isRed => role == 'red';
  bool get isDisplay => role == 'display';
  bool get isViewer => role == 'viewer';
}
