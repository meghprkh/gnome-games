// This file is part of GNOME Games. License: GPLv3

private class Games.LinuxJoystick: Object {
	public signal void button_press_event (LinuxJoystickEvent event);
	public signal void button_release_event (LinuxJoystickEvent event);
	public signal void axis_event (LinuxJoystickEvent event);

	public virtual signal void unplug () {
		remove_event_source ();
	}

	public int16[] axes { get; private set; }
	public int16[] buttons { get; private set; }

//	private string? _name;
//	public string? name {
//		get {
//			char buffer[128];
//			if (Posix.ioctl (fd, Linux.Joystick.JSIOCGNAME (buffer.length), buffer) < 0)
//				return null;

//			_name = (string) buffer;

//		print ("\n\n\n\n\n\nNAME: %s\n\n\n\n\n\n", _name);
//			return _name;
//		}
//	}

	public string? get_name () {
		char name[128];
		if (Posix.ioctl (fd, Linux.Joystick.JSIOCGNAME (name.length), name) < 0)
			return null;

		var _name = (string) name;

	print ("\n\n\n\n\n\nNAME: %s\n\n\n\n\n\n", _name);
		return _name;
	}

	private uint8 axes_number {
		get {
			uint8 number = 0;
			Posix.ioctl (fd, Linux.Joystick.JSIOCGAXES, out number);

			return number;
		}
	}

	private uint8 buttons_number {
		get {
			uint8 number = 0;
			Posix.ioctl (fd, Linux.Joystick.JSIOCGBUTTONS, out number);

			return number;
		}
	}


	private FileMonitor monitor;
	private int fd;
	private uint? event_source_id;

	public LinuxJoystick (string file_name) throws FileError, IOError {
		// Open the file in non blocking mode
		fd = Posix.open (file_name, Posix.O_RDONLY | Posix.O_NONBLOCK);

		if (fd < 0)
			throw new FileError.FAILED (@"Unable to open file $file_name: $(Posix.strerror(Posix.errno))");

		// Monitor the file for deletion
		monitor = File.new_for_path (file_name).monitor_file (FileMonitorFlags.NONE);
		monitor.changed.connect ((f1, f2, e) => {
			if (e == FileMonitorEvent.DELETED)
				unplug ();
		});

		// Poll the events in the default main loop
		var channel = new IOChannel.unix_new (fd);
		event_source_id = channel.add_watch (IOCondition.IN, () => { return poll_events (); });
	}

	construct {
		axes = new int16[axes_number];
		buttons = new int16[buttons_number];
	}

	~LinuxJoystick () {
		Posix.close (fd);
		remove_event_source ();
	}

	private bool poll_events () {
		while (poll_event ());

		return true;
	}

	public bool poll_event () {
		var e = Linux.Joystick.Event ();
		var read_size = Posix.read (fd, &e, sizeof (Linux.Joystick.Event));
		if (read_size != sizeof (Linux.Joystick.Event))
			return false;

		on_linux_joystick_event (e);

		return true;
	}

	public void on_linux_joystick_event (Linux.Joystick.Event e) {
		var joystick_event = new LinuxJoystickEvent ();

		joystick_event.time = e.time;

		switch (e.type & (~Linux.Joystick.JS_EVENT_INIT)) {
		case (uint8) Linux.Joystick.JS_EVENT_BUTTON:
			joystick_event.type = InputType.BUTTON;
			break;
		case (uint8) Linux.Joystick.JS_EVENT_AXIS:
			joystick_event.type = InputType.AXIS;
			break;
		default:
			var event_type = e.type & (~Linux.Joystick.JS_EVENT_INIT);
			warning ("Unknown event type: %u", event_type);
			break;
		}

		joystick_event.init = (bool) (e.type & Linux.Joystick.JS_EVENT_INIT);
		joystick_event.number = e.number;
		joystick_event.value = e.value;
		joystick_event.joystick = this;

		switch (joystick_event.type) {
		case InputType.BUTTON:
			if (joystick_event.value == 0)
				button_release_event (joystick_event);
			else
				button_press_event (joystick_event);
			break;
		case InputType.AXIS:
			axis_event (joystick_event);
			break;
		}
	}

	private void remove_event_source () {
		if (event_source_id == null)
			return;

		Source.remove (event_source_id);
		event_source_id = null;
	}

	private int get_version () {
		int version;
		Posix.ioctl (fd, Linux.Joystick.JSIOCGVERSION, out version);

		return version;
	}

	private void set_correction (Linux.Joystick.Corr[] correction) {
		Posix.ioctl (fd, Linux.Joystick.JSIOCSCORR, ref correction);
	}

	private Linux.Joystick.Corr[] get_correction () {
		Linux.Joystick.Corr[] correction = new Linux.Joystick.Corr[axes_number];
		Posix.ioctl (fd, Linux.Joystick.JSIOCGCORR, ref correction);

		return correction;
	}
}
