// This file is part of GNOME Games. License: GPLv3

/**
 * This class represents a gamepad
 *
 * The client interfaces with this class primarily
 */
public class LibGamepad.Gamepad : Object {

	/**
	 * Emitted when a button is pressed/released
	 * @param  button        The button pressed
	 * @param  value         True if pressed, False if released
	 */
	public signal void button_event (StandardGamepadButton button, bool value);

	/**
	 * Emitted when an axis's value changes
	 * @param  axis          The axis number from 0 to axes_number
	 * @param  value         The value of the axis ranging from -1 to 1
	 */
	public signal void axis_event (StandardGamepadAxis axis, double value);

	/**
	 * Emitted when the gamepad is unplugged
	 */
	public signal void unplugged ();


	/**
	 * The raw name reported by the driver
	 */
	public string? raw_name { get; private set; }

	/**
	 * The guid
	 */
	public string? guid { get; private set; }

	/**
	 * The name present in our database
	 */
	public string? name { get; private set; }

	/**
	 * The raw gamepad behind this gamepad
	 */
	public RawGamepad raw_gamepad { get; private set; }

	/**
	 * Whether this gamepad is mapped
	 */
	public bool mapped { get; private set; }

	/**
	 * The mapping object
	 */
	public Mapping? mapping { get; private set; }

	public Gamepad (RawGamepad raw_gamepad) throws FileError {
		this.raw_gamepad = raw_gamepad;
		raw_name = raw_gamepad.name;
		guid = raw_gamepad.guid;
		name = MappingsManager.get_name (guid) ?? raw_name;
		try {
			mapping = new Mapping.from_sdl_string (MappingsManager.get_mapping (guid));
			mapped = true;
			raw_gamepad.button_event.connect (on_raw_button_event);
			raw_gamepad.axis_event.connect (on_raw_axis_event);
			raw_gamepad.dpad_event.connect (on_raw_dpad_event);
		} catch (MappingError err) {
			debug ("%s - for %s/%s", err.message, guid, name);
			mapping = null;
			mapped = false;
		}
		raw_gamepad.unplugged.connect (() => unplugged ());
	}

	private void on_raw_button_event (int button, bool value) {
		InputType type;
		StandardGamepadAxis output_axis;
		StandardGamepadButton output_button;

		mapping.get_button_mapping (button, out type, out output_axis, out output_button);
		emit_event (type, output_axis, output_button, value ? 1 : 0);
	}

	private void on_raw_axis_event (int axis, double value) {
		InputType type;
		StandardGamepadAxis output_axis;
		StandardGamepadButton output_button;

		mapping.get_axis_mapping (axis, out type, out output_axis, out output_button);
		emit_event (type, output_axis, output_button, value);
	}

	private void on_raw_dpad_event (int dpad_index, int axis, int value) {
		InputType type;
		StandardGamepadAxis output_axis;
		StandardGamepadButton output_button;

		mapping.get_dpad_mapping (dpad_index, axis, value, out type, out output_axis, out output_button);
		emit_event (type, output_axis, output_button, value.abs ());
	}

	private void emit_event (InputType type, StandardGamepadAxis axis, StandardGamepadButton button, double value) {
		switch (type) {
		case InputType.AXIS:
			axis_event (axis, value);
			break;
		case InputType.BUTTON:
			button_event (button, (bool) value);
			break;
		}
	}
}
