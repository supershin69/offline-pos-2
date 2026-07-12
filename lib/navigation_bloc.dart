import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NavigationEvent {}

// events
class TabChanged extends NavigationEvent {
  final int index;
  TabChanged(this.index);
}

// states
class NavigationState {
  final int selectedIndex;
  NavigationState(this.selectedIndex);
}

// bloc

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationState(0)) {
    on<TabChanged>((event, emit) => emit(NavigationState(event.index)));
  }
}
