// This file is part of GNOME Games. License: GPLv3

private class Games.GamepadEvent : Object {
	public GamepadAxisEvent axis_event;
	public GamepadButtonEvent button_event;
}

private class Games.GamepadAxisEvent: Object {
	public uint32 time;
	public uint8 axis;
	public double value;
	public Gamepad gamepad;
}

private class Games.GamepadButtonEvent: Object {
	public uint32 time;
	public uint8 button;
	public GamepadButton value;
	public Gamepad gamepad;
}
