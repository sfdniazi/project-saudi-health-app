enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthStateModel {
  final AuthStatus status;
  final String? errorMessage;
  final String? successMessage;

  AuthStateModel({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  /// Factory constructors for common states
  factory AuthStateModel.initial() {
    return AuthStateModel(status: AuthStatus.initial);
  }

  factory AuthStateModel.loading() {
    return AuthStateModel(status: AuthStatus.loading);
  }

  factory AuthStateModel.authenticated({String? successMessage}) {
    return AuthStateModel(
      status: AuthStatus.authenticated,
      successMessage: successMessage,
    );
  }

  factory AuthStateModel.unauthenticated() {
    return AuthStateModel(status: AuthStatus.unauthenticated);
  }

  factory AuthStateModel.error(String errorMessage) {
    return AuthStateModel(
      status: AuthStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Check if the current state is loading
  bool get isLoading => status == AuthStatus.loading;

  /// Check if the user is authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Check if there's an error
  bool get hasError => status == AuthStatus.error;

  /// Check if the user is unauthenticated
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Copy with new values
  AuthStateModel copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthStateModel(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  String toString() {
    return 'AuthStateModel{status: $status, errorMessage: $errorMessage, successMessage: $successMessage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthStateModel &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.successMessage == successMessage;
  }

  @override
  int get hashCode {
    return status.hashCode ^ errorMessage.hashCode ^ successMessage.hashCode;
  }
}
