// This file is part of GNOME Games. License: GPLv3

public interface Games.TrackerQuery : Object {
	public abstract string get_query ();
	public abstract Game game_for_cursor (Tracker.Sparql.Cursor cursor) throws Error;
}
