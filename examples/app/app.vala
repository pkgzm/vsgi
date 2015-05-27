using Valum;
using VSGI.Soup;

var app = new Router ();
var lua = new Script.Lua ();
var mcd = new NoSQL.Mcached ();

mcd.add_server ("127.0.0.1", 11211);

// extra route types
app.types["permutations"] = /abc|acb|bac|bca|cab|cba/;

var timer  = new Timer ();

app.setup.connect ((req, res) => {
	timer.start ();
});

app.teardown.connect ((req, res) => {
	timer.stop ();
	var elapsed = timer.elapsed ();
	res.headers.append ("X-Runtime", "%8.3fms".printf (elapsed * 1000));
	message ("%s computed in %8.3fms", req.uri.get_path (), elapsed * 1000);
});

// default route
app.get ("", (req, res) => {
	var template = new View.from_stream (resources_open_stream ("/templates/home.html", ResourceLookupFlags.NONE));

	template.stream (res);
});

app.get ("query", (req, res) => {
	var writer = new DataOutputStream (res);

	res.headers.set_content_type ("text/plain", null);

	if (req.query != null) {
		req.query.foreach ((k, v) => {
		writer.put_string ("%s: %s\n".printf (k, v));
	});
	}
});

app.get ("headers", (req, res) => {
	var writer = new DataOutputStream (res);

	res.headers.set_content_type ("text/plain", null);

	req.headers.foreach ((name, header) => {
		writer.put_string ("%s: %s\n".printf (name, header));
	});
});

app.get ("cookies", (req, res) => {
	var writer = new DataOutputStream (res);

	res.headers.set_content_type ("text/plain", null);

	// write cookies in response
	writer.put_string ("Cookie\n");
	foreach (var cookie in req.cookies) {
		writer.put_string ("%s: %s\n".printf (cookie.name, cookie.value));
	}
});

app.get ("custom-route-type/<permutations:p>", (req, res) => {
	var writer = new DataOutputStream (res);
	writer.put_string (req.params["p"]);
});

// hello world! (compare with Node.js!)
app.get ("hello", (req, res) => {
	var writer = new DataOutputStream (res);
	res.headers.set_content_type ("text/plain", null);
	writer.put_string ("Hello world\n");
});

// hello with a trailing slash
app.get ("hello/", (req, res) => {
	var writer = new DataOutputStream (res);
	res.headers.set_content_type ("text/plain", null);
	writer.put_string ("Hello world\n");
});

// example using route parameter
app.get ("hello/<id>", (req, res) => {
	var writer = new DataOutputStream (res);
	res.headers.set_content_type ("text/plain", null);
	writer.put_string ("hello %s!".printf (req.params["id"]));
});

app.scope ("urlencoded-data", (inner) => {
	inner.get ("", (req, res) => {
		var writer = new DataOutputStream (res);
		writer.put_string (
		"""
		<!DOCTYPE html>
		<html>
		  <body>
			<form method="post">
			  <textarea name="data"></textarea>
			  <button type="submit">submit</button>
			</form>
		  </body>
		</html>
		""");
	});

	inner.post ("", (req, res) => {
		var writer = new DataOutputStream (res);
		var data   = new MemoryOutputStream (null, realloc, free);

		data.splice (req, OutputStreamSpliceFlags.CLOSE_SOURCE);

		Soup.Form.decode ((string) data.get_data ()).foreach ((k, v) => {
			writer.put_string ("%s: %s".printf (k, v));
		});
	});
});

// example using a typed route parameter
app.get ("users/<int:id>/<action>", (req, res) => {
	var id     = req.params["id"];
	var test   = req.params["action"];
	var writer = new DataOutputStream (res);

	res.headers.set_content_type ("text/plain", null);

	writer.put_string (@"id\t=> $id\n");
	writer.put_string (@"action\t=> $test");
});

// lua scripting
app.get ("lua", (req, res) => {
	var writer = new DataOutputStream (res);
	writer.put_string (lua.eval ("""
		require "markdown"
		return markdown('## Hello from lua.eval!')
	"""));

	writer.put_string (lua.run ("examples/app/hello.lua"));
});

app.get ("lua.haml", (req, res) => {
	var writer = new DataOutputStream (res);
	writer.put_string (lua.run ("examples/app/haml.lua"));
});


// Ctpl template rendering
app.get ("ctpl/<foo>/<bar>", (req, res) => {
	var tpl = new View.from_string ("""
	   <p>hello {foo}</p>
	   <p>hello {bar}</p>
	   <ul>
		 {for el in strings}
		   <li>{el}</li>
		 {end}
	   </ul>
	""");

	tpl.push_string ("foo", req.params["foo"]);
	tpl.push_string ("bar", req.params["bar"]);
	tpl.push_strings ("strings", {"a", "b", "c"});
	tpl.push_int ("int", 1);

	tpl.stream (res);
});

// memcached
app.get ("memcached/get/<key>", (req, res) => {
	var value = mcd.get (req.params["key"]);
	var writer = new DataOutputStream (res);
	writer.put_string (value);
});

// TODO: rewrite using POST
app.get ("memcached/set/<key>/<value>", (req, res) => {
	var writer = new DataOutputStream (res);
	if (mcd.set (req.params["key"], req.params["value"])) {
		writer.put_string ("Ok! Pushed.");
	} else {
		writer.put_string ("Fail! Not Pushed...");
	}
});

// scoped routing
app.scope ("admin", (adm) => {
	// matches /admin/fun
	adm.scope ("fun", (fun) => {
		// matches /admin/fun/hack
		fun.get ("hack", (req, res) => {
			var time = new DateTime.now_utc ();
			var writer = new DataOutputStream (res);
			res.headers.set_content_type ("text/plain", null);
			writer.put_string ("It's %s around here!\n".printf (time.format ("%H:%M")));
		});
		// matches /admin/fun/heck
		fun.get ("heck", (req, res) => {
			var writer = new DataOutputStream (res);
			res.headers.set_content_type ("text/plain", null);
			writer.put_string ("Wuzzup!");
		});
	});
});

// serve static resource using a path route parameter
app.get ("static/<path:resource>.<any:type>", (req, res) => {
	var writer = new DataOutputStream (res);
	var resource = req.params["resource"];
	var type     = req.params["type"];
	var contents = new uint8[128];
	var path     = "/static/%s.%s".printf (resource, type);
	bool uncertain;

	try {
		var lookup = resources_lookup_data (path, ResourceLookupFlags.NONE);

		// set the content-type based on a good guess
		res.headers.set_content_type (ContentType.guess (path, lookup.get_data (), out uncertain), null);

		if (uncertain)
			warning ("could not infer content type of file %s.%s with certainty".printf (resource, type));

		var file = resources_open_stream (path, ResourceLookupFlags.NONE);

		// transfer the file
		res.splice (file, OutputStreamSpliceFlags.CLOSE_SOURCE);
	} catch (Error e) {
		res.status = 404;
		writer.put_string (e.message);
	}
});

app.get ("redirect", (req, res) => {
	throw new Redirection.MOVED_TEMPORARILY ("http://example.com");
});

app.get ("not-found", (req, res) => {
	throw new ClientError.NOT_FOUND ("the given URL was not found");
});

app.method (VSGI.Request.GET, "custom-method", (req, res) => {
	var writer = new DataOutputStream (res);
	writer.put_string (req.method);
});

app.regex (VSGI.Request.GET, /custom-regular-expression/, (req, res) => {
	var writer = new DataOutputStream (res);
	writer.put_string ("This route was matched using a custom regular expression.");
});

app.matcher (VSGI.Request.GET, (req) => { return req.uri.get_path () == "/custom-matcher"; }, (req, res) => {
	var writer = new DataOutputStream (res);
	writer.put_string ("This route was matched using a custom matcher.");
});

var api = new Router ();

api.get ("repository/<name>", (req, res) => {
	var name = req.params["name"];
	res.write (name.data);
});

// delegate all other GET requests to a subrouter
app.get ("<any:path>", api.handle);

app.teardown.connect ((req, res) => {
	if (res.status == 404) {
		var template = new View.from_stream (resources_open_stream ("/templates/404.html", ResourceLookupFlags.NONE));
		template.environment.push_string ("path", req.uri.get_path ());
		template.stream (res);
	}
});

new Server (app).run ({"app", "--port", "3003"});
