module common.util;

//TODO: why is this not in standard library?
size_t indexOf(T)(T[] array, T needle) {
	foreach(i, a; array) {
		if (a == needle) {
			return i;
		}
	}
	return -1;
}


int max(int[] array) {
	int m = array[0];
	foreach(i; array[1..$]) {
		if (i > m) {
			m = i;
		}
	}
	return m;
}
