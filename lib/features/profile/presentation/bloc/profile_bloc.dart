import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc(this.repository) : super(ProfileLoading()) {

    // Mengambil data profil
    on<LoadProfile>((event, emit) {
      final user = repository.getCurrentUser();
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(const ProfileError("User tidak ditemukan"));
      }
    });

    // Menyimpan alamat baru
    on<UpdateAddress>((event, emit) async {
      emit(ProfileLoading());
      try {
        await repository.updateAddress(event.newAddress);
        emit(const ProfileActionSuccess("✅ Alamat berhasil diperbarui!"));
        // Muat ulang data profil setelah sukses
        add(LoadProfile());
      } catch (e) {
        emit(ProfileError("❌ Gagal menyimpan alamat: $e"));
        add(LoadProfile()); // Kembalikan ke tampilan profil
      }
    });

    // Mengunggah foto profil
    on<UploadAvatar>((event, emit) async {
      emit(ProfileLoading());
      try {
        await repository.uploadProfilePicture(event.userId, event.fileExt, event.bytes);
        emit(const ProfileActionSuccess("✅ Foto profil berhasil diperbarui!"));
        add(LoadProfile());
      } catch (e) {
        emit(ProfileError("❌ Gagal mengunggah foto: $e"));
        add(LoadProfile());
      }
    });
  }
}