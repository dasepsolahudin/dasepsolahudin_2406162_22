// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/home_controller.dart';
import '../../data/models/article_model.dart';
import 'news_card_widget.dart';
import '../utils/helper.dart' as helper;
import '../../routes/route_name.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return ChangeNotifierProvider(
      create: (context) => HomeController(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, theme),
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              if (_searchFocusNode.hasFocus) {
                _searchFocusNode.unfocus();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntro(context, textTheme),
                Consumer<HomeController>(
                  builder: (context, controller, child) {
                    return _buildSearchBar(context, theme, controller);
                  },
                ),
                Expanded(
                  child: Consumer<HomeController>(
                    builder: (context, controller, child) {
                      if (controller.isLoading && controller.articles.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }
                      if (controller.errorMessage != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Gagal memuat berita:\n${controller.errorMessage}',
                              style: textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      if (controller.articles.isEmpty &&
                          !controller.isLoading) {
                        String message =
                            controller.isSearchActive &&
                                controller.currentSearchQuery != null
                            ? 'Tidak ada hasil untuk "${controller.currentSearchQuery}".'
                            : 'Tidak ada berita tersedia saat ini.';
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              message,
                              style: textTheme.titleMedium?.copyWith(
                                color: textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            controller.isSearchActive &&
                                controller.currentSearchQuery != null
                            ? controller.searchArticles(
                                controller.currentSearchQuery!,
                              )
                            : controller.fetchArticles(),
                        color: theme.colorScheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: 16.0,
                            top: 8.0,
                          ),
                          itemCount: controller.articles.length,
                          itemBuilder: (context, index) {
                            final article = controller.articles[index];
                            bool isBookmarked = controller.isArticleBookmarked(
                              article.url,
                            );
                            return NewsCardWidget(
                              article: article,
                              isBookmarked: isBookmarked,
                              onBookmarkTap: () {
                                controller.toggleBookmark(article);
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isBookmarked
                                          ? "'${article.title}' dihapus dari bookmark."
                                          : "'${article.title}' ditambahkan ke bookmark.",
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Row(
        children: [
          Image.asset('assets/images/icon.png', height: 32, width: 32),
          helper.hsSmall,
          Text(
            "BeritaKu",
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.menu,
            color: theme.colorScheme.onBackground,
            size: 28,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Menu button clicked!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildIntro(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Berita Terkini",
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textTheme.bodyLarge?.color,
            ),
          ),
          helper.vsTiny,
          Text(
            "Dapatkan informasi terbaru dan terpercaya dari berbagai kategori",
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    ThemeData theme,
    HomeController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ).copyWith(bottom: 16.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: "Cari artikel...",
          hintStyle: theme.textTheme.titleSmall?.copyWith(
            color: theme.hintColor,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.hintColor,
            size: 24,
          ),
          filled: true,
          fillColor: theme.brightness == Brightness.dark
              ? Colors.black.withOpacity(0.2)
              : helper.cGrey.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: theme.hintColor,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    controller.fetchArticles();
                    _searchFocusNode.unfocus();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            controller.searchArticles(value.trim());
          } else {
            controller.fetchArticles();
          }
          _searchFocusNode.unfocus();
        },
      ),
    );
  }
}
