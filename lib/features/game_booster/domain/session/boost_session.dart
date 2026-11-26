import '../actions/boost_action.dart';
import '../../data/models/game_model.dart';

/// Manages an active gaming boost session.
/// Keeps a stack of applied actions and reverts them in REVERSE order upon completion or error.
class BoostSession {
  final Game game;
  final BoostContext context;

  // LIFO Stack of successfully applied actions
  final List<BoostAction> _appliedStack = [];

  bool _isActive = false;
  bool get isActive => _isActive;

  List<BoostAction> get appliedActions => List.unmodifiable(_appliedStack);

  BoostSession({
    required this.game,
    required this.context,
  });

  /// Applies all requested actions. If one fails, logs it and continues.
  Future<void> start(List<BoostAction> actions) async {
    _isActive = true;
    for (final action in actions) {
      try {
        await action.apply(context);
        _appliedStack.add(action);
      } catch (e) {
        // Architectural rule: One failure must not break the whole session.
        // Log, skip, and continue.
      }
    }
  }

  /// Reverts all applied actions in REVERSE order.
  Future<void> stop() async {
    if (!_isActive) return;

    // Pop and revert in reverse order (LIFO)
    while (_appliedStack.isNotEmpty) {
      final action = _appliedStack.removeLast();
      try {
        await action.revert(context);
      } catch (e) {
        // Continue reverting remaining actions even if one revert fails
      }
    }
    _isActive = false;
  }
}
