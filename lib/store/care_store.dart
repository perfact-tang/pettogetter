import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import '../services/care_service.dart';
import '../utils/care_calendar.dart';
import '../utils/extensions.dart';
import '../utils/id.dart';

/// Shared application state and actions, ported from `CareStore.swift`.
/// Exposes a [ChangeNotifier] that Flutter widgets rebuild from.
class CareStore extends ChangeNotifier {
  CareStore(this._service);

  final CareService _service;

  Household? _household;
  Caregiver? _currentCaregiver;
  List<CareTask> _tasks = [];
  List<Caregiver> _caregivers = [];
  List<CareRoutine> _routines = [];

  String? _errorMessage;
  bool _isLoading = false;
  bool _isRestoringSession = true;
  bool _isSavingTask = false;
  bool _isSavingProfile = false;
  Set<String> _mutatingTaskIDs = {};
  Uint8List? _petPhotoData;

  int _sessionRequestGeneration = 0;
  bool _didAttemptSessionRestore = false;

  // -------------------------------------------------------------------------
  // Getters
  // -------------------------------------------------------------------------

  Household? get household => _household;
  Caregiver? get currentCaregiver => _currentCaregiver;
  List<CareTask> get tasks => _tasks;
  List<Caregiver> get caregivers => _caregivers;
  List<CareRoutine> get routines => _routines;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRestoringSession => _isRestoringSession;
  bool get isSavingTask => _isSavingTask;
  bool get isSavingProfile => _isSavingProfile;
  Set<String> get mutatingTaskIDs => _mutatingTaskIDs;
  Uint8List? get petPhotoData => _petPhotoData;

  Caregiver? get partnerCaregiver {
    final current = _currentCaregiver;
    if (current == null) return null;
    return _caregivers.where((c) => c.id != current.id).firstOrNull;
  }

  List<CareTask> get todayTasks => tasksOn(DateTime.now());
  List<CareTask> get unclaimedTasks => unclaimedTasksOn(DateTime.now());
  List<CareTask> get claimedTasks => claimedTasksOn(DateTime.now());
  List<CareTask> get completedTasks => completedTasksOn(DateTime.now());

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Task expansion (mirrors CareStore.tasks(on:))
  // -------------------------------------------------------------------------

  List<CareTask> tasksOn(DateTime date) {
    final household = _household;
    if (household == null) return const [];

    final selectedDay = startOfDay(date);
    final nextDay = selectedDay.add(const Duration(days: 1));
    final persistedForDay = _tasks
        .where((t) => !t.dueTime.isBefore(selectedDay) && t.dueTime.isBefore(nextDay))
        .toList();
    final overridesByID = {for (final t in persistedForDay) t.id: t};

    final result = <CareTask>[];
    final includedIDs = <String>{};

    for (final routine in _routines.where((r) => r.isActive)) {
      final routineStartDay = startOfDay(routine.startDate);
      final runs = routine.frequency == CareRoutineFrequency.daily ||
          routine.weekdays.contains(swiftWeekday(selectedDay));
      if (selectedDay.isBefore(routineStartDay) || !runs) continue;

      final due = dueTimeForRoutine(routine, selectedDay);
      if (due == null || !due.isBefore(nextDay)) continue;

      final taskID = occurrenceID(routine, selectedDay);
      final occurrence = overridesByID[taskID] ??
          CareTask(
            id: taskID,
            title: routine.title,
            category: routine.category,
            dueTime: due,
            kind: CareTaskKind.routine,
            priority: routine.priority,
            routineID: routine.id,
            status: CareTaskStatus.unclaimed,
            createdByID: routine.createdByID,
            createdBy: routine.createdByNameSnapshot,
            createdAt: routine.startDate,
          );
      result.add(occurrence);
      includedIDs.add(taskID);
    }

    for (final task in persistedForDay) {
      if (!includedIDs.contains(task.id)) {
        result.add(task);
        includedIDs.add(task.id);
      }
    }

    result.sort((a, b) {
      final byTime = a.dueTime.compareTo(b.dueTime);
      if (byTime != 0) return byTime;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return result;
  }

  List<CareTask> unclaimedTasksOn(DateTime date) =>
      tasksOn(date).where((t) => t.status == CareTaskStatus.unclaimed).toList();

  List<CareTask> claimedTasksOn(DateTime date) =>
      tasksOn(date).where((t) => t.status == CareTaskStatus.claimed).toList();

  List<CareTask> completedTasksOn(DateTime date) {
    final completed = tasksOn(date)
        .where((t) => t.status == CareTaskStatus.completed)
        .toList();
    completed.sort((a, b) => (b.completedAt ?? b.dueTime)
        .compareTo(a.completedAt ?? a.dueTime));
    return completed;
  }

  // -------------------------------------------------------------------------
  // Session
  // -------------------------------------------------------------------------

  Future<void> restoreSession() async {
    if (_didAttemptSessionRestore) return;
    _didAttemptSessionRestore = true;
    await _restoreSessionIfAvailable();
  }

  Future<void> createHousehold({
    required String name,
    required String petName,
    required String caregiverName,
  }) async {
    if (_isLoading) return;
    _sessionRequestGeneration++;
    final generation = _sessionRequestGeneration;
    _isLoading = true;
    notifyListeners();

    await _performSessionRequest(generation, () => _service.createHousehold(
          name: name,
          petName: petName,
          caregiverName: caregiverName,
        ));
  }

  Future<void> joinHousehold({
    required String inviteCode,
    required String caregiverName,
  }) async {
    if (_isLoading) return;
    _sessionRequestGeneration++;
    final generation = _sessionRequestGeneration;
    _isLoading = true;
    notifyListeners();

    await _performSessionRequest(generation, () => _service.joinHousehold(
          inviteCode: inviteCode,
          caregiverName: caregiverName,
        ));
  }

  // -------------------------------------------------------------------------
  // Adds
  // -------------------------------------------------------------------------

  Future<bool> addTask({
    required String title,
    required CareCategory category,
    required CareTaskKind kind,
    required CarePriority priority,
    required DateTime date,
    CareRoutineFrequency frequency = CareRoutineFrequency.daily,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    if (household == null || currentCaregiver == null || _isSavingTask) {
      return false;
    }

    final generation = _sessionRequestGeneration;
    _isSavingTask = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (kind) {
        case CareTaskKind.oneOff:
          final task = CareTask(
            id: uuid(),
            title: title,
            category: category,
            dueTime: date,
            kind: CareTaskKind.oneOff,
            priority: priority,
            status: CareTaskStatus.unclaimed,
            createdByID: currentCaregiver.id,
            createdBy: currentCaregiver.displayName,
            createdAt: DateTime.now(),
          );
          await _service.addTask(task, household.id);
        case CareTaskKind.routine:
          final routine = CareRoutine(
            id: uuid(),
            title: title,
            category: category,
            priority: priority,
            frequency: frequency,
            weekdays: weekdays,
            hour: date.hour,
            minute: date.minute,
            startDate: startOfDay(date),
            timeZoneIdentifier: household.timeZoneIdentifier,
            createdByID: currentCaregiver.id,
            createdByNameSnapshot: currentCaregiver.displayName,
          );
          await _service.addRoutine(routine, household.id);
      }
      return generation == _sessionRequestGeneration;
    } catch (error) {
      if (generation != _sessionRequestGeneration) return false;
      _errorMessage = _describe(error);
      return false;
    } finally {
      _isSavingTask = false;
      notifyListeners();
    }
  }

  Future<bool> addOneOffTask({
    required String title,
    required CareCategory category,
    required DateTime dueTime,
  }) {
    return addTask(
      title: title,
      category: category,
      kind: CareTaskKind.oneOff,
      priority: CarePriority.normal,
      date: dueTime,
    );
  }

  // -------------------------------------------------------------------------
  // Profile
  // -------------------------------------------------------------------------

  Future<bool> updateProfile({
    required String caregiverName,
    required String householdName,
    required String petName,
  }) async {
    final existingHousehold = _household;
    final existingCaregiver = _currentCaregiver;
    if (existingHousehold == null || existingCaregiver == null || _isSavingProfile) {
      return false;
    }

    final caregiver = caregiverName.trim();
    final household = householdName.trim();
    final pet = petName.trim();
    if (caregiver.isEmpty ||
        caregiver.length > 50 ||
        household.isEmpty ||
        household.length > 60 ||
        pet.isEmpty ||
        pet.length > 60) {
      _errorMessage = const CareServiceError(
              CareServiceErrorType.invalidProfile)
          .message;
      notifyListeners();
      return false;
    }

    final updatedHousehold =
        existingHousehold.copyWith(name: household, petName: pet);
    final updatedCaregiver = existingCaregiver.copyWith(displayName: caregiver);

    final generation = _sessionRequestGeneration;
    _isSavingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateProfile(updatedHousehold, updatedCaregiver);
      if (generation != _sessionRequestGeneration) return false;
      _household = updatedHousehold;
      _currentCaregiver = updatedCaregiver;
      _caregivers = [
        for (final c in _caregivers)
          c.id == updatedCaregiver.id ? updatedCaregiver : c,
      ];
      return true;
    } catch (error) {
      if (generation != _sessionRequestGeneration) return false;
      _errorMessage = _describe(error);
      return false;
    } finally {
      _isSavingProfile = false;
      notifyListeners();
    }
  }

  Future<void> savePetPhoto(Uint8List? data) async {
    final household = _household;
    if (household == null) return;
    final file = await _petPhotoFile(household.id);

    if (data == null) {
      if (await file.exists()) await file.delete();
    } else {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data, flush: true);
    }
    _petPhotoData = data;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Task actions
  // -------------------------------------------------------------------------

  Future<bool> claim(CareTask task) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    if (household == null || currentCaregiver == null) return false;
    return _performTaskMutation(task.id, () => _service.claimTask(
          task,
          household.id,
          currentCaregiver,
        ));
  }

  Future<bool> request(CareTask task, Caregiver requestedCaregiver) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    if (household == null || currentCaregiver == null) return false;
    return _performTaskMutation(task.id, () => _service.requestAssignment(
          task,
          household.id,
          currentCaregiver,
          requestedCaregiver,
        ));
  }

  Future<bool> requestPartner(CareTask task) async {
    final partner = partnerCaregiver;
    if (partner == null) {
      _errorMessage = const CareServiceError(
              CareServiceErrorType.caregiverNotFound)
          .message;
      notifyListeners();
      return false;
    }
    return request(task, partner);
  }

  Future<bool> requestAnyone(CareTask task) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    if (household == null || currentCaregiver == null) return false;
    return _performTaskMutation(task.id, () => _service.requestOpenAssignment(
          task,
          household.id,
          currentCaregiver,
        ));
  }

  Future<bool> acceptRequest(CareTask task) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    final request = task.assignmentRequest;
    if (household == null || currentCaregiver == null || request == null) {
      return false;
    }
    return _performTaskMutation(task.id, () => _service.acceptAssignmentRequest(
          task.id,
          request.id,
          household.id,
          currentCaregiver,
        ));
  }

  Future<bool> declineRequest(CareTask task) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    final request = task.assignmentRequest;
    if (household == null || currentCaregiver == null || request == null) {
      return false;
    }
    return _performTaskMutation(task.id, () => _service.declineAssignmentRequest(
          task.id,
          request.id,
          household.id,
          currentCaregiver,
        ));
  }

  Future<bool> cancelRequest(CareTask task) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    final request = task.assignmentRequest;
    if (household == null || currentCaregiver == null || request == null) {
      return false;
    }
    return _performTaskMutation(task.id, () => _service.cancelAssignmentRequest(
          task.id,
          request.id,
          household.id,
          currentCaregiver,
        ));
  }

  Future<bool> complete(CareTask task) async {
    final household = _household;
    final currentCaregiver = _currentCaregiver;
    if (household == null || currentCaregiver == null) return false;
    return _performTaskMutation(task.id, () => _service.completeTask(
          task.id,
          household.id,
          currentCaregiver,
        ));
  }

  void leaveHousehold() {
    _sessionRequestGeneration++;
    _service.leaveHousehold();
    _household = null;
    _currentCaregiver = null;
    _tasks = [];
    _caregivers = [];
    _routines = [];
    _mutatingTaskIDs = {};
    _petPhotoData = null;
    _isLoading = false;
    _isSavingTask = false;
    _isSavingProfile = false;
    _errorMessage = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  Future<bool> _performTaskMutation(
    String taskID,
    Future<void> Function() mutation,
  ) async {
    if (_mutatingTaskIDs.contains(taskID)) return false;
    final generation = _sessionRequestGeneration;
    _mutatingTaskIDs = {..._mutatingTaskIDs, taskID};
    _errorMessage = null;
    notifyListeners();

    try {
      await mutation();
      return generation == _sessionRequestGeneration;
    } catch (error) {
      if (generation != _sessionRequestGeneration) return false;
      _errorMessage = _describe(error);
      return false;
    } finally {
      _mutatingTaskIDs = {..._mutatingTaskIDs}..remove(taskID);
      notifyListeners();
    }
  }

  Future<void> _performSessionRequest(
    int generation,
    Future<CareSession> Function() request,
  ) async {
    _errorMessage = null;
    try {
      final session = await request();
      if (generation != _sessionRequestGeneration) return;
      _household = session.household;
      _currentCaregiver = session.caregiver;
      await _loadPetPhoto(session.household.id);
      _observeDomain(session);
    } catch (error) {
      if (generation != _sessionRequestGeneration) return;
      _errorMessage = _describe(error);
    } finally {
      if (generation == _sessionRequestGeneration) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> _restoreSessionIfAvailable() async {
    final generation = _sessionRequestGeneration;
    try {
      final session = await _service.restoreSession();
      if (generation != _sessionRequestGeneration) return;
      if (session == null) return;
      _household = session.household;
      _currentCaregiver = session.caregiver;
      await _loadPetPhoto(session.household.id);
      _observeDomain(session);
    } catch (error) {
      if (generation != _sessionRequestGeneration) return;
      _errorMessage = _describe(error);
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  void _observeDomain(CareSession session) {
    _service.stopObserving();
    _service.observeHousehold(
      householdID: session.household.id,
      onChange: (household) {
        _household = household;
        notifyListeners();
      },
      onError: (error) => _setError(error),
    );
    _service.observeTasks(
      householdID: session.household.id,
      onChange: (tasks) {
        _tasks = tasks;
        notifyListeners();
      },
      onError: (error) => _setError(error),
    );
    _service.observeCaregivers(
      householdID: session.household.id,
      onChange: (caregivers) {
        _caregivers = caregivers;
        final currentID = _currentCaregiver?.id;
        if (currentID != null) {
          final updated = caregivers.where((c) => c.id == currentID).firstOrNull;
          if (updated != null) _currentCaregiver = updated;
        }
        notifyListeners();
      },
      onError: (error) => _setError(error),
    );
    _service.observeRoutines(
      householdID: session.household.id,
      onChange: (routines) {
        _routines = routines;
        notifyListeners();
      },
      onError: (error) => _setError(error),
    );
  }

  void _setError(Object error) {
    _errorMessage = _describe(error);
    notifyListeners();
  }

  String _describe(Object error) {
    if (error is CareServiceError) return error.message;
    return error.toString();
  }

  // -------------------------------------------------------------------------
  // Pet photo persistence
  // -------------------------------------------------------------------------

  Future<File> _petPhotoFile(String householdID) async {
    final directory = await getApplicationSupportDirectory();
    final safeID = base64UrlEncode(utf8.encode(householdID)).replaceAll('=', '');
    return File('${directory.path}/PetPhotos/$safeID.jpg');
  }

  Future<void> _loadPetPhoto(String householdID) async {
    try {
      final file = await _petPhotoFile(householdID);
      if (await file.exists()) {
        _petPhotoData = await file.readAsBytes();
      } else {
        _petPhotoData = null;
      }
    } catch (_) {
      _petPhotoData = null;
    }
    notifyListeners();
  }
}
