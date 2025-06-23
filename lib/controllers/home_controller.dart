// lib/controllers/home_controller.dart
import 'package:flutter/material.dart';
import '../services/news_api_service.dart';
import '../data/models/article_model.dart';
import '../services/database_helper.dart';

class HomeController with ChangeNotifier {
  final NewsApiService _newsApiService = NewsApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Article> _articles = [];
  List<Article> get articles => _articles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Set<String> _bookmarkedArticleUrls = {};

  bool _isSearchActive = false;
  bool get isSearchActive => _isSearchActive;

  String? _currentSearchQuery;
  String? get currentSearchQuery => _currentSearchQuery;

  HomeController() {
    fetchArticles();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _loadBookmarkedStatus() async {
    try {
      final bookmarks = await _dbHelper.getAllBookmarks();
      _bookmarkedArticleUrls = bookmarks
          .map((article) => article.url!)
          .where((url) => url.isNotEmpty)
          .toSet();
    } catch (e) {
      print("HomeController: Error loading bookmark statuses: $e");
    }
  }

  Future<void> fetchArticles() async {
    _isSearchActive = false;
    _currentSearchQuery = null;
    _setLoading(true);
    _setError(null);
    _articles = [];
    notifyListeners();

    try {
      print("Mencoba mengambil semua berita...");
      // Selalu mengambil semua berita tanpa filter kategori
      _articles = await _newsApiService.fetchTopHeadlines(category: null);
    } catch (e) {
      print("Gagal mengambil berita. Error: $e");
      _setError(e.toString());
    } finally {
      await _loadBookmarkedStatus();
      _setLoading(false);
    }
  }

  Future<void> searchArticles(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      fetchArticles();
      return;
    }

    _currentSearchQuery = trimmedQuery;
    _isSearchActive = true;
    _setLoading(true);
    _setError(null);
    _articles = [];

    try {
      _articles = await _newsApiService.searchNews(trimmedQuery);
      await _loadBookmarkedStatus();
    } catch (e) {
      _setError(e.toString());
      _articles = [];
    } finally {
      _setLoading(false);
    }
  }

  bool isArticleBookmarked(String? articleUrl) {
    if (articleUrl == null || articleUrl.isEmpty) return false;
    return _bookmarkedArticleUrls.contains(articleUrl);
  }

  Future<void> toggleBookmark(Article article) async {
    if (article.url == null || article.url!.isEmpty) {
      _setError("Artikel tidak memiliki URL yang valid untuk di-bookmark.");
      notifyListeners();
      return;
    }

    final bool currentlyBookmarked = isArticleBookmarked(article.url);
    bool successOperation;

    if (currentlyBookmarked) {
      _bookmarkedArticleUrls.remove(article.url!);
      successOperation = await _dbHelper.removeBookmark(article.url!);
      if (!successOperation) {
        _bookmarkedArticleUrls.add(article.url!);
        _setError("Gagal menghapus bookmark dari database.");
      }
    } else {
      _bookmarkedArticleUrls.add(article.url!);
      successOperation = await _dbHelper.addBookmark(article);
      if (!successOperation) {
        _bookmarkedArticleUrls.remove(article.url!);
        _setError("Gagal menambahkan bookmark ke database.");
      }
    }
    notifyListeners();
  }
}