import 'package:flutter/material.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../home/home_page.dart';
import '../practice/practice_page.dart';
import '../exam/exam_page.dart';
import '../wrong_book/wrong_book_page.dart';
import '../settings/settings_page.dart';

/// Main Page with Bottom Navigation
/// Root scaffold with bottom navigation bar
class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const HomePage(),
    const PracticePage(),
    const ExamPage(),
    const WrongBookPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onPageSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onPageSelected,
        items: BottomNavBar.defaultItems,
      ),
    );
  }
}
