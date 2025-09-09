enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  updated,
  error,
}

class ProfileStateModel {
  final ProfileStatus status;
  final String? errorMessage;
  final String? successMessage;
  final bool isProfileUpdating;
  final bool isLoggingOut;

  ProfileStateModel({
    this.status = ProfileStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.isProfileUpdating = false,
    this.isLoggingOut = false,
  });

  /// Factory constructors for common states
  factory ProfileStateModel.initial() {
    return ProfileStateModel(status: ProfileStatus.initial);
  }

  factory ProfileStateModel.loading() {
    return ProfileStateModel(status: ProfileStatus.loading);
  }

  factory ProfileStateModel.loaded({String? successMessage}) {
    return ProfileStateModel(
      status: ProfileStatus.loaded,
      successMessage: successMessage,
    );
  }

  factory ProfileStateModel.updating({
    bool isProfileUpdating = false,
  }) {
    return ProfileStateModel(
      status: ProfileStatus.updating,
      isProfileUpdating: isProfileUpdating,
    );
  }

  factory ProfileStateModel.updated({String? successMessage}) {
    return ProfileStateModel(
      status: ProfileStatus.updated,
      successMessage: successMessage,
    );
  }

  factory ProfileStateModel.error(String errorMessage) {
    return ProfileStateModel(
      status: ProfileStatus.error,
      errorMessage: errorMessage,
    );
  }

  factory ProfileStateModel.loggingOut() {
    return ProfileStateModel(
      status: ProfileStatus.loading,
      isLoggingOut: true,
    );
  }

  /// Check if the current state is loading
  bool get isLoading => status == ProfileStatus.loading;

  /// Check if the profile is loaded
  bool get isLoaded => status == ProfileStatus.loaded;

  /// Check if updating
  bool get isUpdating => status == ProfileStatus.updating;

  /// Check if there's an error
  bool get hasError => status == ProfileStatus.error;

  /// Check if any operation is in progress
  bool get isBusy => isLoading || isUpdating || isProfileUpdating || isLoggingOut;

  /// Copy with new values
  ProfileStateModel copyWith({
    ProfileStatus? status,
    String? errorMessage,
    String? successMessage,
    bool? isProfileUpdating,
    bool? isLoggingOut,
  }) {
    return ProfileStateModel(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isProfileUpdating: isProfileUpdating ?? this.isProfileUpdating,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  String toString() {
    return 'ProfileStateModel{status: $status, errorMessage: $errorMessage, successMessage: $successMessage, isProfileUpdating: $isProfileUpdating, isLoggingOut: $isLoggingOut}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileStateModel &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.successMessage == successMessage &&
        other.isProfileUpdating == isProfileUpdating &&
        other.isLoggingOut == isLoggingOut;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        errorMessage.hashCode ^
        successMessage.hashCode ^
        isProfileUpdating.hashCode ^
        isLoggingOut.hashCode;
  }
}
