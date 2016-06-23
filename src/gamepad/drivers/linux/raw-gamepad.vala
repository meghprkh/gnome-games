private class LibGamepad.LinuxRawGamepad : Object, RawGamepad {
	public string identifier { get; protected set; }
	public string name { get; protected set; }
	public string guid { get; protected set; }

	public uint8 axes_number { get; protected set; default = 0; }
	public uint8 buttons_number { get; protected set; default = 0; }
	private int _dpads_number = -1;
	public uint8 dpads_number {
		get {
			if (_dpads_number != -1)
				return (uint8) _dpads_number;

			_dpads_number = 0;
			for (var i = Linux.Input.ABS_HAT0X; i <= Linux.Input.ABS_HAT3Y; i += 2) {
				if (dev.has_event_code (Linux.Input.EV_ABS, i) || dev.has_event_code (Linux.Input.EV_ABS, i+1)) {
					Linux.Input.AbsInfo? absinfo = dev.get_abs_info (i);
					if (absinfo == null)
						continue;

					_dpads_number++;
				}
			}
			return (uint8) _dpads_number;
		}
		protected set {}
	}

	private int fd;
	private GUdev.Client gudev_client;
	private uint? event_source_id;
	private Libevdev.Evdev dev;

	private uint8 key_map[Linux.Input.KEY_MAX];
	private uint8 abs_map[Linux.Input.ABS_MAX];
	private Linux.Input.AbsInfo abs_info[Linux.Input.ABS_MAX];

	public LinuxRawGamepad (string file_name) throws FileError {
		identifier = file_name;
		fd = Posix.open (file_name, Posix.O_RDONLY | Posix.O_NONBLOCK);

		if (fd < 0)
			throw new FileError.FAILED (@"Unable to open file $file_name: $(Posix.strerror (Posix.errno))");

		dev = new Libevdev.Evdev ();
		if (dev.set_fd (fd) < 0)
			throw new FileError.FAILED (@"Evdev is unable to open $file_name: $(Posix.strerror (Posix.errno))");

		// Monitor the file for deletion
		gudev_client = new GUdev.Client ({"input"});
		gudev_client.uevent.connect (handle_gudev_event);

		name = dev.name;
		guid = LinuxGuidHelpers.from_dev (dev);

		// Poll the events in the default main loop
		var channel = new IOChannel.unix_new (fd);
		event_source_id = channel.add_watch (IOCondition.IN, poll_events);

		// Initialize dpads, buttons and axes
		for (var i = Linux.Input.BTN_JOYSTICK; i < Linux.Input.KEY_MAX; i++) {
			if (dev.has_event_code (Linux.Input.EV_KEY, i)) {
				key_map[i - Linux.Input.BTN_MISC] = buttons_number;
				buttons_number++;
			}
		}
		for (var i = Linux.Input.BTN_MISC; i < Linux.Input.BTN_JOYSTICK; i++) {
			if (dev.has_event_code (Linux.Input.EV_KEY, i)) {
				key_map[i - Linux.Input.BTN_MISC] = buttons_number;
				buttons_number++;
			}
		}


		// Get info about axes
		for (var i = 0; i < Linux.Input.ABS_MAX; i++) {
			/* Skip dpads */
			if (i == Linux.Input.ABS_HAT0X) {
				i = Linux.Input.ABS_HAT3Y;
				continue;
			}
			if (dev.has_event_code (Linux.Input.EV_ABS, i)) {
				var absinfo = dev.get_abs_info (i);
				abs_map[i] = axes_number;
				abs_info[axes_number] = absinfo;
				axes_number++;
			}
		}
	}

	~LinuxRawGamepad () {
		Posix.close (fd);
		remove_event_source ();
	}

	private bool poll_events () {
		while (dev.has_event_pending () > 0)
			handle_evdev_event ();

		return true;
	}

	private void handle_evdev_event () {
		int rc;
		Linux.Input.Event ev;
		rc = dev.next_event (Libevdev.ReadFlag.NORMAL, out ev);
		if (rc == 0) {
			int code = ev.code;
			switch (ev.type) {
			case Linux.Input.EV_KEY:
				if (code >= Linux.Input.BTN_MISC) {
					button_event (key_map[code - Linux.Input.BTN_MISC], (bool) ev.value);
				}
				break;
			case Linux.Input.EV_ABS:
				switch (code) {
				case Linux.Input.ABS_HAT0X:
				case Linux.Input.ABS_HAT0Y:
				case Linux.Input.ABS_HAT1X:
				case Linux.Input.ABS_HAT1Y:
				case Linux.Input.ABS_HAT2X:
				case Linux.Input.ABS_HAT2Y:
				case Linux.Input.ABS_HAT3X:
				case Linux.Input.ABS_HAT3Y:
					code -= Linux.Input.ABS_HAT0X;
					dpad_event (code / 2, code % 2, ev.value);
					break;
				default:
					var axis = abs_map[code];
					axis_event (axis, (double) ev.value / abs_info[axis].maximum);
					break;
				}
				break;
			}
		}
	}

	private void handle_gudev_event (string action, GUdev.Device gudev_dev) {
		if (action == "remove" && gudev_dev.get_device_file () == identifier) {
			remove_event_source ();
			unplugged ();
		}
	}

	private void remove_event_source () {
		if (event_source_id == null)
			return;

		Source.remove (event_source_id);
		event_source_id = null;
	}
}
