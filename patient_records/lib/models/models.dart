class Vitals {
  final String bp; // e.g. "120/80"
  final String pulse; // e.g. "72"
  final String temperature; // e.g. "98.6"
  final String weight; // e.g. "70"
  final String spo2; // e.g. "98"
  final String bloodSugar; // e.g. "110"

  Vitals({
    this.bp = '',
    this.pulse = '',
    this.temperature = '',
    this.weight = '',
    this.spo2 = '',
    this.bloodSugar = '',
  });

  bool get isEmpty =>
      bp.isEmpty &&
      pulse.isEmpty &&
      temperature.isEmpty &&
      weight.isEmpty &&
      spo2.isEmpty &&
      bloodSugar.isEmpty;

  Map<String, dynamic> toJson() => {
        'bp': bp,
        'pulse': pulse,
        'temperature': temperature,
        'weight': weight,
        'spo2': spo2,
        'bloodSugar': bloodSugar,
      };

  factory Vitals.fromJson(Map<String, dynamic> json) => Vitals(
        bp: json['bp'] as String? ?? '',
        pulse: json['pulse'] as String? ?? '',
        temperature: json['temperature'] as String? ?? '',
        weight: json['weight'] as String? ?? '',
        spo2: json['spo2'] as String? ?? '',
        bloodSugar: json['bloodSugar'] as String? ?? '',
      );

  String get summaryText {
    final parts = <String>[];
    if (bp.isNotEmpty) parts.add('BP: $bp mmHg');
    if (pulse.isNotEmpty) parts.add('Pulse: $pulse bpm');
    if (temperature.isNotEmpty) parts.add('Temp: $temperature °F');
    if (weight.isNotEmpty) parts.add('Weight: $weight kg');
    if (spo2.isNotEmpty) parts.add('SpO2: $spo2%');
    if (bloodSugar.isNotEmpty) parts.add('Sugar: $bloodSugar mg/dL');
    return parts.join(' | ');
  }
}

class MedicineMaster {
  final String id;
  final String name;
  final String type; // Tablet, Capsule, Syrup, Injection, Ointment, Drops
  final String defaultDosage; // e.g. 500mg, 10ml
  final String defaultFrequency; // e.g. 1-0-1
  final String defaultDuration; // e.g. 5 days
  final String defaultInstructions; // e.g. After food

  MedicineMaster({
    required this.id,
    required this.name,
    this.type = 'Tablet',
    this.defaultDosage = '',
    this.defaultFrequency = '1-0-1',
    this.defaultDuration = '5 days',
    this.defaultInstructions = 'After food',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'defaultDosage': defaultDosage,
        'defaultFrequency': defaultFrequency,
        'defaultDuration': defaultDuration,
        'defaultInstructions': defaultInstructions,
      };

  factory MedicineMaster.fromJson(Map<String, dynamic> json) => MedicineMaster(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String? ?? 'Tablet',
        defaultDosage: json['defaultDosage'] as String? ?? '',
        defaultFrequency: json['defaultFrequency'] as String? ?? '1-0-1',
        defaultDuration: json['defaultDuration'] as String? ?? '5 days',
        defaultInstructions: json['defaultInstructions'] as String? ?? 'After food',
      );
}

class PrescribedMedicine {
  final String name;
  final String type;
  final String dosage;
  final String frequency; // 1-0-1, 1-1-1, 1-0-0, 0-0-1, etc.
  final String duration; // e.g. 3 days, 5 days
  final String instructions; // After food, Before food

  PrescribedMedicine({
    required this.name,
    this.type = 'Tablet',
    this.dosage = '',
    this.frequency = '1-0-1',
    this.duration = '5 days',
    this.instructions = 'After food',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
      };

  factory PrescribedMedicine.fromJson(Map<String, dynamic> json) => PrescribedMedicine(
        name: json['name'] as String,
        type: json['type'] as String? ?? 'Tablet',
        dosage: json['dosage'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '1-0-1',
        duration: json['duration'] as String? ?? '5 days',
        instructions: json['instructions'] as String? ?? 'After food',
      );

  String get displayText => '$type $name ${dosage.isNotEmpty ? "($dosage)" : ""} — $frequency for $duration [$instructions]';
}

class Patient {
  final String id;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String address;
  final String medicalHistory;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    this.address = '',
    this.medicalHistory = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'age': age,
        'gender': gender,
        'address': address,
        'medicalHistory': medicalHistory,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        age: json['age'] as int,
        gender: json['gender'] as String,
        address: json['address'] as String? ?? '',
        medicalHistory: json['medicalHistory'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Patient copyWith({
    String? id,
    String? name,
    String? phone,
    int? age,
    String? gender,
    String? address,
    String? medicalHistory,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class QueueItem {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final int tokenNumber;
  final DateTime timeAdded;
  final String status; // 'waiting', 'inConsultation', 'completed', 'cancelled'
  final String chiefComplaint;
  final Vitals? vitals;

  QueueItem({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.tokenNumber,
    required this.timeAdded,
    this.status = 'waiting',
    this.chiefComplaint = '',
    this.vitals,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'tokenNumber': tokenNumber,
        'timeAdded': timeAdded.toIso8601String(),
        'status': status,
        'chiefComplaint': chiefComplaint,
        'vitals': vitals?.toJson(),
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String,
        patientPhone: json['patientPhone'] as String,
        tokenNumber: json['tokenNumber'] as int,
        timeAdded: DateTime.parse(json['timeAdded'] as String),
        status: json['status'] as String? ?? 'waiting',
        chiefComplaint: json['chiefComplaint'] as String? ?? '',
        vitals: json['vitals'] != null
            ? Vitals.fromJson(json['vitals'] as Map<String, dynamic>)
            : null,
      );

  QueueItem copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    int? tokenNumber,
    DateTime? timeAdded,
    String? status,
    String? chiefComplaint,
    Vitals? vitals,
  }) {
    return QueueItem(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      timeAdded: timeAdded ?? this.timeAdded,
      status: status ?? this.status,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      vitals: vitals ?? this.vitals,
    );
  }
}

class VisitRecord {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime date;
  final int tokenNumber;
  final String diagnosis;
  final String prescription;
  final String notes;
  final double fee;
  final String? billId;
  final Vitals? vitals;
  final List<PrescribedMedicine> medicines;

  VisitRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.tokenNumber,
    this.diagnosis = '',
    this.prescription = '',
    this.notes = '',
    this.fee = 0.0,
    this.billId,
    this.vitals,
    this.medicines = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'date': date.toIso8601String(),
        'tokenNumber': tokenNumber,
        'diagnosis': diagnosis,
        'prescription': prescription,
        'notes': notes,
        'fee': fee,
        'billId': billId,
        'vitals': vitals?.toJson(),
        'medicines': medicines.map((m) => m.toJson()).toList(),
      };

  factory VisitRecord.fromJson(Map<String, dynamic> json) => VisitRecord(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String,
        date: DateTime.parse(json['date'] as String),
        tokenNumber: json['tokenNumber'] as int,
        diagnosis: json['diagnosis'] as String? ?? '',
        prescription: json['prescription'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
        billId: json['billId'] as String?,
        vitals: json['vitals'] != null
            ? Vitals.fromJson(json['vitals'] as Map<String, dynamic>)
            : null,
        medicines: json['medicines'] != null
            ? (json['medicines'] as List<dynamic>)
                .map((m) => PrescribedMedicine.fromJson(m as Map<String, dynamic>))
                .toList()
            : const [],
      );
}

class BillItem {
  final String id;
  final String description;
  final int quantity;
  final double unitPrice;

  BillItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        id: json['id'] as String,
        description: json['description'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );
}

class Bill {
  final String id;
  final String billNumber;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final DateTime date;
  final List<BillItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final String paymentStatus; // 'Paid', 'Pending'
  final String paymentMethod; // 'Cash', 'UPI', 'Card', 'NetBanking'

  Bill({
    required this.id,
    required this.billNumber,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.totalAmount,
    this.paymentStatus = 'Paid',
    this.paymentMethod = 'UPI',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'billNumber': billNumber,
        'patientId': patientId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'totalAmount': totalAmount,
        'paymentStatus': paymentStatus,
        'paymentMethod': paymentMethod,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        billNumber: json['billNumber'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String,
        patientPhone: json['patientPhone'] as String,
        date: DateTime.parse(json['date'] as String),
        items: (json['items'] as List<dynamic>)
            .map((i) => BillItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paymentStatus: json['paymentStatus'] as String? ?? 'Paid',
        paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
      );
}

