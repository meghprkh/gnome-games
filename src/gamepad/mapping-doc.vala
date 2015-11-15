// This file is part of GNOME Games. License: GPLv3

private class Games.MappingDoc: XmlDoc {
	public MappingDoc () {
		base ("1.0");

		Xml.Node* root = new Xml.Node (null, "gampads");
		doc->set_root_element (root);
	}

	public MappingDoc.from_resource (string resource) throws Error {
		base.from_resource (resource);

		// TODO Check if the document is well formed.
	}

	public MappingNode? get_mapping_for_gamepad_id (string id) {
		var expr = "/gamepads/gamepad[@id = \"" + id + "\"]/mapping";

		Xml.Node* node = lookup_node (expr);
		if (node == null)
			return null;

		return new MappingNode (this, node);
	}
}
