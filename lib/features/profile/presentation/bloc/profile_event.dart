import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateAddress extends ProfileEvent {
  final String newAddress;
  const UpdateAddress(this.newAddress);

  @override
  List<Object?> get props => [newAddress];
}

class UploadAvatar extends ProfileEvent {
  final String userId;
  final String fileExt;
  final Uint8List bytes;

  const UploadAvatar(this.userId, this.fileExt, this.bytes);

  @override
  List<Object?> get props => [userId, fileExt, bytes];
}