// This file is part of GNOME Games. License: GPLv3

private class LibGamepad.LinuxRawGamepadMonitor : Object, RawGamepadMonitor {
	public delegate void RawGamepadCallback (RawGamepad raw_gamepad);

	private GUdev.Client client;
	private HashTable<string, RawGamepad> raw_gamepads;

	public LinuxRawGamepadMonitor () {
		client = new GUdev.Client ({"input"});
		client.uevent.connect (handle_udev_client_callback);

		// Initialize internally plugged in gamepads
		client.query_by_subsystem ("input").foreach ((dev) => {
			if (dev.get_device_file () == null)
				return;
			var identifier = dev.get_device_file ();
			if ((dev.has_property ("ID_INPUT_JOYSTICK") && dev.get_property ("ID_INPUT_JOYSTICK") == "1") ||
				(dev.has_property (".INPUT_CLASS") && dev.get_property (".INPUT_CLASS") == "joystick")) {
				RawGamepad raw_gamepad;
				try {
					raw_gamepad = new LinuxRawGamepad (identifier);
				} catch (FileError err) {
					return;
				}
				raw_gamepads.replace (identifier, raw_gamepad);
			}
		});
	}

	public void foreach_gamepad (RawGamepadCallback callback) {
		raw_gamepads.foreach((identifier, raw_gamepad) => callback (raw_gamepad));
	}

	private void handle_udev_client_callback (string action, GUdev.Device dev) {
		if (dev.get_device_file () == null)
			return;

		var identifier = dev.get_device_file ();
		if ((dev.has_property ("ID_INPUT_JOYSTICK") && dev.get_property ("ID_INPUT_JOYSTICK") == "1") ||
			(dev.has_property (".INPUT_CLASS") && dev.get_property (".INPUT_CLASS") == "joystick")) {
			switch (action) {
			case "add":
				RawGamepad raw_gamepad;
				try {
					raw_gamepad = new LinuxRawGamepad (identifier);
				} catch (FileError err) {
					return;
				}
				raw_gamepads.replace (identifier, raw_gamepad);
				gamepad_plugged (raw_gamepad);
				break;
			case "remove":
				if (!raw_gamepads.contains (identifier))
					break;

				var raw_gamepad = raw_gamepads.get (identifier);
				raw_gamepads.remove (identifier);

				// This signal is emitted from here to simplify the code
				raw_gamepad.unplugged ();
				gamepad_unplugged (raw_gamepad);
				break;
			}
		}
	}
}
