enum RealtimeDispatchConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  unavailable,
}

extension RealtimeDispatchConnectionStatusX
    on RealtimeDispatchConnectionStatus {
  bool get canSendLocationUpdate =>
      this == RealtimeDispatchConnectionStatus.connected;
}
