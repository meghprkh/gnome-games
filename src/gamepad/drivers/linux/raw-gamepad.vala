private class LibGamepad.LinuxRawGamepad : Object, RawGamepad {
	public string identifier { get; protected set; }
	public string name { get; protected set; }
	public string guid { get; protected set; }

	public uint8 axes_number { get; protected set; default = 0; }
	public uint8 buttons_number { get; protected set; default = 0; }
	public uint8 dpads_number { get; protected set; default = 0; }

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
			throw new FileError.FAILED (@"Unable to open file $file_name: $(Posix.strerror(Posix.errno))");

		dev = new Libevdev.Evdev();
		if (dev.set_fd(fd) < 0)
			throw new FileError.FAILED ("Locha ho gaya o bhaiya locha ho gaya");

		// Monitor the file for deletion
		gudev_client = new GUdev.Client({"input"});
		gudev_client.uevent.connect((action, gudev_dev) => {
			if (action == "remove" && gudev_dev.get_device_file () == file_name) {
				remove_event_source();
				unplugged();
			}
		});

		name = dev.name;
		guid = LinuxGuidHelpers.from_dev(dev);

		// Poll the events in the default main loop
		var channel = new IOChannel.unix_new (fd);
		event_source_id = channel.add_watch (IOCondition.IN, poll_events);

		// Initialize dpads, buttons and axes
		uint i;
		for (i = Linux.Input.BTN_JOYSTICK; i < Linux.Input.KEY_MAX; ++i) {
			if (dev.has_event_code(Linux.Input.EV_KEY, i)) {
				key_map[i - Linux.Input.BTN_MISC] = buttons_number;
				++buttons_number;
			}
		}
		for (i = Linux.Input.BTN_MISC; i < Linux.Input.BTN_JOYSTICK; ++i) {
			if (dev.has_event_code(Linux.Input.EV_KEY, i)) {
				key_map[i - Linux.Input.BTN_MISC] = buttons_number;
				++buttons_number;
			}
		}


		// Get info about axes
		for (i = 0; i < Linux.Input.ABS_MAX; ++i) {
			/* Skip dpads */
			if (i == Linux.Input.ABS_HAT0X) {
				i = Linux.Input.ABS_HAT3Y;
				continue;
			}
			if (dev.has_event_code(Linux.Input.EV_ABS, i)) {
				Linux.Input.AbsInfo? absinfo = dev.get_abs_info(i);
				abs_map[i] = axes_number;
				abs_info[axes_number] = absinfo;
				++axes_number;
			}
		}

		// Get info about dpads
		for (i = Linux.Input.ABS_HAT0X; i <= Linux.Input.ABS_HAT3Y; i += 2) {
			if (dev.has_event_code(Linux.Input.EV_ABS, i) || dev.has_event_code(Linux.Input.EV_ABS, i+1)) {
				Linux.Input.AbsInfo? absinfo = dev.get_abs_info(i);
				if (absinfo == null) continue;

				++dpads_number;
			}
		}
	}

	~LinuxRawGamepad () {
		Posix.close (fd);
		remove_event_source ();
	}
	
	private bool poll_events () {
		while (dev.has_event_pending() > 0)
			on_event();

		return true;
	}

	private void on_event () {
		int rc;
		Linux.Input.Event ev;
		rc = dev.next_event(Libevdev.ReadFlag.NORMAL, out ev);
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
					int axis = abs_map[code];
					axis_event (axis, (double) ev.value / abs_info[axis].maximum);
					break;
				}
				break;
			case Linux.Input.EV_REL:
				switch (code) {
				case Linux.Input.REL_X:
				case Linux.Input.REL_Y:
					code -= Linux.Input.REL_X;
					// TODO : ball events
					print("Ball %d Axis %d Value %d\n", code / 2, code % 2, ev.value);
					break;
				default:
					break;
				}
				break;
			}
		}
	}

	private void remove_event_source () {
		if (event_source_id == null)
			return;

		Source.remove (event_source_id);
		event_source_id = null;
	}
}
