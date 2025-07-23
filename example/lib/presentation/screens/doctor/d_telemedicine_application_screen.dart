import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'doctor_drawer.dart'; // 같은 폴더 또는 경로에 맞게 수정

class DTelemedicineApplicationScreen extends StatefulWidget {
  final String baseUrl;
  final int initialTab;

  const DTelemedicineApplicationScreen({
    super.key,
    required this.baseUrl,
    this.initialTab = 0,
  });

  @override
  State<DTelemedicineApplicationScreen> createState() => _DTelemedicineApplicationScreenState();
}

class _DTelemedicineApplicationScreenState extends State<DTelemedicineApplicationScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _patients = [
    {'name': '김철수', 'status': '진단 대기', 'date': '2025-07-17', 'time': '09:00'},
    {'name': '이영희', 'status': '진단 대기', 'date': '2025-07-17', 'time': '09:10'},
    {'name': '박민수', 'status': '진단 완료', 'date': '2025-07-17', 'time': '09:20'},
    {'name': '최지우', 'status': '진단 완료', 'date': '2025-07-17', 'time': '09:30'},
    {'name': '장하늘', 'status': '진단 대기', 'date': '2025-07-17', 'time': '09:40'},
    {'name': '한가람', 'status': '진단 완료', 'date': '2025-07-17', 'time': '09:50'},
    {'name': '서유리', 'status': '진단 대기', 'date': '2025-07-17', 'time': '10:00'},
    {'name': '오하늘', 'status': '진단 완료', 'date': '2025-07-17', 'time': '10:10'},
    {'name': '강도현', 'status': '진단 완료', 'date': '2025-07-17', 'time': '10:20'},
    {'name': '이수민', 'status': '진단 대기', 'date': '2025-07-17', 'time': '10:30'},
    {'name': '문정우', 'status': '진단 대기', 'date': '2025-07-17', 'time': '10:40'},
    {'name': '배지훈', 'status': '진단 완료', 'date': '2025-07-17', 'time': '10:50'},
  ];

  final List<String> statuses = ['ALL', '진단 대기', '진단 완료'];
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map && extra.containsKey('initialTab')) {
        final int index = extra['initialTab'] ?? 0;
        if (index >= 0 && index < statuses.length) {
          setState(() {
            _selectedIndex = index;
            _pageController.jumpToPage(index);
          });
        }
      }
    });
  }

  List<Map<String, dynamic>> get _filteredPatients {
    String keyword = _searchController.text.trim();
    String selectedStatus = statuses[_selectedIndex];
    return _patients.where((patient) {
      final matchesFilter = selectedStatus == 'ALL' || patient['status'] == selectedStatus;
      final matchesSearch = keyword.isEmpty || patient['name'].contains(keyword);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedPatients {
    final start = _currentPage * _itemsPerPage;
    final end = (_currentPage + 1) * _itemsPerPage;
    final list = _filteredPatients;
    return list.sublist(start, end > list.length ? list.length : end);
  }

  int get _totalPages => (_filteredPatients.length / _itemsPerPage).ceil();

  Color _getSelectedColorByStatus(String status) {
    switch (status) {
      case '진단 대기':
        return Colors.orange;
      case '진단 완료':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage + 1 < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFAAD0F8),
      appBar: AppBar(
        title: const Text('비대면 진료 신청 현황'),
        backgroundColor: const Color(0xFF4386DB),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
      ),
      drawer: DoctorDrawer(baseUrl: widget.baseUrl),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildSearchBar(),
          _buildStatusChips(),
          Expanded(child: _buildPatientListView()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 0),
              decoration: const InputDecoration(
                hintText: '환자 이름을 검색하세요',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () => setState(() => _currentPage = 0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / statuses.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: itemWidth,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSelectedColorByStatus(statuses[_selectedIndex]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: List.generate(statuses.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        _currentPage = 0;
                        _pageController.jumpToPage(index);
                      });
                    },
                    child: Container(
                      width: itemWidth,
                      alignment: Alignment.center,
                      child: Text(
                        statuses[index],
                        style: TextStyle(
                          color: _selectedIndex == index ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildPatientListView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
          _currentPage = 0;
        });
      },
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final filtered = _filteredPatients;
        final paginated = _paginatedPatients;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                ),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: filtered.isEmpty
                    ? const Center(child: Text('일치하는 환자가 없습니다.'))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paginated.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.grey[300], thickness: 1),
                        itemBuilder: (context, i) {
                          final patient = paginated[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline),
                                const SizedBox(width: 12),
                                Text(
                                  patient['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('날짜 : ${patient['date']}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text('시간 : ${patient['time']}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  height: 64,
                                  width: 64,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _getSelectedColorByStatus(patient['status']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    patient['status'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black12),
                    ),
                    onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('이전'),
                  ),
                  const SizedBox(width: 16),
                  Text('${_currentPage + 1} / $_totalPages', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black12),
                    ),
                    onPressed: (_currentPage + 1 < _totalPages) ? _goToNextPage : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('다음'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
