// This file is part of GNOME Games. License: GPLv3

private class Games.LinuxJoystickMapping: GamepadMapping {
	private GamepadMappingType mapping_type;

	public void map_event (LinuxJoystickEvent event, Func<GamepadEvent> func) {
		var gamepad_event = convert_joystick_event (event);

//		if (mapping == null)
//			return gamepad_event;

		map_gamepad_event (gamepad_event, func);
	}

	private GamepadEvent? convert_joystick_event (LinuxJoystickEvent event) {
		switch (event.type) {
		case InputType.AXIS:
			return convert_joystick_axis_event (event);
		case InputType.BUTTON:
			return convert_joystick_button_event (event);
		}

		return null;
	}

	private GamepadEvent convert_joystick_axis_event (LinuxJoystickEvent event) {
		var axis_event = new GamepadAxisEvent ();

		axis_event.time = event.time;
		axis_event.axis = event.number;
		axis_event.value = (double) event.value / int16.MAX;

		var gamepad_event = new GamepadEvent ();
		gamepad_event.axis_event = axis_event;

		return gamepad_event;
	}

	private GamepadEvent convert_joystick_button_event (LinuxJoystickEvent event) {
		var button_event = new GamepadButtonEvent ();

		button_event.time = event.time;
		button_event.button = event.number;
		button_event.value.pressed = event.value != 0;
		button_event.value.value = (double) event.value + int16.MAX;
		button_event.value.value /= 2 * (double) int16.MAX;

		var gamepad_event = new GamepadEvent ();
		gamepad_event.button_event = button_event;

		return gamepad_event;
	}

	private void map_gamepad_event (GamepadEvent event, Func<GamepadEvent> func) {
		if (event.axis_event != null) {
			map_gamepad_axis_event (event.axis_event, func);

			return;
		}

		if (event.button_event != null) {
			map_gamepad_button_event (event.button_event, func);

			return;
		}
	}

	private void map_gamepad_axis_event (GamepadAxisEvent event, Func<GamepadEvent> func) {
		foreach_source (InputType.AXIS, event.axis, (input_mapping) => {
			var mapped_event = new GamepadEvent ();
			switch (input_mapping.dst_type) {
			case InputType.AXIS:
				var mapped_axis_event = new GamepadAxisEvent ();
				mapped_axis_event.time = event.time;
				mapped_axis_event.axis = input_mapping.dst_index;
				mapped_axis_event.value = input_mapping.filter.apply (event.value);

				mapped_event.axis_event = mapped_axis_event;
				break;
			case InputType.BUTTON:
				var mapped_button_event = new GamepadButtonEvent ();
				mapped_button_event.time = event.time;
				mapped_button_event.button = input_mapping.dst_index;
				mapped_button_event.value.value = input_mapping.filter.apply (event.value);
				mapped_button_event.value.pressed = mapped_button_event.value.value > 0.8;

	print ("\taxis %d %lf to button %d: %lf\n", event.axis, event.value, mapped_button_event.button, mapped_button_event.value.value);

				mapped_event.button_event = mapped_button_event;
				break;
			}

			func (mapped_event);
		});
	}

	private void map_gamepad_button_event (GamepadButtonEvent event, Func<GamepadEvent> func) {
		foreach_source (InputType.BUTTON, event.button, (input_mapping) => {
			var mapped_event = new GamepadEvent ();
	print ("\t%d %d\n", input_mapping.dst_type, InputType.BUTTON);
			switch (input_mapping.dst_type) {
	//		case (InputType.AXIS):
	//			var mapped_axis_event = new GamepadAxisEvent ();
	//			mapped_axis_event.time = event.time;
	//			mapped_axis_event.axis = input_mapping.dst_index;
	//			mapped_axis_event.value = input_mapping.filter.apply (event.value);

	//			mapped_event.axis_event = mapped_axis_event;
	//			break;
			case (InputType.BUTTON):
				var mapped_button_event = new GamepadButtonEvent ();
				mapped_button_event.time = event.time;
				mapped_button_event.button = input_mapping.dst_index;
				mapped_button_event.value.value = input_mapping.filter.apply (event.value.value);
				mapped_button_event.value.pressed = event.value.pressed;

				mapped_event.button_event = mapped_button_event;
				break;
			}

			func (mapped_event);
		});
	}
}
