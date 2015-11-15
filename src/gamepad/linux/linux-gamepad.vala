// This file is part of GNOME Games. License: GPLv3

private class Games.LinuxGamepad: LinuxJoystick, Gamepad {
	public string id {
		get {
			return "";
		}
	}

	private long _index;
	public long index {
		get { return _index; }
	}

	private bool _connected;
	public bool connected {
		get { return _connected; }
	}

	private time_t _timestamp;
	public time_t timestamp {
		get { return _timestamp; }
	}

	private GamepadMappingType _mapping_type;
	public GamepadMappingType mapping_type {
		get { return _mapping_type; }
	}

	private double[] _axes;
	public double[] axes {
		get { return _axes; }
	}

	private GamepadButton[] _buttons;
	public GamepadButton[] buttons {
		get { return _buttons; }
	}



	private static MappingDoc mapping_doc;


	public LinuxJoystickMapping mapping { get; set; }

	public signal void gamepad_button_event (GamepadButtonEvent event);
	public signal void gamepad_axis_event (GamepadAxisEvent event);

	public LinuxGamepad (string file_name, bool with_default_mapping = true) throws FileError, IOError {
		base (file_name);

		mapping = new LinuxJoystickMapping ();

//		if (with_default_mapping)
//			mapping = MappingSet.get_default ().get_mapping (get_name ());

//		if (mapping == null)
//			mapping = new Mapping ();

		button_press_event.connect (on_joystick_event);
		button_release_event.connect (on_joystick_event);
		axis_event.connect (on_joystick_event);

		_connected = true;
		unplug.connect (() => { _connected = false; });
	}

	construct {
		if (mapping_doc == null)
			mapping_doc = new MappingDoc.from_resource ("gamepads/linux.gamepads.xml");
	}

//	private void on_joystick_event (LinuxJoystickEvent e) {
//		foreach (var input in mapping.get_input_types (e.type, e.number)) {
//			var event_gp = new EventGamepad ();

//			var input_mapping = mapping.get_input_mapping (input);

//			event_gp.time = e.time;
//			event_gp.type = input;
//			event_gp.gamepad = this;
//			event_gp.value = input_mapping == null ? 0 :
//				input_mapping.operation_type.apply (e.value);

			// Emit the event
//			var generic_event = new Event ();
//			generic_event.gamepad = event_gp;
//			event (generic_event);

//			gamepad_button_event (event_gp);

//			event_after(generic_event);
//		}
//	}

	private bool mapping_initiated = false;
	private void init_mapping () {
		if (mapping_initiated)
			return;

		var mapping_node = mapping_doc.get_mapping_for_gamepad_id (get_name ());
		mapping_node.foreach_input_mapping ((input_mapping) => {
			mapping.add (input_mapping);
		});
		mapping_initiated = true;
	}

	private void on_joystick_event (LinuxJoystickEvent e) {
		init_mapping ();

		mapping.map_event (e, (gamepad_event) => {
			if (gamepad_event == null)
				return;

			if (gamepad_event.axis_event != null)
				gamepad_axis_event (gamepad_event.axis_event);

			if (gamepad_event.button_event != null)
				gamepad_button_event (gamepad_event.button_event);
		});
	}
}
