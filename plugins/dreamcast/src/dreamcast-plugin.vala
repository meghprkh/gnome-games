// This file is part of GNOME Games. License: GPLv3

private class Games.DreamcastPlugin : Object, Plugin {
	private const string MIME_TYPE = "application/x-dc-rom";
	private const string MODULE_BASENAME = "libretro-dreamcast.so";
	private const bool SUPPORTS_SNAPSHOTTING = false;

	public GameSource get_game_source () throws Error {
		var query = new MimeTypeTrackerQuery (MIME_TYPE, game_for_uri);
		var connection = Tracker.Sparql.Connection.@get ();
		var source = new TrackerGameSource (connection);
		source.add_query (query);

		return source;
	}

	private static Game game_for_uri (string uri) throws Error {
		var file = File.new_for_uri (uri);
		var header = new DreamcastHeader (file);
		header.check_validity ();

		var uid = new DreamcastUid (header);
		var title = new FilenameTitle (uri);
		var icon = new DummyIcon ();
		var media = new GriloMedia (title, MIME_TYPE);
		var cover = new GriloCover (media, uid);
		var runner = new RetroRunner.with_mime_types (uri, uid, { MIME_TYPE }, MODULE_BASENAME, SUPPORTS_SNAPSHOTTING);

		return new GenericGame (title, icon, cover, runner);
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof(Games.DreamcastPlugin);
}
