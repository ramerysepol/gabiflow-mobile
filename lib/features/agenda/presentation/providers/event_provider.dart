import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_providers.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/datasources/google_agenda_datasource.dart';
import '../../data/models/event_model.dart';

// ── DataSource ──────────────────────────────────────────────────────────────

final eventDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  return EventRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

// ─── Google Calendar ─────────────────────────────────────────────────────────

final googleAgendaDatasourceProvider = Provider<GoogleAgendaDatasource>((ref) {
  return GoogleAgendaDatasource(ref.watch(apiClientProvider));
});

/// Status da conexão com o Google Calendar (conectado, última sync, erro).
final googleAgendaStatusProvider =
    FutureProvider.autoDispose<GoogleAgendaStatus>((ref) {
  return ref.watch(googleAgendaDatasourceProvider).status();
});

// ── Lista mensal ─────────────────────────────────────────────────────────────

class EventListState {
  final List<EventModel> items;
  final bool isLoading;
  final String? error;
  final DateTime focusedMonth;

  const EventListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    required this.focusedMonth,
  });

  EventListState copyWith({
    List<EventModel>? items,
    bool? isLoading,
    String? error,
    DateTime? focusedMonth,
  }) =>
      EventListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        focusedMonth: focusedMonth ?? this.focusedMonth,
      );

  /// Retorna eventos do mês atual agrupados por data (yyyy-MM-dd).
  Map<DateTime, List<EventModel>> get eventsByDay {
    final map = <DateTime, List<EventModel>>{};
    for (final e in items) {
      final dt = _parseDate(e.startDate);
      if (dt == null) continue;
      final key = DateTime(dt.year, dt.month, dt.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  List<EventModel> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return eventsByDay[key] ?? [];
  }
}

DateTime? _parseDate(String? s) {
  if (s == null) return null;
  try {
    // A API manda UTC ("...Z"); agrupar sem converter jogava o evento das
    // 22h no dia seguinte do calendario.
    return DateTime.parse(s).toLocal();
  } catch (_) {
    return null;
  }
}

class EventListNotifier extends StateNotifier<EventListState> {
  final EventRemoteDataSource _ds;

  EventListNotifier(this._ds)
      : super(EventListState(focusedMonth: DateTime.now())) {
    fetchMonth(DateTime.now());
  }

  Future<void> fetchMonth(DateTime month) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);
      final result = await _ds.getEvents(
        startDate:
            '${start.year}-${_pad(start.month)}-${_pad(start.day)}',
        endDate: '${end.year}-${_pad(end.month)}-${_pad(end.day)}',
      );
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        focusedMonth: month,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => fetchMonth(state.focusedMonth);

  String _pad(int n) => n.toString().padLeft(2, '0');
}

final eventListProvider =
    StateNotifierProvider<EventListNotifier, EventListState>((ref) {
  return EventListNotifier(ref.watch(eventDataSourceProvider));
});

// ── Detalhe ──────────────────────────────────────────────────────────────────

final eventDetailProvider =
    FutureProvider.family<EventModel, String>((ref, id) async {
  return ref.watch(eventDataSourceProvider).getEventById(id);
});

// ── Formulário ───────────────────────────────────────────────────────────────

class EventFormState {
  final bool isLoading;
  final String? error;
  final bool success;

  const EventFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  EventFormState copyWith({bool? isLoading, String? error, bool? success}) =>
      EventFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class EventFormNotifier extends StateNotifier<EventFormState> {
  final EventRemoteDataSource _ds;

  EventFormNotifier(this._ds) : super(const EventFormState());

  Future<EventModel?> save(
      Map<String, dynamic> body, String? existingId) async {
    state = const EventFormState(isLoading: true);
    try {
      final result = existingId != null
          ? await _ds.updateEvent(existingId, body)
          : await _ds.createEvent(body);
      state = const EventFormState(success: true);
      return result;
    } catch (e) {
      state = EventFormState(error: e.toString());
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = const EventFormState(isLoading: true);
    try {
      await _ds.deleteEvent(id);
      state = const EventFormState(success: true);
      return true;
    } catch (e) {
      state = EventFormState(error: e.toString());
      return false;
    }
  }
}

final eventFormProvider =
    StateNotifierProvider.autoDispose<EventFormNotifier, EventFormState>((ref) {
  return EventFormNotifier(ref.watch(eventDataSourceProvider));
});
