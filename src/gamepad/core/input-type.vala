// This file is part of GNOME Games. License: GPLv3

private enum Games.InputType {
	AXIS,
	BUTTON;

	public static uint length () {
		return InputType.BUTTON + 1;
	}
}
