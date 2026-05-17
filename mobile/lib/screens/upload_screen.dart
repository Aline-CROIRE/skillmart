import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  final Project? existingProject; 
  const UploadScreen({super.key, this.existingProject});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  // Basic Info
  late TextEditingController _title;
  late TextEditingController _desc;
  late TextEditingController _externalLink;
  String _category = 'Select category';
  PlatformFile? _thumbnail;

  // Ownership
  String _ownerType = 'Individual';
  late TextEditingController _ownerName;
  late TextEditingController _ceoName;
  late TextEditingController _linkedinUrl;

  // Project Details & Verification
  String _projectType = 'Business Idea';
  PlatformFile? _mainFile;
  PlatformFile? _proposalDoc;
  PlatformFile? _rdbProof;
  PlatformFile? _incomeStmt;
  PlatformFile? _taxHistory;
  PlatformFile? _taxClearance;
  PlatformFile? _pitchVideo;

  // Shareholders
  late TextEditingController _maxShareholders;
  late TextEditingController _currentInvestors;
  late TextEditingController _totalShares;
  late TextEditingController _minShare;
  late TextEditingController _shareValue;
  late TextEditingController _rdbReg;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existingProject?.title ?? "");
    _desc = TextEditingController(text: widget.existingProject?.description ?? "");
    _externalLink = TextEditingController(text: widget.existingProject?.externalLink ?? "");
    if (widget.existingProject != null) _category = widget.existingProject!.category;

    _ownerType = widget.existingProject?.ownerType ?? "Individual";
    _ownerName = TextEditingController(text: widget.existingProject?.ownerName ?? "");
    _ceoName = TextEditingController(text: widget.existingProject?.ceoName ?? "");
    _linkedinUrl = TextEditingController(text: widget.existingProject?.linkedinUrl ?? "");

    _projectType = widget.existingProject?.projectType ?? "Business Idea";
    if (_projectType == "Investment Seeking") _projectType = "Shareholder Seeking"; // Compatibility

    _maxShareholders = TextEditingController(text: widget.existingProject?.maxShareholders.toString() ?? "0");
    _currentInvestors = TextEditingController(text: widget.existingProject?.currentInvestors.toString() ?? "0");
    _totalShares = TextEditingController(text: widget.existingProject?.totalSharesAvailable.toString() ?? "0");
    _minShare = TextEditingController(text: widget.existingProject?.minShare.toString() ?? "0");
    _shareValue = TextEditingController(text: widget.existingProject?.shareValue.toString() ?? "0");
    _rdbReg = TextEditingController(text: widget.existingProject?.rdbRegistrationNumber ?? "");
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        final profile = await ApiService().getProfile(token);
        if (mounted) setState(() => _userProfile = profile);
      }
    } catch (e) { debugPrint("Profile fetch failed: $e"); }
  }

  Future<String?> _upload(PlatformFile? file, String? currentUrl) async {
    if (file == null) return currentUrl;
    return await ApiService().uploadFile(file);
  }

  Future<void> _submit() async {
    if (_category == 'Select category') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')!;

    // Phone Number Validation
    final phone = _userProfile?['phoneNumber'];
    if (phone == null || phone.toString().isEmpty) {
      setState(() => _isLoading = false);
      if (mounted) {
        final phoneController = TextEditingController();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Phone Number Required"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Please provide a Rwandan phone number to continue with your submission."),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    hintText: "e.g., 078...",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () async {
                  if (phoneController.text.trim().isEmpty) return;
                  
                  // Disable button while processing
                  Navigator.pop(context); // close dialog
                  setState(() => _isLoading = true);
                  
                  try {
                    await ApiService().updateProfileInfo({
                      'phoneNumber': phoneController.text.trim(),
                    }, token);
                    
                    // Refresh profile and proceed
                    await _fetchProfile();
                    _submit(); // resume submission
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                }, 
                child: const Text("SAVE & CONTINUE")
              ),
            ],
          )
        );
      }
      return;
    }

    String? thumbUrl = await _upload(_thumbnail, widget.existingProject?.thumbnailUrl);
    String? fileUrl = await _upload(_mainFile, widget.existingProject?.fileUrl);
    String? propUrl = await _upload(_proposalDoc, widget.existingProject?.proposalUrl);
    String? rdbUrl = await _upload(_rdbProof, widget.existingProject?.rdbProofUrl);
    String? incUrl = await _upload(_incomeStmt, widget.existingProject?.incomeStatementUrl);
    String? histUrl = await _upload(_taxHistory, widget.existingProject?.rraTaxHistoryUrl);
    String? clearUrl = await _upload(_taxClearance, widget.existingProject?.rraClearanceUrl);
    String? videoUrl = await _upload(_pitchVideo, widget.existingProject?.pitchVideoUrl);

    final data = {
      'title': _title.text,
      'description': _desc.text,
      'category': _category,
      'price': widget.existingProject?.price ?? 0,
      'thumbnailUrl': thumbUrl,
      'fileUrl': fileUrl,
      'externalLink': _externalLink.text,
      'rdbRegistrationNumber': _projectType == "Shareholder Seeking" ? _rdbReg.text : "",
      'sellerId': prefs.getString('userId'),
      'ownerType': _ownerType,
      'ownerName': _ownerName.text,
      'ceoName': _ceoName.text,
      'linkedinUrl': _linkedinUrl.text,
      'projectType': _projectType,
      'proposalUrl': propUrl,
      'rdbProofUrl': rdbUrl,
      'incomeStatementUrl': incUrl,
      'rraTaxHistoryUrl': histUrl,
      'rraClearanceUrl': clearUrl,
      'pitchVideoUrl': videoUrl,
      'isShareholderSeeking': _projectType == "Shareholder Seeking",
      'maxShareholders': int.tryParse(_maxShareholders.text) ?? 0,
      'currentInvestors': int.tryParse(_currentInvestors.text) ?? 0,
      'totalSharesAvailable': int.tryParse(_totalShares.text) ?? 0,
      'minShare': int.tryParse(_minShare.text) ?? 0,
      'shareValue': int.tryParse(_shareValue.text) ?? 0,
    };

    bool success;
    if (widget.existingProject != null) {
      success = await ApiService().updateProject(widget.existingProject!.id, data, token);
    } else {
      success = await ApiService().submitProject(data, token);
    }

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project Submitted!")));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    int totalSteps = _projectType == "Shareholder Seeking" ? 4 : 3;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Create New Project")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildStepIndicator(colorScheme, totalSteps),
              Expanded(
                child: AnimatedSwitcher(
                  duration: 400.ms,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildCurrentStep(context, colorScheme),
                ),
              ),
              _buildNavButtons(colorScheme, totalSteps),
            ],
          ),
    );
  }

  Widget _buildStepIndicator(ColorScheme colorScheme, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: List.generate(total, (index) {
          bool isCurrent = _currentStep == index;
          bool isDone = _currentStep > index;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green : (isCurrent ? colorScheme.primary : colorScheme.surface),
                    shape: BoxShape.circle,
                    border: Border.all(color: isCurrent ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.1)),
                    boxShadow: isCurrent ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 10)] : [],
                  ),
                  child: Center(
                    child: isDone 
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text("${index + 1}", style: TextStyle(color: isCurrent ? Colors.white : colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                  ),
                ),
                if (index < total - 1) 
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: isDone ? Colors.green : colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, ColorScheme colorScheme) {
    switch (_currentStep) {
      case 0: return _stepBasics(context, colorScheme);
      case 1: return _stepOwnership(context, colorScheme);
      case 2: return _stepVerification(context, colorScheme);
      case 3: return _stepShareholders(context, colorScheme);
      default: return const SizedBox();
    }
  }

  Widget _stepBasics(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(25),
      children: [
        _sectionTitle("Core Project Info"),
        _input("Project Name", _title, Icons.title, context),
        _dropdown("Category", _category, ["Select category", "Academic", "Business", "Creative", "Technology", "Professional"], (v) => setState(() => _category = v!)),
        _filePicker("Thumbnail Image (Identity)", _thumbnail, (f) => setState(() => _thumbnail = f), allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'], existingUrl: widget.existingProject?.thumbnailUrl),
        _input("Description", _desc, Icons.description, context, lines: 4),
        _input("Project Website / App Link (Optional)", _externalLink, Icons.link, context),
        _filePicker("Main Project File (PDF/Doc)", _mainFile, (f) => setState(() => _mainFile = f), existingUrl: widget.existingProject?.fileUrl),
      ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideX(begin: 0.1),
    );
  }

  Widget _stepOwnership(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(25),
      children: [
        _sectionTitle("Ownership Details"),
        _dropdown("Owner Type", _ownerType, ["Individual", "Company"], (v) => setState(() => _ownerType = v!)),
        const SizedBox(height: 10),
        _input(_ownerType == "Individual" ? "Creator Full Name" : "Company Name", _ownerName, Icons.person_pin, context),
        if (_ownerType == "Company") _input("CEO Name", _ceoName, Icons.badge, context),
        if (_ownerType == "Individual") _input("LinkedIn Profile URL (Optional)", _linkedinUrl, Icons.link, context),
      ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideX(begin: 0.1),
    );
  }

  Widget _stepVerification(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(25),
      children: [
        _sectionTitle("Verification & Evidence"),
        _dropdown("Project Maturity", _projectType, ["Business Idea", "Shareholder Seeking", "Operational"], (v) {
          setState(() {
            _projectType = v!;
            if (_currentStep > 2 && _projectType != "Shareholder Seeking") _currentStep = 2;
          });
        }),
        const SizedBox(height: 20),
        _sectionTitle("Business & Verification Docs"),
        if (_projectType == "Shareholder Seeking") 
          _input("RDB Registration Number", _rdbReg, Icons.business, context),
        
        _filePicker("Detailed Proposal (PDF)", _proposalDoc, (f) => setState(() => _proposalDoc = f), allowedExtensions: ['pdf'], existingUrl: widget.existingProject?.proposalUrl),
        _filePicker("RDB Certificate (PDF/Image)", _rdbProof, (f) => setState(() => _rdbProof = f), existingUrl: widget.existingProject?.rdbProofUrl),
        _filePicker("Income Statement (Optional)", _incomeStmt, (f) => setState(() => _incomeStmt = f), allowedExtensions: ['pdf'], existingUrl: widget.existingProject?.incomeStatementUrl),
        _filePicker("Tax History (Optional)", _taxHistory, (f) => setState(() => _taxHistory = f), allowedExtensions: ['pdf'], existingUrl: widget.existingProject?.rraTaxHistoryUrl),
        _filePicker("Tax Clearance (Optional)", _taxClearance, (f) => setState(() => _taxClearance = f), allowedExtensions: ['pdf'], existingUrl: widget.existingProject?.rraClearanceUrl),
        _filePicker("Pitch Video (Optional MP4)", _pitchVideo, (f) => setState(() => _pitchVideo = f), allowedExtensions: ['mp4', 'mov', 'avi'], existingUrl: widget.existingProject?.pitchVideoUrl),
      ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideX(begin: 0.1),
    );
  }

  Widget _stepShareholders(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(25),
      children: [
        _sectionTitle("Shareholder Configuration"),
        Text(
          "As you are seeking shareholders, please define your market offering.",
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 25),
        _input("Total Shares on Market (%)", _totalShares, Icons.pie_chart, context, isNum: true),
        _input("Maximum Number of Shareholders", _maxShareholders, Icons.groups, context, isNum: true),
        _input("Current Secured Investors", _currentInvestors, Icons.group_add, context, isNum: true),
        _input("Minimum Share per Holder (%)", _minShare, Icons.percent, context, isNum: true),
        _input("Share Unit Value (RWF)", _shareValue, Icons.money, context, isNum: true),
      ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideX(begin: 0.1),
    );
  }

  Widget _buildNavButtons(ColorScheme colorScheme, int total) {
    bool isLast = _currentStep == total - 1;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: colorScheme.surface, border: Border(top: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)))),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("PREVIOUS"),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (!isLast) {
                  setState(() => _currentStep++);
                } else {
                  _submit();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18), 
                backgroundColor: isLast ? Colors.green : colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: Text(isLast ? "SUBMIT FOR ANALYSIS" : "NEXT STEP", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  );

  Widget _input(String h, TextEditingController c, IconData i, BuildContext context, {int lines = 1, bool isNum = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextField(
      controller: c, maxLines: lines, 
      keyboardType: isNum ? TextInputType.number : TextInputType.text, 
      decoration: InputDecoration(
        labelText: h,
        hintText: h, 
        prefixIcon: Icon(i, size: 20), 
      )
    ),
  );

  Widget _dropdown(String label, String value, List<String> options, Function(String?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DropdownButtonFormField<String>(
      value: value, 
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))).toList(), 
      onChanged: onChanged, 
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.list, size: 20)
      )
    ),
  );

  Widget _filePicker(String label, PlatformFile? file, Function(PlatformFile) onPicked, {List<String>? allowedExtensions, String? existingUrl}) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: InkWell(
      onTap: () async {
        final r = await FilePicker.platform.pickFiles(
          type: allowedExtensions != null ? FileType.custom : FileType.any,
          allowedExtensions: allowedExtensions,
        );
        if (r != null) onPicked(r.files.first);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22), 
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1))
        ), 
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 15), 
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                  Text(file?.name ?? (existingUrl != null ? "Existing file saved" : "No file selected"), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            if (file != null || existingUrl != null) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ]
        )
      ),
    ),
  );
}