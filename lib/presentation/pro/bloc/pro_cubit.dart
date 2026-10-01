import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/pro_remote_datasource.dart';
import '../../../data/models/pro_models.dart';

class ProState extends Equatable {
  final ProStatus status;
  final bool loading;
  final String? error;

  const ProState({this.status = ProStatus.free, this.loading = false, this.error});

  bool get isPro => status.isPro;

  @override
  List<Object?> get props => [status, loading, error];
}

/// Estado del plan Pro, compartido por toda la app.
class ProCubit extends Cubit<ProState> {
  final ProRemoteDataSource _dataSource;

  ProCubit(this._dataSource) : super(const ProState());

  Future<void> load() async {
    try {
      emit(ProState(status: await _dataSource.getStatus()));
    } catch (e) {
      // Si falla, se queda como estaba (por defecto, plan gratis)
      emit(ProState(status: state.status, error: e.toString()));
    }
  }

  /// Activa Pro (de momento, modo de prueba). Devuelve null si va bien o el error.
  Future<String?> activate() => _run(_dataSource.activateTest);

  Future<String?> deactivate() => _run(_dataSource.deactivateTest);

  Future<String?> _run(Future<ProStatus> Function() action) async {
    emit(ProState(status: state.status, loading: true));
    try {
      emit(ProState(status: await action()));
      return null;
    } catch (e) {
      emit(ProState(status: state.status));
      return e.toString();
    }
  }

  void reset() => emit(const ProState());
}
