package;

interface Threshold {
	public var threshold(default, set):Float;
	public var callbacks(default, null):Array<Float->Float->Void>;
	public function precondition(before:Float, after:Float):Bool;
}

// Threshold that always triggers whenever it is crossed
class SimpleThreshold implements Threshold {
	public var callbacks(default, null):Array<Float->Float->Void>;
	public var threshold(default, set):Float;

	public function new(threshold:Float, ?callbacks:Array<Float->Float->Void>) {
		this.threshold = threshold;
		this.callbacks = callbacks;
	}
	
	public function precondition(before:Float, after:Float):Bool {
		return true;
	}
	
	public function set_threshold(threshold:Float):Float {
		return this.threshold = threshold;
	}
}

// This watches a value and dispatches signals when thresholds are crossed due to that value changing
class ThresholdTrigger<T:Threshold> {
	public var value(default, set):Float;
	private var thresholds = new Array<T>();

	public function new(initialValue:Float) {
		this.value = initialValue;
	}

	public function add(o:T):Void {
		if (thresholds.length == 0) {
			thresholds.push(o);
			return;
		}

		var idx = binarySearchNumeric(thresholds, o.threshold, 0, thresholds.length - 1, comp);
		if (idx < 0) {
			idx = ~idx;
		}

		thresholds.insert(idx, o);
	}

	private function comp(a:T, b:Float):Int {
		if (a.threshold < b) {
			return -1;
		}
		if (a.threshold > b) {
			return 1;
		}
		return 0;
	}

	private function set_value(v:Float):Float {
		if (v == this.value) {
			return this.value;
		}

		if (thresholds.length == 0) {
			return this.value = v;
		}

		var lower = binarySearchNumeric(thresholds, Math.min(v, this.value), 0, thresholds.length - 1, comp);
		var upper = binarySearchNumeric(thresholds, Math.max(v, this.value), 0, thresholds.length - 1, comp);
		if (lower < 0) {
			lower = ~lower;
		}
		if (upper < 0) {
			upper = ~upper;
		}

		for (i in lower...upper) {
			if (thresholds[i].precondition(this.value, v)) {
				if (thresholds[i].callbacks != null) {
					for (callback in thresholds[i].callbacks) {
						callback(this.value, v);
					}
				}
			}
		}

		return this.value = v;
	}
	
	// Returns the index of the element in the range min,max
	// NOTE requires a sorted, non-empty array
	// Returns the index of the element or, if one is not found, negative value of the index where the element would be inserted
	private static function binarySearchNumeric<T, V:Float>(a:Array<T>, x:V, min:Int, max:Int, comparator:T->V->Int):Int {
		var low:Int = min;
		var high:Int = max + 1;
		var middle:Int;

		while (low < high) {
			middle = low + ((high - low) >> 1);
			if (comparator(a[middle], x) < 0) {
				low = middle + 1;
			} else {
				high = middle;
			}
		}

		if (low <= max && comparator(a[low], x) == 0) {
			return low;
		} else {
			return ~low;
		}
	}
}