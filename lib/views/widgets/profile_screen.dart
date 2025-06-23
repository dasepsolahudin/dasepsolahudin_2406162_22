// lib/views/widgets/profile_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui'; // Untuk ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/profile_controller.dart';
import '../utils/helper.dart' as helper;
import '../../routes/route_name.dart';

// Kelas helper untuk menjaga konsistensi nama kolom
class _DbColumnNames {
  static const columnId = '_id';
  static const columnUsername = 'username';
  static const columnEmail = 'email';
  static const columnPhoneNumber = 'phone_number';
  static const columnAddress = 'address';
  static const columnCity = 'city';
  static const columnProfilePicturePath = 'profile_picture_path';
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- WIDGET HELPER UNTUK MENAMPILKAN GAMBAR (Tidak berubah) ---
  Widget _buildProfileImage(String? path, {double? width, double? height}) {
    if (path == null || path.isEmpty) {
      return Icon(
        Icons.person_rounded,
        size: 60,
        color: helper.cWhite.withOpacity(0.8),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person_rounded,
          size: 60,
          color: helper.cWhite.withOpacity(0.8),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );
    } else {
      final imageFile = File(path);
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } else {
        return Icon(
          Icons.person_rounded,
          size: 60,
          color: helper.cWhite.withOpacity(0.8),
        );
      }
    }
  }

  // --- WIDGET HELPER BARU UNTUK ITEM STATISTIK ---
  Widget _buildStatItem(BuildContext context, String count, String label) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        helper.vsSuperTiny,
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  // --- WIDGET HELPER BARU UNTUK JUDUL SEKSI ---
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }

  // --- WIDGET HELPER BARU UNTUK ITEM DAFTAR AKSI ---
  Widget _buildProfileListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? customColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final color = customColor ?? theme.textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(color: color),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: theme.hintColor.withOpacity(0.7),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => ProfileController(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<ProfileController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.userData == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    controller.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (controller.userData == null) {
              return Center(
                child: Text(
                  "Tidak dapat memuat data profil.",
                  style: theme.textTheme.titleMedium,
                ),
              );
            }

            final userData = controller.userData!;
            String displayName =
                userData[_DbColumnNames.columnUsername] as String? ??
                'Nama Pengguna';
            String displayEmail =
                userData[_DbColumnNames.columnEmail] as String? ??
                'email@example.com';
            String? profilePicPath =
                userData[_DbColumnNames.columnProfilePicturePath] as String?;

            return RefreshIndicator(
              onRefresh: () => controller.refreshProfile(),
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  // --- HEADER DENGAN EFEK YANG DISEMPURNAKAN ---
                  SliverAppBar(
                    expandedHeight: 250.0,
                    pinned: true,
                    stretch: true,
                    backgroundColor: theme.appBarTheme.backgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 5.0,
                              sigmaY: 5.0,
                            ),
                            child: _buildProfileImage(
                              profilePicPath,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.5),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 48,
                                    child: ClipOval(
                                      child: _buildProfileImage(profilePicPath),
                                    ),
                                  ),
                                ),
                                helper.vsMedium,
                                Text(
                                  displayName,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                helper.vsSuperTiny,
                                Text(
                                  displayEmail,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- KONTEN BODY DENGAN TATA LETAK BARU ---
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SEKSI STATISTIK ---
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(context, '120', 'Artikel'),
                              _buildStatItem(context, '25', 'Bookmark'),
                              _buildStatItem(context, '1.2K', 'Suka'),
                            ],
                          ),
                        ),

                        // --- SEKSI AKUN ---
                        _buildSectionHeader(context, "AKUN"),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildProfileListItem(
                                context: context,
                                icon: Icons.edit_outlined,
                                title: "Edit Profil",
                                onTap: () async {
                                  final String? userId = controller
                                      .userData?[_DbColumnNames.columnId];
                                  if (userId != null) {
                                    final bool? profileWasUpdated =
                                        await context.pushNamed<bool>(
                                          RouteName.editProfile,
                                          extra: userId,
                                        );
                                    if (profileWasUpdated == true && mounted) {
                                      controller.refreshProfile();
                                    }
                                  }
                                },
                              ),
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              _buildProfileListItem(
                                context: context,
                                icon: Icons.lock_outline_rounded,
                                title: "Ganti Password",
                                onTap: () {
                                  context.pushNamed(RouteName.changePassword);
                                },
                              ),
                            ],
                          ),
                        ),

                        // --- SEKSI APLIKASI ---
                        _buildSectionHeader(context, "APLIKASI"),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildProfileListItem(
                                context: context,
                                icon: Icons.settings_outlined,
                                title: "Pengaturan",
                                onTap: () =>
                                    context.pushNamed(RouteName.settings),
                              ),
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              _buildProfileListItem(
                                context: context,
                                icon: Icons.logout_rounded,
                                title: "Logout",
                                customColor: theme.colorScheme.error,
                                onTap: () => controller.logout(context),
                              ),
                            ],
                          ),
                        ),
                        // PERUBAHAN UTAMA: Menambahkan ruang kosong di bagian bawah
                        // untuk memberi tempat bagi bilah navigasi apung.
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
