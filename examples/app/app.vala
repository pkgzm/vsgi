using Valum;
using VSGI.Soup;

var app = new Router ();

app.all (null, (req, res, next) => {
	res.headers.append ("Server", "Valum/1.0");
	next (req, res);
});

app.get ("", (req, res, next) => {
	var template = new View.from_resources ("/templates/home.html");
	template.to_stream (res.body);
});

app.get ("gzip", (req, res, next) => {
	res.headers.replace ("Content-Encoding", "gzip");
	next (req, new VSGI.ConvertedResponse (res, new ZlibCompressor (ZlibCompressorFormat.GZIP)));
}).then ((req, res) => {
	var template = new View.from_resources ("/templates/home.html");
	template.to_stream (res.body);
});

// replace 'Content-Type' for 'text/plain'
app.get (null, (req, res, next) => {
	HashTable<string, string>? @params;
	res.headers.get_content_type (out @params);
	res.headers.set_content_type ("text/plain", @params);
	next (req, res);
});

app.get ("headers", (req, res) => {
	req.headers.foreach ((name, header) => {
		res.body.write_all ("%s: %s\n".printf (name, header).data, null);
	});
});

app.get ("query", (req, res) => {
	if (req.query == null) {
		res.body.write_all ("null".data, null);
	} else {
		req.query.foreach ((k, v) => {
			res.body.write_all ("%s: %s\n".printf (k, v).data, null);
		});
	}
});

app.get ("cookies", (req, res) => {
	var cookies = VSGI.Cookies.from_request (req);
	if (cookies == null) {
		res.body.write_all ("null".data, null);
	} else {
		foreach (var cookie in cookies) {
			res.body.write_all ("%s: %s\n".printf (cookie.name, cookie.value).data, null);
		}
	}
});

app.scope ("cookie", (inner) => {
	inner.get ("<name>", (req, res) => {
		foreach (var cookie in VSGI.Cookies.from_request (req))
			if (cookie.name == req.params["name"])
				res.body.write_all ("%s\n".printf (cookie.value).data, null);
	});

	inner.post ("<name>", (req, res) => {
		var @value = new MemoryOutputStream (null, realloc, free);

		@value.splice (req.body, OutputStreamSpliceFlags.CLOSE_SOURCE);

		var cookie = new Soup.Cookie (req.params["name"], (string) @value.data, "0.0.0.0", "/", 60);

		res.headers.append ("Set-Cookie", cookie.to_set_cookie_header ());
	});
});

app.scope ("urlencoded-data", (inner) => {
	inner.get ("", (req, res) => {
		res.headers.set_content_type ("text/html", null);
		res.body.write_all (
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
		""".data, null);
	});

	inner.post ("", (req, res) => {
		var writer = new DataOutputStream (res.body);
		var data   = new MemoryOutputStream (null, realloc, free);

		data.splice (req.body, OutputStreamSpliceFlags.CLOSE_SOURCE);

		Soup.Form.decode ((string) data.get_data ()).foreach ((k, v) => {
			writer.put_string ("%s: %s".printf (k, v));
		});
	});
});

// hello world! (compare with Node.js!)
app.get ("hello", (req, res) => {
	res.body.write_all ("Hello world!".data, null);
});

app.get ("hello/", (req, res) => {
	res.body.write_all ("Hello world!".data, null);
});

app.all ("all", (req, res) => {
	res.body.write_all ("Matches all HTTP methods".data, null);
});

app.methods ({VSGI.Request.GET, VSGI.Request.POST}, "get-and-post", (req, res) => {
	res.body.write_all ("Matches GET and POST".data, null);
});

app.method (VSGI.Request.GET, "custom-method", (req, res) => {
	res.body.write_all (req.method.data, null);
});

app.get ("hello/<id>", (req, res) => {
	res.body.write_all ("hello %s!".printf (req.params["id"]).data, null);
});

app.get ("users/<int:id>/<action>", (req, res) => {
	var id     = req.params["id"];
	var test   = req.params["action"];
	var writer = new DataOutputStream (res.body);

	writer.put_string (@"id\t=> $id\n");
	writer.put_string (@"action\t=> $test");
});

app.types["permutations"] = /abc|acb|bac|bca|cab|cba/;

app.get ("custom-route-type/<permutations:p>", (req, res) => {
	res.body.write_all (req.params["p"].data, null);
});

app.regex (VSGI.Request.GET, /custom-regular-expression/, (req, res) => {
	res.body.write_all ("This route was matched using a custom regular expression.".data, null);
});

app.matcher (VSGI.Request.GET, (req) => { return req.uri.get_path () == "/custom-matcher"; }, (req, res) => {
	res.body.write_all ("This route was matched using a custom matcher.".data, null);
});

// scoped routing
app.scope ("admin", (adm) => {
	// matches /admin/fun
	adm.scope ("fun", (fun) => {
		// matches /admin/fun/hack
		fun.get ("hack", (req, res) => {
			var time = new DateTime.now_utc ();
			res.body.write_all ("It's %s around here!\n".printf (time.format ("%H:%M")).data, null);
		});
		// matches /admin/fun/heck
		fun.get ("heck", (req, res) => {
			res.body.write_all ("Wuzzup!".data, null);
		});
	});
});

app.get ("redirect", (req, res) => {
	throw new Redirection.MOVED_TEMPORARILY ("http://example.com");
});

app.get ("not-found", (req, res) => {
	throw new ClientError.NOT_FOUND ("This status were thrown and handled by a status handler.");
});

var api = new Router ();

api.get ("repository/<name>", (req, res) => {
	var name = req.params["name"];
	res.body.write_all (name.data, null);
});

// delegate all other GET requests to a subrouter
app.get ("repository/<any:path>", api.handle);

app.get ("next", (req, res, next) => {
	next (req, res);
});

app.get ("next", (req, res) => {
	res.body.write_all ("Matched by the next route in the queue.".data, null);
});

app.get ("state", (req, res, next, stack) => {
	stack.push_tail ("I have been passed!");
	next (req, res);
});

app.get ("state", (req, res, next, stack) => {
	res.body.write_all (stack.pop_tail ().get_string ().data, null);
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

	res.headers.set_content_type ("text/html", null);
	tpl.to_stream (res.body);
});

// serve static resource using a path route parameter
app.get ("static/<path:resource>.<any:type>", (req, res) => {
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
		res.body.splice_async.begin (file,
			                         OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET,
			                         Priority.DEFAULT,
			                         null, (obj, result) => {
			var size = res.body.splice_async.end (result);
		});
	} catch (Error e) {
		throw new ClientError.NOT_FOUND (e.message);
	}
});

app.status (Soup.Status.NOT_FOUND, (req, res, next, stack) => {
	var template = new View.from_stream (resources_open_stream ("/templates/404.html", ResourceLookupFlags.NONE));
	template.environment.push_string ("message", stack.pop_tail ().get_string ());
	res.status = Soup.Status.NOT_FOUND;
	HashTable<string, string> @params;
	res.headers.get_content_type (out @params);
	res.headers.set_content_type ("text/html", @params);
	template.to_stream (res.body);
});

new Server ("org.valum.example.App", app.handle).run ({"app", "--all"});
