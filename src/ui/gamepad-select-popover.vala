// This file is part of GNOME Games. License: GPLv3
private enum Games.GamepadSelectPopoverState {
	CHOSE_PLAYER,
	CHOSE_GAMEPAD,
}

[GtkTemplate (ui = "/org/gnome/Games/ui/gamepad-select-popover.ui")]
private class Games.GamepadSelectPopover : Gtk.Popover {
	[GtkChild]
	private Gtk.ListBox player_list;
	[GtkChild]
	private Gtk.ListBox gamepad_list;
	[GtkChild]
	private Gtk.Stack popover_stack;

	public string[] gamepads;
	public int[] associations;

	private GamepadSelectPopoverState state = GamepadSelectPopoverState.CHOSE_PLAYER;
	private int active_player = -1;

	public GamepadSelectPopover (string[] gamepad_c, int[] association_c) {
		gamepads = gamepad_c;
		associations = association_c;

		this.destroy.connect (() => {
			print (@"\n\nAssociations : $(associations.length)\n");
			for (var i = 0; i < associations.length; i++)
				print (@"Player $(i+1) - $(associations[i]) - $(gamepads[associations[i]])\n");
		});

		foreach (var gamepad in gamepads)
			gamepad_list.add (new Gtk.Label (gamepad));

		for (var i = 0; i < associations.length; i++) {
			player_list.add (new Gtk.Label (""));
			update_player_string (i);
		}

		player_list.row_activated.connect ((row) => {
			var player = row.get_index ();
			change_state (GamepadSelectPopoverState.CHOSE_GAMEPAD, player);
		});

		gamepad_list.row_selected.connect (() => change_state (GamepadSelectPopoverState.CHOSE_PLAYER));
		player_list.show_all ();
		gamepad_list.show_all ();
	}

	private void update_player_string (int player) {
		var label = (Gtk.Label) player_list.get_row_at_index (player).get_child ();
		label.label = @"#$(player+1) - $(gamepads[associations[player]])";
	}

	private void change_state (GamepadSelectPopoverState to, int player = -1) {
		if (to == state) return;
		switch (to) {
		case GamepadSelectPopoverState.CHOSE_PLAYER:
			var associate_to = gamepad_list.get_selected_row ().get_index ();
			print (@"Row changed $active_player - $associate_to!\n");
			int other_player = -1;
			for (var i = 0; i < associations.length; i++) {
				if (associations[i] == associate_to) {
					other_player = i;

					break;
				}
			}
			if (other_player != -1)
				associations[other_player] = associations[active_player];
			associations[active_player] = associate_to;
			update_player_string (active_player);
			update_player_string (other_player);
			popover_stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
			popover_stack.set_visible_child (player_list);

			break;
		case GamepadSelectPopoverState.CHOSE_GAMEPAD:
			gamepad_list.select_row (gamepad_list.get_row_at_index (associations[player]));
			popover_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
			popover_stack.set_visible_child (gamepad_list);

			break;
		}
		state = to;
		active_player = player;
	}
}
