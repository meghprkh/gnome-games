// This file is part of GNOME Games. License: GPLv3

public interface Games.Game : Object {
	public abstract string name { get; }
	public abstract Icon? icon { get; }

	public abstract Runner get_runner () throws Error;
}
