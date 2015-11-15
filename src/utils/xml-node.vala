// This file is part of GNOME Games. License: GPLv3

private class Games.XmlNode: Object {
	private XmlDoc doc;
	private Xml.Node* node;

	public XmlNode (XmlDoc doc, Xml.Node* node) {
		this.doc = doc;
		this.node = node;
	}

	public Xml.Node* lookup_node (string xpath) {
		return doc.lookup_node (xpath, node);
	}

	public string? get_content () {
		return node->get_content ();
	}

	public string? get_prop (string prop) {
		return node->get_prop (prop);
	}

	public void @foreach (string xpath, Func<unowned Xml.Node*> func) {
		doc.foreach (xpath, node, func);
	}

	public void foreach_child (Func<unowned Xml.Node*> func) {
		for (Xml.Node* child = node->children; child != null; child = child->next)
			func (child);
	}
}
