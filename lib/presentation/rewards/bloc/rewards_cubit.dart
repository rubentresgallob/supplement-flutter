import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../data/datasources/intakes_remote_datasource.dart';
import '../../../data/datasources/rewards_remote_datasource.dart';
import '../../../data/models/rewards_models.dart';

/// Algo que celebrar: premios nuevos y/o días de racha salvados por un protector.
class RewardsCelebration {
  final List<GrantedReward> rewards;
  final List<String> repairedDays;

  const RewardsCelebration({this.rewards = const [], this.repairedDays = const []});

  int get totalPoints => rewards.fold(0, (sum, r) => sum + r.points);
  bool get isEmpty => rewards.isEmpty && repairedDays.isEmpty;
}

class RewardsState extends Equatable {
  final RewardsSummary? summary;
  final List<ShopItem> items;
  final bool loading;

  /// Código del objeto que se está comprando/equipando (para el spinner).
  final String? busyCode;
  final String? error;

  const RewardsState({
    this.summary,
    this.items = const [],
    this.loading = false,
    this.busyCode,
    this.error,
  });

  int get points => summary?.points ?? 0;
  int get protectors => summary?.protectors ?? 0;
  Map<String, String> get equipped => summary?.equipped ?? const {};
  CapsuOutfit get outfit => CapsuOutfit.fromEquipped(equipped);

  ShopItem? item(String? code) {
    if (code == null) return null;
    for (final i in items) {
      if (i.code == code) return i;
    }
    return null;
  }

  RewardsState copyWith({
    RewardsSummary? summary,
    List<ShopItem>? items,
    bool? loading,
    String? busyCode,
    bool clearBusy = false,
    String? error,
    bool clearError = false,
  }) =>
      RewardsState(
        summary: summary ?? this.summary,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        busyCode: clearBusy ? null : (busyCode ?? this.busyCode),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [summary, items, loading, busyCode, error];
}

class RewardsCubit extends Cubit<RewardsState> {
  final RewardsRemoteDataSource _dataSource;
  StreamSubscription<List<GrantedReward>>? _intakeRewardsSub;
  final _celebrations = StreamController<RewardsCelebration>.broadcast();

  RewardsCubit(this._dataSource, IntakesRemoteDataSource intakes)
      : super(const RewardsState()) {
    // Premios ganados al registrar tomas → celebrar y actualizar saldo
    _intakeRewardsSub = intakes.rewards.listen((granted) {
      _celebrate(RewardsCelebration(rewards: granted));
      load();
    });
  }

  /// La UI escucha esto para mostrar a Capsu celebrando.
  Stream<RewardsCelebration> get celebrations => _celebrations.stream;

  Future<void> load() async {
    emit(state.copyWith(loading: state.summary == null, clearError: true));
    try {
      final results = await Future.wait([
        _dataSource.getSummary(),
        _dataSource.getShopItems(),
      ]);
      final summary = results[0] as RewardsSummary;
      emit(state.copyWith(
        summary: summary,
        items: results[1] as List<ShopItem>,
        loading: false,
      ));
      _celebrate(RewardsCelebration(
        rewards: summary.newRewards,
        repairedDays: summary.repairedDays,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: _message(e)));
    }
  }

  /// Compra un objeto. Devuelve null si va bien o el mensaje de error.
  Future<String?> buy(String code) async {
    emit(state.copyWith(busyCode: code));
    try {
      final granted = await _dataSource.buy(code);
      await load();
      _celebrate(RewardsCelebration(rewards: granted));
      return null;
    } catch (e) {
      return _message(e);
    } finally {
      emit(state.copyWith(clearBusy: true));
    }
  }

  Future<String?> toggleEquip(ShopItem item) async {
    emit(state.copyWith(busyCode: item.code));
    try {
      if (item.equipped) {
        await _dataSource.unequip(item.code);
      } else {
        await _dataSource.equip(item.code);
      }
      await load();
      return null;
    } catch (e) {
      return _message(e);
    } finally {
      emit(state.copyWith(clearBusy: true));
    }
  }

  /// Al cerrar sesión, que el siguiente usuario no vea los datos del anterior.
  void reset() => emit(const RewardsState());

  void _celebrate(RewardsCelebration c) {
    if (!c.isEmpty) _celebrations.add(c);
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  Future<void> close() {
    _intakeRewardsSub?.cancel();
    _celebrations.close();
    return super.close();
  }
}
