// This file is part of GNOME Games. License: GPLv3
private enum Games.GamepadSelectPopoverState {
	CHOSE_PLAYER,
	CHOSE_GAMEPAD,
}

[GtkTemplate (ui = "/org/gnome/Games/ui/gamepad-select-popover.ui")]
private class Games.GamepadSelectPopover : Gtk.Popover {
	[GtkChild]
	private Gtk.ListBox list_box1;
	[GtkChild]
	private Gtk.ListBox list_box2;
	[GtkChild]
	private Gtk.Stack stack;

	public string[] gamepads;
	public int[] associations;

	private GamepadSelectPopoverState state = GamepadSelectPopoverState.CHOSE_PLAYER;
	private int active_player = -1;

	public GamepadSelectPopover (string[] gamepad_c, int[] association_c) {
		gamepads = gamepad_c;
		associations = association_c;

		this.destroy.connect(() => {
			print(@"\n\nAssociations : $(associations.length)\n");
			for (var i = 0; i < associations.length; i++) {
				print(@"Player $(i+1) - $(associations[i]) - $(gamepads[associations[i]])\n");
			}
		});

		foreach (var gamepad in gamepads) {
			list_box2.add(new Gtk.Label(gamepad));
		}

		for (var i = 0; i < associations.length; i++) {
			var button = new Gtk.Button.with_label(get_player_string(i));
			var i_copy = i;
			button.clicked.connect(() => change_state(GamepadSelectPopoverState.CHOSE_GAMEPAD, i_copy));
			list_box1.add(new Gtk.Label(get_player_string(i)));
		}

		list_box1.row_activated.connect((row) => {
			var player = row.get_index();
			change_state(GamepadSelectPopoverState.CHOSE_GAMEPAD, player);
		});
		list_box2.row_selected.connect(() => change_state (GamepadSelectPopoverState.CHOSE_PLAYER));
		list_box1.show_all ();
		list_box2.show_all ();
	}

	private string get_player_string (int player) {
		return @"#$(player+1) - $(gamepads[associations[player]])";
	}

	private void change_state (GamepadSelectPopoverState to, int player = -1) {
		if (to == state) return;
		switch (to) {
		case GamepadSelectPopoverState.CHOSE_PLAYER:
			var associate_to = list_box2.get_selected_row().get_index();
			print(@"Row changed $active_player - $associate_to!\n");
			int other = -1;
			for (var i = 0; i < associations.length; i++) {
				if (associations[i] == associate_to) { other = i; break; }
			}
			if (other != -1) associations[other] = associations[active_player];
			associations[active_player] = associate_to;
			((Gtk.Label) list_box1.get_row_at_index(active_player).get_child()).label = get_player_string(active_player);
			((Gtk.Label) list_box1.get_row_at_index(other).get_child()).label = get_player_string(other);
			stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
			stack.set_visible_child(list_box1);
			break;
		case GamepadSelectPopoverState.CHOSE_GAMEPAD:
			list_box2.select_row(list_box2.get_row_at_index(associations[player]));
			stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
			stack.set_visible_child(list_box2);
			break;
		}
		state = to;
		active_player = player;
	}
}
