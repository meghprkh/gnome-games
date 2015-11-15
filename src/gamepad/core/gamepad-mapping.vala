// This file is part of GNOME Games. License: GPLv3

private class Games.GamepadMapping: Object {
	private HashTable<int?, Array<InputMapping?>>[] mappings;

	construct {
		var length = InputType.length ();
		mappings = new HashTable<int?, Array<InputMapping?>>[length];
		for (int i = 0; i < length; i++)
			mappings[i] = new HashTable<int?, Array<InputMapping?>> (int_hash, int_equal);
	}

	public void add (InputMapping input_mapping) {
		var src_type = input_mapping.src_type;
		int index = input_mapping.src_index;

		if (!mappings[src_type].contains (index))
			mappings[src_type][index] = new Array <InputMapping?> ();

		mappings[src_type][index].append_val (input_mapping);
	}

	public void foreach_source (InputType src_type, uint8 src_index, Func<InputMapping?> func) {
		return_if_fail (0 <= src_type < InputType.length ());

		int index = src_index;
		if (!mappings[src_type].contains (index))
			return;

		for (int i = 0; i < mappings[src_type][index].length; i++)
			func (mappings[src_type][index].index (i));
	}
}
