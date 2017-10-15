package util;

class Reduhx<State, Action> {
	public var state(default, null):State;
	public var reducers(null, set):Array<State->Action->State>;

	var reducer:State->Action->State;
	var currentListeners:Array<Void->Void>;
	var nextListeners:Array<Void->Void>;
	var isDispatching:Bool;

	public function new(reducerList:Array<State->Action->State>, ?initialState:State) {
		state = initialState;
		currentListeners = new Array<Void->Void>();
		nextListeners = currentListeners;
		isDispatching = false;
		reducers = reducerList;
	}

	inline function ensureCanMutate() if (nextListeners == currentListeners) nextListeners = currentListeners.slice(0);
	public function subscribe(listener:Void->Void) {
		var isSubscribed = true;
		ensureCanMutate();
		nextListeners.push(listener);

		return function unsubscribe()
		{
			if (!isSubscribed) return;
			isSubscribed = false;

			ensureCanMutate();
			var index = nextListeners.indexOf(listener);
			nextListeners.splice(index, 1);
		}
	}

	public function dispatch(action:Action) {
		if (isDispatching) throw 'recursive dispatch';

		try {
			isDispatching = true;
			state = reducer(state, action);
		}
		isDispatching = false;

		var listeners = currentListeners = nextListeners;
		for (i in 0...listeners.length) listeners[i]();
	}

	function set_reducers(newReducers:Array<State->Action->State>) {
		reducer = function (state:State, action)
		{
			var hasChanged = false;
			var nextState = null;
			for (i in 0...newReducers.length) {
				var reducer = newReducers[i];
				nextState = reducer(state, action);
				hasChanged = hasChanged || nextState != state;
			}
			return hasChanged ? nextState : state;
		};

		dispatch(null);
		return newReducers;
	}
}

