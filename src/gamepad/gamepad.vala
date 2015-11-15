// This file is part of GNOME Games. License: GPLv3

private interface Games.Gamepad: Object {
	public abstract string id { get; }
	public abstract long index { get; }
	public abstract bool connected { get; }
	public abstract time_t timestamp { get; }
	public abstract GamepadMappingType mapping_type { get; }
	public abstract double[] axes { get; }
	public abstract GamepadButton[] buttons { get; }
}
