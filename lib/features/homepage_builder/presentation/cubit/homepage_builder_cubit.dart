import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/homepage_builder_entities.dart';
import '../../domain/usecases/homepage_builder_usecases.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class HomepageBuilderState extends Equatable {
  const HomepageBuilderState();
  @override
  List<Object?> get props => [];
}

class HomepageBuilderInitial extends HomepageBuilderState {
  const HomepageBuilderInitial();
}

class HomepageBuilderLoading extends HomepageBuilderState {
  const HomepageBuilderLoading();
}

class HomepageBuilderLoaded extends HomepageBuilderState {
  final List<HomepageSection> sections;
  final String? selectedId;
  final bool isSaving;
  final bool savedBriefly;

  const HomepageBuilderLoaded({
    required this.sections,
    this.selectedId,
    this.isSaving = false,
    this.savedBriefly = false,
  });

  HomepageSection? get selected =>
      sections.where((s) => s.id == selectedId).firstOrNull;

  HomepageBuilderLoaded copyWith({
    List<HomepageSection>? sections,
    Object? selectedId = _sentinel,
    bool? isSaving,
    bool? savedBriefly,
  }) =>
      HomepageBuilderLoaded(
        sections:     sections ?? this.sections,
        selectedId:   selectedId == _sentinel ? this.selectedId : selectedId as String?,
        isSaving:     isSaving ?? this.isSaving,
        savedBriefly: savedBriefly ?? this.savedBriefly,
      );

  @override
  List<Object?> get props => [sections, selectedId, isSaving, savedBriefly];
}

class HomepageBuilderError extends HomepageBuilderState {
  final String message;
  const HomepageBuilderError(this.message);
  @override
  List<Object?> get props => [message];
}

const _sentinel = Object();

// ── Cubit ─────────────────────────────────────────────────────────────────────

class HomepageBuilderCubit extends Cubit<HomepageBuilderState> {
  final GetHomepageLayoutUseCase _getLayout;
  final SaveHomepageLayoutUseCase _saveLayout;

  HomepageBuilderCubit({
    required GetHomepageLayoutUseCase getLayout,
    required SaveHomepageLayoutUseCase saveLayout,
  })  : _getLayout = getLayout,
        _saveLayout = saveLayout,
        super(const HomepageBuilderInitial());

  Future<void> load() async {
    emit(const HomepageBuilderLoading());
    final result = await _getLayout();
    if (isClosed) return;
    result.fold(
      (f) => emit(HomepageBuilderError(f.message)),
      (sections) => emit(HomepageBuilderLoaded(sections: sections)),
    );
  }

  void selectSection(String? id) {
    final s = state;
    if (s is HomepageBuilderLoaded) {
      emit(s.copyWith(selectedId: id));
    }
  }

  void addSection(SectionType type) {
    final s = state;
    if (s is! HomepageBuilderLoaded) return;
    final newId = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
    final section = HomepageSection(
      id:       newId,
      type:     type,
      settings: defaultSettings(type),
    );
    emit(s.copyWith(
      sections:   [...s.sections, section],
      selectedId: newId,
    ));
  }

  void deleteSection(String id) {
    final s = state;
    if (s is! HomepageBuilderLoaded) return;
    final newSections = s.sections.where((sec) => sec.id != id).toList();
    emit(s.copyWith(
      sections:   newSections,
      selectedId: s.selectedId == id ? null : s.selectedId,
    ));
  }

  void moveUp(String id) {
    final s = state;
    if (s is! HomepageBuilderLoaded) return;
    final idx = s.sections.indexWhere((sec) => sec.id == id);
    if (idx <= 0) return;
    final list = [...s.sections];
    final tmp = list[idx - 1];
    list[idx - 1] = list[idx];
    list[idx] = tmp;
    emit(s.copyWith(sections: list));
  }

  void moveDown(String id) {
    final s = state;
    if (s is! HomepageBuilderLoaded) return;
    final idx = s.sections.indexWhere((sec) => sec.id == id);
    if (idx < 0 || idx >= s.sections.length - 1) return;
    final list = [...s.sections];
    final tmp = list[idx + 1];
    list[idx + 1] = list[idx];
    list[idx] = tmp;
    emit(s.copyWith(sections: list));
  }

  void patchSettings(String id, Map<String, dynamic> patch) {
    final s = state;
    if (s is! HomepageBuilderLoaded) return;
    final updated = s.sections.map((sec) {
      if (sec.id != id) return sec;
      return sec.copyWith(settings: {...sec.settings, ...patch});
    }).toList();
    emit(s.copyWith(sections: updated));
  }

  Future<bool> save() async {
    final s = state;
    if (s is! HomepageBuilderLoaded) return false;
    emit(s.copyWith(isSaving: true, savedBriefly: false));
    final result = await _saveLayout(s.sections);
    if (isClosed) return false;
    return result.fold(
      (f) {
        if (state is HomepageBuilderLoaded) {
          emit((state as HomepageBuilderLoaded).copyWith(isSaving: false));
        }
        return false;
      },
      (_) {
        if (state is HomepageBuilderLoaded) {
          emit((state as HomepageBuilderLoaded)
              .copyWith(isSaving: false, savedBriefly: true));
          Future.delayed(const Duration(seconds: 2), () {
            if (!isClosed && state is HomepageBuilderLoaded) {
              emit((state as HomepageBuilderLoaded).copyWith(savedBriefly: false));
            }
          });
        }
        return true;
      },
    );
  }
}
