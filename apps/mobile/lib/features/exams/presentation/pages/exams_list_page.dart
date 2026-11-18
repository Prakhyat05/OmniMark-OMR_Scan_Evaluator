import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/state/app_state.dart';

class ExamsListPage extends ConsumerStatefulWidget {
  const ExamsListPage({super.key});

  @override
  ConsumerState<ExamsListPage> createState() => _ExamsListPageState();
}

class _ExamsListPageState extends ConsumerState<ExamsListPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(examsProvider);

    final filteredExams = exams.where((e) {
      final matchesFilter = switch (_selectedFilter) {
        'Published' => e.status == 'published',
        'Completed' => e.status == 'completed',
        'Draft' => e.status == 'draft',
        _ => true,
      };

      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.className.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search assessments...',
                  border: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(color: AppColors.tertiary),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('Assessments & Exams'),
        actions: [
          IconButton(
            icon:
                Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              icon: const Icon(Icons.add_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              tooltip: 'Create Assessment',
              onPressed: () => context.push('/create-exam'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children:
                  ['All', 'Published', 'Completed', 'Draft'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    backgroundColor: AppColors.surfaceContainerLow,
                    selectedColor: AppColors.softMint,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Exams List
          Expanded(
            child: filteredExams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No assessments match "$_searchQuery"'
                              : 'No $_selectedFilter assessments found',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredExams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index];
                      final isDraft = exam.status == 'draft';

                      return InkWell(
                        onTap: () {
                          ref.read(activeExamIdProvider.notifier).state =
                              exam.id;
                          if (isDraft) {
                            context.push('/answer-key-setup');
                          } else {
                            context.push('/exam-results-summary');
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.surfaceContainerHigh),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDraft
                                          ? AppColors.surfaceContainerHigh
                                          : AppColors.softMint,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      exam.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isDraft
                                            ? AppColors.tertiary
                                            : AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    exam.date,
                                    style: TextStyle(
                                        color:
                                            AppColors.tertiary.withOpacity(0.8),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                exam.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${exam.className} • ${exam.questionsCount} Questions',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${exam.scannedCount} of ${exam.totalStudents} sheets',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12),
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          side: const BorderSide(
                                              color: AppColors.primary),
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(
                                                  activeExamIdProvider.notifier)
                                              .state = exam.id;
                                          context.push('/scan');
                                        },
                                        icon: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 14,
                                            color: AppColors.primary),
                                        label: const Text('Scan',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(
                                                  activeExamIdProvider.notifier)
                                              .state = exam.id;
                                          if (isDraft) {
                                            context.push('/answer-key-setup');
                                          } else {
                                            context
                                                .push('/exam-results-summary');
                                          }
                                        },
                                        icon: Icon(
                                            isDraft
                                                ? Icons.edit_note_rounded
                                                : Icons.insights_rounded,
                                            size: 14,
                                            color: AppColors.tertiary),
                                        label: Text(
                                            isDraft ? 'Edit Key' : 'Results',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.tertiary)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
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
