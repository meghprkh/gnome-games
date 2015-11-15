// This file is part of GNOME Games. License: GPLv3

private class Games.XmlDoc: Object {
	protected Xml.Doc* doc;

	[CCode (cname = "xmlKeepBlanksDefault")]
	private static extern int xmlKeepBlanksDefault (int val);

	private static bool is_initiated = false;

	public XmlDoc (string? version = null) {
		init ();

		doc = new Xml.Doc (version);
	}

	public XmlDoc.from_file (string filename) throws XmlError {
		init ();

		doc = Xml.Parser.parse_file (filename);

		if (doc == null)
			throw new XmlError.PARSING_ERROR ("Counldn't parse file '%s'.", filename);
	}

	public XmlDoc.from_resource (string resource) throws Error {
		init ();
		var bytes = resources_lookup_data ("/org/gnome/Games/" + resource, ResourceLookupFlags.NONE);
		var text = (string) bytes.get_data ();

		doc = Xml.Parser.parse_memory (text, text.length);
		if (doc == null)
			throw new XmlError.PARSING_ERROR ("Counldn't parse resource '%s'.", resource);
	}

	~XmlDoc () {
		if (doc != null)
			delete doc;
	}

	private static void init () {
		if (is_initiated)
			return;

		xmlKeepBlanksDefault (0);
		Xml.Parser.init ();

		is_initiated = true;
	}

//	public void save (string filename) {
//		var stream = FileStream.open (filename, "w");
//		if (stream == null)
//			return;

//		print (stream);
//	}

//	public void print (FileStream stream) {
//		string data;
//		doc->dump_memory_enc_format (out data);
//		stream.printf (data);
//	}

	internal Xml.Node* lookup_node (string xpath,
	                             Xml.Node* from_node = null) {
		var ctx = new Xml.XPath.Context (doc);
		if (from_node != null)
			ctx.node = from_node;

		Xml.XPath.Object* obj = ctx.eval_expression (xpath);
		if (obj->nodesetval == null)
			return null;

		Xml.Node* first_node = obj->nodesetval->item(0);

		delete obj;

		return first_node;
	}

	public string? get_content (string xpath,
	                            Xml.Node* current_node) {
		Xml.Node* node = lookup_node (xpath, current_node);
		if (node == null)
			return null;

		return node->get_content ();
	}

	internal string? get_prop (string xpath,
	                           string prop,
	                           Xml.Node* current_node) {
		Xml.Node* node = lookup_node (xpath, current_node);
		if (node == null)
			return null;

		return node->get_prop (prop);
	}

	public void @foreach (string xpath,
	                      Xml.Node* from_node,
	                      Func<unowned Xml.Node*> func) {
		var ctx = new Xml.XPath.Context (doc);
		if (from_node != null)
			ctx.node = from_node;

		Xml.XPath.Object* obj = ctx.eval_expression (xpath);
		if (obj->nodesetval == null)
			return;

		var nodes = obj->nodesetval;
		for (int i = 0; i < nodes->length (); i++)
			func (nodes->item(i));

		delete obj;
	}
}
