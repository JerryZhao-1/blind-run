class ApiFailure implements Exception {
  const ApiFailure({
    required this.message,
    this.httpStatus,
    this.businessCode,
    this.rawBody = '',
  });

  final String message;
  final int? httpStatus;
  final int? businessCode;
  final String rawBody;

  bool get isUnauthorized => httpStatus == 401;

  @override
  String toString() {
    return 'ApiFailure(httpStatus: $httpStatus, businessCode: $businessCode, message: $message)';
  }
}
