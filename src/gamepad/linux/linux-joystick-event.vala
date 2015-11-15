// This file is part of GNOME Games. License: GPLv3

private class Games.LinuxJoystickEvent: Object {
	public uint32 time;
	public InputType type;
	public bool init;
	public uint8 number;
	public int16 value;
	public LinuxJoystick joystick;
}
