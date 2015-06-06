using Valum;
using VSGI.FastCGI;

public static int main (string[] args) {
	var app = new Router ();

	// default route
	app.get ("", (req, res) => {
		res.body.write ("Hello world!".data);
		res.end ();
	});

	app.get ("random/<int:size>", (req, res) => {
		var size   = int.parse (req.params["size"]);
		var writer = new DataOutputStream (res.body);

		for (; size > 0; size--) {
			// write byte to byte
			writer.put_uint32 (Random.next_int ());
		}

		res.end ();
	});

	app.get ("<any:path>", (req, res) => {
		res.status = 404;

		var writer = new DataOutputStream (res.body);
		writer.put_string ("404 - Not found");

		res.end ();
	});

	return new Server (app).run (args);
}
