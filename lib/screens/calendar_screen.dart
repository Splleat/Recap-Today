import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add Provider import
import 'package:recap_today/provider/diary_provider.dart'; // Add DiaryProvider import
import 'package:recap_today/model/diary_model.dart'; // Add DiaryModel import
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/calendar.dart';
import 'package:recap_today/router.dart'; // Add this import
import 'package:recap_today/screens/daily_summary_screen.dart'; // Add this import
import 'dart:async'; // Import for Timer

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce; // Add Timer for debouncing

  int _currentPage = 1;
  final int _limit = 10; // Number of items per page
  int _totalResults = 0;
  bool _isLoading = false; // To prevent multiple simultaneous loads
  final ScrollController _scrollController =
      ScrollController(); // For detecting scroll to bottom

  @override
  void initState() {
    super.initState();
    // Ensure diaries are loaded when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DiaryProvider>(context, listen: false).loadDiaries();
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _currentPage = 1; // Reset to first page on new search
        _searchResults = []; // Clear previous results
        _totalResults = 0;
        _performSearch();
      });
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _searchResults.length < _totalResults) {
        _currentPage++;
        _performSearch(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel the timer when the widget is disposed
    _scrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }

  Future<void> _performSearch({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final String currentQuery = _searchController.text;

    if (!loadMore) {
      // Only update search query if it's a new search, not loading more
      if (_searchQuery != currentQuery) {
        _searchQuery = currentQuery;
      }
    }

    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _totalResults = 0;
        _currentPage = 1;
        _isLoading = false;
      });
      return;
    }

    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);

    Map<String, dynamic> searchResult = await diaryProvider.searchDiaries(
      _searchQuery,
      limit: _limit,
      offset: (loadMore ? (_currentPage - 1) * _limit : 0),
    );

    List<DiaryModel> newDiaries = searchResult['diaries'] as List<DiaryModel>;
    int totalCount = searchResult['totalCount'] as int;

    List<Map<String, dynamic>> newResults =
        newDiaries.map((diary) {
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(diary.date);
          } catch (e) {
            print(
              'Error parsing date for search result map: $e for date ${diary.date}',
            );
            parsedDate = DateTime.now();
          }
          return {
            'date': parsedDate,
            'title': diary.title,
            'content': diary.content,
          };
        }).toList();

    setState(() {
      if (loadMore) {
        _searchResults.addAll(newResults);
      } else {
        _searchResults = newResults;
      }
      _totalResults = totalCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('캘린더'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: commonTabDecoration()),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController, // Attach scroll controller
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '제목 또는 내용 검색...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  MainCalendar(
                    onDateSelectedCallback: (selectedDay) {
                      _searchController.clear();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  DailySummaryScreen(selectedDate: selectedDay),
                        ),
                      );
                    },
                  ),
                  if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Keep this if inside SingleChildScrollView
                      itemCount:
                          _searchResults.length +
                          (_searchResults.length < _totalResults
                              ? 1
                              : 0), // Add one for loading indicator
                      itemBuilder: (context, index) {
                        if (index == _searchResults.length &&
                            _searchResults.length < _totalResults) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (index >= _searchResults.length) {
                          // Should not happen if logic is correct
                          return const SizedBox.shrink();
                        }
                        final result = _searchResults[index];
                        final date = result['date'] as DateTime;
                        final title = result['title'] as String;
                        final contentSnippet =
                            (result['content'] as String).length > 100
                                ? '${(result['content'] as String).substring(0, 100)}...'
                                : result['content'] as String;

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text(
                              '${date.year}-${date.month}-${date.day}\n$contentSnippet',
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => DailySummaryScreen(
                                        selectedDate: date,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  if (_isLoading &&
                      _searchResults.isEmpty &&
                      _searchQuery
                          .isNotEmpty) // Show loader when initially loading and query is not empty
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_isLoading &&
                      _searchQuery.isNotEmpty &&
                      _searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('검색 결과가 없습니다.'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
