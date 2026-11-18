import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/state/app_state.dart';

class StudentsManagementPage extends ConsumerStatefulWidget {
  const StudentsManagementPage({super.key});

  @override
  ConsumerState<StudentsManagementPage> createState() =>
      _StudentsManagementPageState();
}

class _StudentsManagementPageState
    extends ConsumerState<StudentsManagementPage> {
  String _searchQuery = '';
  String _selectedClass = 'All Classes';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCsvImportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bulk Student CSV Import',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload a CSV with columns: Full Name, Student Code, Roll No, Class, Parent Email.',
              style: TextStyle(
                  color: AppColors.tertiary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.softMint.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryContainer),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      size: 40, color: AppColors.primary),
                  const SizedBox(height: 8),
                  const Text('Select .CSV or Excel file',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Supports up to 500 students per batch',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Sample CSV format: Full Name,Student Code,Roll No,Class,Parent Email')),
                      );
                    },
                    child: const Text('View Template'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      const sampleCsv = '''
Full Name,Student Code,Roll No,Class,Parent Email
Kavya Joshi,STU1006,106,Grade 10 - Section A,kavya.joshi@example.com
Devansh Kapoor,STU1007,107,Grade 10 - Section A,devansh.kapoor@example.com
Isha Singhania,STU1008,108,Grade 10 - Section A,isha.singh@example.com
''';
                      final count = ref
                          .read(studentsProvider.notifier)
                          .importFromCsv(sampleCsv);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('$count new students imported into roster!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    child: const Text('Import Roster'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsProvider);

    final filtered = students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.roll.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesClass =
          _selectedClass == 'All Classes' || s.className == _selectedClass;
      return matchesSearch && matchesClass;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Students & Parents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import CSV',
            onPressed: _showCsvImportDialog,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              tooltip: 'Add Student',
              onPressed: () => context.push('/add-student'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, roll, or ID...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.outline),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    isExpanded: true,
                    items: [
                      'All Classes',
                      'Grade 10 - Section A',
                      'Grade 10 - Section B',
                      'Grade 12 - Science'
                    ]
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedClass = v!),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total Count Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Students Enrolled',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiary),
                ),
                const Text(
                  'Active Term: 2026-27',
                  style: TextStyle(fontSize: 12, color: AppColors.tertiary),
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No students match your filter criteria',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      final initials = student.name
                          .split(' ')
                          .take(2)
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .join();

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.softMint,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  student.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.softMint,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  student.avgScore,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'ID: ${student.code} • Roll: ${student.roll}',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  'Parent: ${student.parentEmail}',
                                  style: const TextStyle(
                                      color: AppColors.tertiary, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.outline),
                          onTap: () {
                            ref.read(selectedStudentIdProvider.notifier).state =
                                student.id;
                            context.push('/student-detail');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
