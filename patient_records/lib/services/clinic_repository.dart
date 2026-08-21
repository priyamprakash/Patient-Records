import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'fake_clinic_database.dart';

class ClinicRepository extends ChangeNotifier {
  static final ClinicRepository _instance = ClinicRepository._internal();
  factory ClinicRepository() => _instance;
  ClinicRepository._internal();

  List<Patient> _patients = [];
  List<QueueItem> _todayQueue = [];
  List<VisitRecord> _visitHistory = [];
  List<Bill> _bills = [];
  bool _isInitialized = false;

  List<Patient> get patients => List.unmodifiable(_patients);
  List<QueueItem> get todayQueue => List.unmodifiable(_todayQueue);
  List<VisitRecord> get visitHistory => List.unmodifiable(_visitHistory);
  List<Bill> get bills => List.unmodifiable(_bills);
  bool get isInitialized => _isInitialized;

  // Filtered views
  List<QueueItem> get waitingQueue =>
      _todayQueue.where((q) => q.status == 'waiting' || q.status == 'inConsultation').toList();

  List<QueueItem> get attendedTodayQueue =>
      _todayQueue.where((q) => q.status == 'completed').toList();

  List<VisitRecord> get attendedTodayVisits {
    final now = DateTime.now();
    return _visitHistory.where((v) {
      return v.date.year == now.year && v.date.month == now.month && v.date.day == now.day;
    }).toList();
  }

  double get todayRevenue {
    final now = DateTime.now();
    final todaysBills = _bills.where((b) {
      return b.date.year == now.year && b.date.month == now.month && b.date.day == now.day;
    });
    return todaysBills.fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  Future<void> init() async {
    if (_isInitialized) return;
    await _loadFromStorage();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientsRaw = prefs.getString('patients_data');
      final queueRaw = prefs.getString('queue_data');
      final visitsRaw = prefs.getString('visits_data');
      final billsRaw = prefs.getString('bills_data');

      if (patientsRaw != null) {
        final List list = jsonDecode(patientsRaw);
        _patients = list.map((e) => Patient.fromJson(e)).toList();
      }

      if (queueRaw != null) {
        final List list = jsonDecode(queueRaw);
        _todayQueue = list.map((e) => QueueItem.fromJson(e)).toList();
      }

      if (visitsRaw != null) {
        final List list = jsonDecode(visitsRaw);
        _visitHistory = list.map((e) => VisitRecord.fromJson(e)).toList();
      }

      if (billsRaw != null) {
        final List list = jsonDecode(billsRaw);
        _bills = list.map((e) => Bill.fromJson(e)).toList();
      }

      // If storage is empty, populate fake database sample data
      if (_patients.isEmpty) {
        _populateSampleData();
        await _saveToStorage();
      }
    } catch (e) {
      debugPrint('Error loading clinic data: $e');
      if (_patients.isEmpty) {
        _populateSampleData();
      }
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'patients_data', jsonEncode(_patients.map((p) => p.toJson()).toList()));
      await prefs.setString(
          'queue_data', jsonEncode(_todayQueue.map((q) => q.toJson()).toList()));
      await prefs.setString(
          'visits_data', jsonEncode(_visitHistory.map((v) => v.toJson()).toList()));
      await prefs.setString(
          'bills_data', jsonEncode(_bills.map((b) => b.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving clinic data: $e');
    }
  }

  void _populateSampleData() {
    _patients = FakeClinicDatabase.getSamplePatients();
    _todayQueue = FakeClinicDatabase.getSampleTodayQueue(_patients);
    _visitHistory = FakeClinicDatabase.getSampleVisits(_patients);
    _bills = FakeClinicDatabase.getSampleBills(_patients);
  }

  Future<void> resetToFakeDatabase() async {
    _populateSampleData();
    await _saveToStorage();
    notifyListeners();
  }

  // --- Patient Actions ---
  Future<Patient> addPatient(
    String name,
    String phone,
    int age,
    String gender, {
    String address = '',
    String medicalHistory = '',
    bool addToTodayQueue = true,
    String chiefComplaint = '',
  }) async {
    final patientId = 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final newPatient = Patient(
      id: patientId,
      name: name.trim(),
      phone: phone.trim(),
      age: age,
      gender: gender,
      address: address.trim(),
      medicalHistory: medicalHistory.trim(),
      createdAt: DateTime.now(),
    );

    _patients.add(newPatient);

    if (addToTodayQueue) {
      final newToken = getNextTokenNumber();
      final queueId = 'Q-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _todayQueue.add(QueueItem(
        id: queueId,
        patientId: newPatient.id,
        patientName: newPatient.name,
        patientPhone: newPatient.phone,
        tokenNumber: newToken,
        timeAdded: DateTime.now(),
        status: 'waiting',
        chiefComplaint: chiefComplaint,
      ));
    }

    await _saveToStorage();
    notifyListeners();
    return newPatient;
  }

  Future<void> addToQueue(String patientId, String chiefComplaint) async {
    final patient = _patients.firstWhere((p) => p.id == patientId);
    final newToken = getNextTokenNumber();
    final queueId = 'Q-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    _todayQueue.add(QueueItem(
      id: queueId,
      patientId: patient.id,
      patientName: patient.name,
      patientPhone: patient.phone,
      tokenNumber: newToken,
      timeAdded: DateTime.now(),
      status: 'waiting',
      chiefComplaint: chiefComplaint,
    ));

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateQueueStatus(String queueId, String newStatus) async {
    final index = _todayQueue.indexWhere((q) => q.id == queueId);
    if (index != -1) {
      _todayQueue[index] = _todayQueue[index].copyWith(status: newStatus);
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<VisitRecord> attendPatient({
    required QueueItem queueItem,
    required String diagnosis,
    required String prescription,
    required String notes,
    required double fee,
    bool autoCreateBill = true,
  }) async {
    // 1. Mark Queue Item as Completed
    final qIndex = _todayQueue.indexWhere((q) => q.id == queueItem.id);
    if (qIndex != -1) {
      _todayQueue[qIndex] = _todayQueue[qIndex].copyWith(status: 'completed');
    }

    // 2. Create Visit Record
    final visitId = 'VIS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    String? billId;

    if (autoCreateBill && fee > 0) {
      final newBill = await generateBill(
        patientId: queueItem.patientId,
        patientName: queueItem.patientName,
        patientPhone: queueItem.patientPhone,
        items: [
          BillItem(
            id: '1',
            description: 'Consultation Fee',
            quantity: 1,
            unitPrice: fee,
          ),
        ],
        discount: 0,
        tax: 0,
        paymentStatus: 'Paid',
        paymentMethod: 'Cash',
      );
      billId = newBill.id;
    }

    final visit = VisitRecord(
      id: visitId,
      patientId: queueItem.patientId,
      patientName: queueItem.patientName,
      date: DateTime.now(),
      tokenNumber: queueItem.tokenNumber,
      diagnosis: diagnosis,
      prescription: prescription,
      notes: notes,
      fee: fee,
      billId: billId,
    );

    _visitHistory.insert(0, visit);
    await _saveToStorage();
    notifyListeners();
    return visit;
  }

  Future<Bill> generateBill({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required List<BillItem> items,
    double discount = 0.0,
    double tax = 0.0,
    String paymentStatus = 'Paid',
    String paymentMethod = 'Cash',
  }) async {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final total = (subtotal - discount) + tax;
    final billId = 'BILL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final billNum = generateNextBillNumber();

    final bill = Bill(
      id: billId,
      billNumber: billNum,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      date: DateTime.now(),
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      totalAmount: total > 0 ? total : 0,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
    );

    _bills.insert(0, bill);
    await _saveToStorage();
    notifyListeners();
    return bill;
  }

  // --- Queries & Utilities ---
  int getNextTokenNumber() {
    if (_todayQueue.isEmpty) return 1;
    final maxToken = _todayQueue.fold(0, (max, q) => q.tokenNumber > max ? q.tokenNumber : max);
    return maxToken + 1;
  }

  String generateNextBillNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final countToday = _bills.where((b) {
          return b.date.year == now.year && b.date.month == now.month && b.date.day == now.day;
        }).length +
        1;
    return 'INV-$dateStr-${countToday.toString().padLeft(3, '0')}';
  }

  List<Patient> searchPatients(String query) {
    if (query.trim().isEmpty) return patients;
    final q = query.trim().toLowerCase();
    return _patients.where((p) {
      return p.name.toLowerCase().contains(q) || p.phone.contains(q);
    }).toList();
  }

  List<VisitRecord> getAttendedVisitsForDate(DateTime date) {
    return _visitHistory.where((v) {
      return v.date.year == date.year && v.date.month == date.month && v.date.day == date.day;
    }).toList();
  }

  Set<DateTime> getAttendedDates() {
    final set = <DateTime>{};
    for (final v in _visitHistory) {
      set.add(DateTime(v.date.year, v.date.month, v.date.day));
    }
    return set;
  }

  List<VisitRecord> getVisitsForPatient(String patientId) {
    return _visitHistory.where((v) => v.patientId == patientId).toList();
  }

  List<Bill> getBillsForPatient(String patientId) {
    return _bills.where((b) => b.patientId == patientId).toList();
  }

  Patient? getPatientById(String patientId) {
    try {
      return _patients.firstWhere((p) => p.id == patientId);
    } catch (_) {
      return null;
    }
  }
}
