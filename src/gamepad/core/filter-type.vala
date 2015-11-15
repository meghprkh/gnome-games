// This file is part of GNOME Games. License: GPLv3

private enum Games.FilterType {
	NONE,
	POSITIVE,
	NEGATIVE;

	public double apply (double value) {
		switch (this) {
		case FilterType.NONE:
			return value;
		case FilterType.POSITIVE:
			return value < 0.0 ? 0.0 : value;
		case FilterType.NEGATIVE:
			return value > 0.0 ? 0.0 : -value;
		default:
			return value;
		}
	}
}
