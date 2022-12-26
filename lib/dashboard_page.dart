import 'package:flutter/material.dart';

import 'package:bill_splitter/bills_page.dart';
import 'package:bill_splitter/history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentPage = 0;
  List<Widget> screens = const [
    BillsPage(),
    HistoryPage(),
    // StatisticsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D/Vibe'),
        actions: [
          IconButton(
            onPressed: () {
              debugPrint('Profile clicked');
            },
            icon: const Icon(Icons.account_circle_sharp),
          ),
        ],
      ),
      body: screens[currentPage],
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            debugPrint('Add bill button clicked');
          },
          child: const Icon(Icons.add)),
      // Bottom Navbar
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.business), label: 'History'),
          // NavigationDestination(
          // icon: Icon(Icons.chat_rounded), label: 'Statics')
        ],
        // Loading page based on navbar selection
        onDestinationSelected: (int index) {
          setState(() {
            currentPage = index;
          });
        },
        selectedIndex: currentPage,
      ),
    );
  }
}
