// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:timeago/timeago.dart' as timeago;
//
// import 'R_Top_Bar.dart';
// import 'Recruiter_provider_Job_listing.dart';
//
// class recruiter_job_listing extends StatefulWidget {
//   const recruiter_job_listing({super.key});
//
//   @override
//   State<recruiter_job_listing> createState() => _recruiter_job_listingState();
// }
//
// class _recruiter_job_listingState extends State<recruiter_job_listing> with TickerProviderStateMixin {
//   // Filter Controllers
//   String _selectedStatus = 'All';
//   String _selectedDepartment = 'All';
//   String _selectedLocation = 'All';
//   String _selectedExperience = 'All';
//   String _selectedWorkMode = 'All';
//   String _searchQuery = '';
//   final TextEditingController _searchController = TextEditingController();
//
//   // Filter Options
//   final List<String> _statusOptions = ['All', 'Active', 'Paused'];
//   final List<String> _departmentOptions = ['All', 'Engineering', 'Marketing', 'Sales', 'HR', 'Design', 'Finance'];
//   final List<String> _experienceOptions = ['All', 'Entry Level', 'Mid Level', 'Senior Level', 'Executive'];
//   final List<String> _workModeOptions = ['All', 'Remote', 'On-site', 'Hybrid'];
//
//   // Animation Controllers
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   // Column widths for consistent alignment
//   static const double statusWidth = 90.0;
//   static const double jobTitleWidth = 180.0;
//   static const double qualificationWidth = 180.0;
//   static const double departmentWidth = 130.0;
//   static const double locationWidth = 140.0;
//   static const double experienceWidth = 120.0;
//   static const double salaryWidth = 110.0;
//   static const double workModeWidth = 100.0;
//   static const double spacing = 10.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//   }
//
//   void _initializeAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     ));
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));
//
//     _fadeController.forward();
//     _slideController.forward();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _fadeController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }
//
//   void _clearFilters() {
//     setState(() {
//       _selectedStatus = 'All';
//       _selectedDepartment = 'All';
//       _selectedLocation = 'All';
//       _selectedExperience = 'All';
//       _selectedWorkMode = 'All';
//       _searchQuery = '';
//       _searchController.clear();
//     });
//   }
//
//   // Enhanced filtering logic
//   List<Map<String, dynamic>> _getFilteredJobs(List<Map<String, dynamic>> jobs) {
//     return jobs.where((job) {
//       // Search filter
//       if (_searchQuery.isNotEmpty) {
//         final query = _searchQuery.toLowerCase();
//         final title = (job['title'] as String? ?? '').toLowerCase();
//         final company = (job['company'] as String? ?? '').toLowerCase();
//         final department = (job['department'] as String? ?? '').toLowerCase();
//         final location = (job['location'] as String? ?? '').toLowerCase();
//         final experience = (job['experience'] as String? ?? '').toLowerCase();
//         final pay = (job['pay'] as String? ?? '').toLowerCase();
//         final qualifications = (job['qualifications'] as String? ?? '').toLowerCase();
//         final workModes = (job['workModes'] as List<dynamic>?)?.cast<String>().join(' ').toLowerCase() ?? '';
//
//         final searchableText = '$title $company $department $location $experience $pay $qualifications $workModes';
//         if (!searchableText.contains(query)) return false;
//       }
//
//       // Status filter
//       if (_selectedStatus != 'All') {
//         final status = job['status'] as String? ?? 'active';
//         if (_selectedStatus.toLowerCase() != status.toLowerCase()) return false;
//       }
//
//       // Department filter
//       if (_selectedDepartment != 'All') {
//         final department = job['department'] as String? ?? '';
//         if (department != _selectedDepartment) return false;
//       }
//
//       // Experience filter
//       if (_selectedExperience != 'All') {
//         final experience = job['experience'] as String? ?? '';
//         if (experience != _selectedExperience) return false;
//       }
//
//       // Work Mode filter
//       if (_selectedWorkMode != 'All') {
//         final workModes = (job['workModes'] as List<dynamic>?)?.cast<String>() ?? [];
//         if (!workModes.contains(_selectedWorkMode)) return false;
//       }
//
//       return true;
//     }).toList();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return  Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: Row(
//         children: [
//           RecruiterSidebar(activeIndex: 1),
//           Expanded(
//             child:Padding(padding: EdgeInsetsGeometry.all(0),
//
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: SlideTransition(
//                   position: _slideAnimation,
//                   child: _buildDashboardContent(context),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildDashboardContent(BuildContext context) {
//     final jobProvider = Provider.of<job_listing_provider>(context);
//     final filteredJobs = _getFilteredJobs(jobProvider.jobList);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFAFAFA),
//       appBar: _buildAppBar(context, filteredJobs.length),
//       body: Column(
//         children: [
//           _buildFilterSection(),
//           _buildListHeader(),
//           _buildJobsList(filteredJobs),
//         ],
//       ),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar(BuildContext context, int jobCount) {
//     return AppBar(
//       elevation: 0,
//       backgroundColor: Color(0xFFFAFAFA),
//       title: Text(
//         'Jobs Dashboard',
//         style: GoogleFonts.montserrat(
//           fontSize: 26,
//           fontWeight: FontWeight.w700,
//           color: Color(0xFF0B0B0B),
//         ),
//       ),
//       actions: [
//         Container(
//           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Theme.of(context).primaryColor,
//                 Theme.of(context).primaryColor.withOpacity(0.8),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(25),
//             boxShadow: [
//               BoxShadow(
//                 color: Theme.of(context).primaryColor.withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.work_outline,
//                 size: 16,
//                 color: Colors.white,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 '$jobCount Jobs',
//                 style: GoogleFonts.montserrat(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFilterSection() {
//     return Container(
//       width: double.infinity,
//       color: Color(0xFFFAFAFA),
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Search Bar
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   height: 52,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade50,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Color(0xff5C738A)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: (value) {
//                       setState(() {
//                         _searchQuery = value;
//                       });
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search jobs, companies, departments, locations...',
//                       hintStyle: GoogleFonts.montserrat(
//                         color: Colors.grey.shade500,
//                         fontSize: 15,
//                       ),
//                       prefixIcon: Container(
//                         padding: const EdgeInsets.all(12),
//                         child: Icon(
//                           Icons.search_rounded,
//                           color: Colors.grey.shade500,
//                           size: 22,
//                         ),
//                       ),
//                       border: InputBorder.none,
//                       filled: false,
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                     ),
//                     style: GoogleFonts.montserrat(fontSize: 15),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Container(
//                 height: 52,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Color(0xFF64748B), Color(0xFF64748B)],
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: ElevatedButton.icon(
//                   onPressed: _clearFilters,
//                   icon: const Icon(Icons.clear_all_rounded, size: 20),
//                   label: Text(
//                     'Clear Filters',
//                     style: GoogleFonts.montserrat(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.transparent,
//                     foregroundColor: Colors.white,
//                     shadowColor: Colors.transparent,
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 20),
//
//           // Filter Dropdowns
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _FilterDropdown(
//                   label: 'Status',
//                   value: _selectedStatus,
//                   options: _statusOptions,
//                   onChanged: (value) => setState(() => _selectedStatus = value!),
//                 ),
//                 const SizedBox(width: 16),
//                 _FilterDropdown(
//                   label: 'Department',
//                   value: _selectedDepartment,
//                   options: _departmentOptions,
//                   onChanged: (value) => setState(() => _selectedDepartment = value!),
//                 ),
//                 const SizedBox(width: 16),
//                 _FilterDropdown(
//                   label: 'Experience',
//                   value: _selectedExperience,
//                   options: _experienceOptions,
//                   onChanged: (value) => setState(() => _selectedExperience = value!),
//                 ),
//                 const SizedBox(width: 16),
//                 _FilterDropdown(
//                   label: 'Work Mode',
//                   value: _selectedWorkMode,
//                   options: _workModeOptions,
//                   onChanged: (value) => setState(() => _selectedWorkMode = value!),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildListHeader() {
//     return Container(
//       color: Colors.grey.shade50,
//       padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 16),
//       child: Row(
//         children: [
//           _HeaderCell('Status', statusWidth),
//           SizedBox(width: spacing+20),
//           _HeaderCell('Job Title', jobTitleWidth),
//           SizedBox(width: spacing),
//           _HeaderCell('Qualification', qualificationWidth),
//           SizedBox(width: spacing),
//           _HeaderCell('Department', departmentWidth),
//           SizedBox(width: spacing+15),
//           _HeaderCell('Location', locationWidth),
//           SizedBox(width: spacing),
//           _HeaderCell('Experience', experienceWidth),
//           SizedBox(width: spacing+15),
//           _HeaderCell('Salary', salaryWidth),
//           SizedBox(width: spacing),
//           _HeaderCell('Work Mode', workModeWidth),
//         ],
//       ),
//     );
//   }
//
//   Widget _HeaderCell(String title, double width) {
//     return SizedBox(
//       width: width,
//       child: Text(
//         title,
//         style: GoogleFonts.montserrat(
//           fontSize: 13,
//           fontWeight: FontWeight.w700,
//           color: Color(0xFF64748B),
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildJobsList(List<Map<String, dynamic>> filteredJobs) {
//     return Expanded(
//       child: filteredJobs.isEmpty
//           ? _buildEmptyState()
//           : ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//         itemCount: filteredJobs.length,
//         itemBuilder: (context, index) {
//           return _JobListItem(
//             jobData: filteredJobs[index],
//             index: index,
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.work_off_outlined,
//               size: 60,
//               color: Colors.grey.shade400,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No jobs found',
//             style: GoogleFonts.montserrat(
//               fontSize: 24,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Try adjusting your filters or search terms to find more results',
//             style: GoogleFonts.montserrat(
//               fontSize: 16,
//               color: Colors.grey.shade500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _FilterDropdown extends StatelessWidget {
//   final String label;
//   final String value;
//   final List<String> options;
//   final ValueChanged<String?> onChanged;
//
//   const _FilterDropdown({
//     required this.label,
//     required this.value,
//     required this.options,
//     required this.onChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 160,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: GoogleFonts.montserrat(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             height: 46,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Color(0xff5C738A)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: DropdownButton<String>(
//               value: value,
//               onChanged: onChanged,
//               underline: const SizedBox(),
//               isExpanded: true,
//               icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 24),
//               style: GoogleFonts.montserrat(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF64748B),
//
//               ),
//               dropdownColor: Colors.white,
//               elevation: 12,
//               borderRadius: BorderRadius.circular(12),
//               menuMaxHeight: 250,
//               items: options.map((String option) {
//                 return DropdownMenuItem<String>(
//                   value: option,
//                   child: Text(
//                     option,
//                     style: GoogleFonts.montserrat(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _JobListItem extends StatefulWidget {
//   final Map<String, dynamic> jobData;
//   final int index;
//
//   const _JobListItem({
//     required this.jobData,
//     required this.index,
//   });
//
//   @override
//   State<_JobListItem> createState() => _JobListItemState();
// }
//
// class _JobListItemState extends State<_JobListItem> {
//   bool _isHovered = false;
//
//   String _getRelativeTime(Timestamp? ts) {
//     if (ts == null) return '';
//     final date = ts.toDate();
//     return timeago.format(date, locale: 'en_short');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final job = widget.jobData;
//     final status = job['status'] as String? ?? 'active';
//     final isActive = status == 'active';
//
//     // Extract data
//     final title = job['title'] as String? ?? 'No Title';
//     final department = job['department'] as String? ?? 'N/A';
//     final company = job['company'] as String? ?? 'Unknown Company';
//     final location = job['location'] as String? ?? 'Unknown Location';
//     final experience = job['experience'] as String? ?? 'Not specified';
//     final pay = job['pay'] as String? ?? 'Competitive';
//     final workModes = (job['workModes'] as List<dynamic>?)?.cast<String>() ?? [];
//     final qualifications = job['qualifications'] as String? ?? '';
//     final timestamp = job['timestamp'] as Timestamp?;
//     final postedAgo = _getRelativeTime(timestamp);
//
//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovered = true),
//       onExit: (_) => setState(() => _isHovered = false),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         margin: const EdgeInsets.only(bottom: 8),
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
//         decoration: BoxDecoration(
//           color: _isHovered ? Colors.white : Colors.grey.shade50,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: _isHovered
//                 ? Theme.of(context).primaryColor.withOpacity(0.3)
//                 : Colors.grey.shade200,
//             width: _isHovered ? 2 : 1,
//           ),
//           boxShadow: _isHovered
//               ? [
//             BoxShadow(
//               color: Theme.of(context).primaryColor.withOpacity(0.15),
//               blurRadius: 12,
//               offset: const Offset(0, 6),
//             )
//           ]
//               : [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.08),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             )
//           ],
//         ),
//         child: Row(
//           children: [
//             // Status
//             _buildStatusColumn(isActive),
//             SizedBox(width: _recruiter_job_listingState.spacing),
//
//             // Job Title & Company
//             _buildJobTitleColumn(title, company, postedAgo),
//             SizedBox(width: _recruiter_job_listingState.spacing),
//
//             // Qualification
//             _buildQualificationColumn(qualifications),
//             SizedBox(width: _recruiter_job_listingState.spacing),
//
//             // Department
//             _buildDepartmentColumn(department),
//             SizedBox(width: _recruiter_job_listingState.spacing),
//
//             // Location
//             _buildLocationColumn(location),
//             SizedBox(width: _recruiter_job_listingState.spacing),
//
//             // Experience
//             _buildExperienceColumn(experience),
//             SizedBox(width: _recruiter_job_listingState.spacing),
//
//             // Salary
//             _buildSalaryColumn(pay),
//             SizedBox(width: _recruiter_job_listingState.spacing),
//
//             // Work Mode
//             _buildWorkModeColumn(workModes),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusColumn(bool isActive) {
//     return SizedBox(
//       width: _recruiter_job_listingState.statusWidth,
//       child: Row(
//         children: [
//           Container(
//             width: 10,
//             height: 10,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: isActive ? Colors.green.shade500 : Colors.red.shade500,
//               boxShadow: [
//                 BoxShadow(
//                   color: (isActive ? Colors.green : Colors.red).withOpacity(0.3),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               isActive ? 'Active' : 'Paused',
//               style: GoogleFonts.montserrat(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: isActive ? Colors.green.shade600 : Colors.red.shade600,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildJobTitleColumn(String title, String company, String postedAgo) {
//     return SizedBox(
//       width: _recruiter_job_listingState.jobTitleWidth,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: GoogleFonts.montserrat(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFF64748B),
//
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             company,
//             style: GoogleFonts.montserrat(
//               fontSize: 12,
//               color: Color(0xFF64748B),
//               fontWeight: FontWeight.w500,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           if (postedAgo.isNotEmpty) ...[
//             const SizedBox(height: 2),
//             Text(
//               postedAgo,
//               style: GoogleFonts.montserrat(
//                 fontSize: 10,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQualificationColumn(String qualifications) {
//     return SizedBox(
//       width: _recruiter_job_listingState.qualificationWidth,
//       child: Text(
//         qualifications,
//         style: GoogleFonts.montserrat(
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF64748B),
//         ),
//         maxLines: 2,
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
//   }
//
//   Widget _buildDepartmentColumn(String department) {
//     return SizedBox(
//       width: _recruiter_job_listingState.departmentWidth,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.blue.shade50,
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: Colors.blue.shade200, width: 0.5),
//         ),
//         child: Text(
//           department,
//           style: GoogleFonts.montserrat(
//             fontSize: 11,
//             fontWeight: FontWeight.w600,
//             color: Colors.blue.shade700,
//           ),
//           textAlign: TextAlign.center,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLocationColumn(String location) {
//     return SizedBox(
//       width: _recruiter_job_listingState.locationWidth,
//       child: Row(
//         children: [
//           Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
//           const SizedBox(width: 4),
//           Expanded(
//             child: Text(
//               location,
//               style: GoogleFonts.montserrat(
//                 fontSize: 12,
//                 color: Color(0xFF64748B),
//                 fontWeight: FontWeight.w500,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildExperienceColumn(String experience) {
//     return SizedBox(
//       width: _recruiter_job_listingState.experienceWidth,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.orange.shade50,
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: Colors.orange.shade200, width: 0.5),
//         ),
//         child: Text(
//           experience,
//           style: GoogleFonts.montserrat(
//             fontSize: 11,
//             fontWeight: FontWeight.w600,
//             color: Colors.orange.shade700,
//           ),
//           textAlign: TextAlign.center,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSalaryColumn(String pay) {
//     return SizedBox(
//       width: _recruiter_job_listingState.salaryWidth,
//       child: Row(
//         children: [
//           Icon(Icons.attach_money_rounded, size: 14, color: Colors.green.shade600),
//           const SizedBox(width: 2),
//           Expanded(
//             child: Text(
//               pay,
//               style: GoogleFonts.montserrat(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.green.shade700,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildWorkModeColumn(List<String> workModes) {
//     return SizedBox(
//       width: _recruiter_job_listingState.workModeWidth,
//       child: workModes.isNotEmpty
//           ? Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.purple.shade50,
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: Colors.purple.shade200, width: 0.5),
//         ),
//         child: Text(
//           workModes.first,
//           style: GoogleFonts.montserrat(
//             fontSize: 11,
//             fontWeight: FontWeight.w600,
//             color: Colors.purple.shade700,
//           ),
//           textAlign: TextAlign.center,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       )
//           : const SizedBox(),
//     );
//   }
// }