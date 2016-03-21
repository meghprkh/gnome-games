// This file is part of GNOME Games. License: GPLv3

public interface Games.Runner : Object {
	public signal void stopped ();

	public abstract bool can_resume { get; }

	public abstract Gtk.Widget get_display ();
	public abstract void start () throws Error;
	public abstract void resume () throws Error;
	public abstract void load_from_store (int index) throws Error;
	public abstract void save_to_store (int index) throws Error;
	public abstract void pause ();
}
