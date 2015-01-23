using Gee;
using VSGI;

namespace Valum {

	public class Route : Object {
		public  string rule { construct; get; }
		private Regex regex;
		private ArrayList<string> captures = new ArrayList<string> ();
		private unowned RouteCallback callback;

		/**
		 * Route callback.

		 * IOError are thrown as the Request and Response objects are based on
		 * GIO stream api.
		 */
		public delegate void RouteCallback (Request req, Response res) throws IOError;

		public Route(string rule, RouteCallback callback) {
			Object(rule: rule);
			this.callback = callback;

			try {
				Regex param_regex = new Regex("(<(?:\\w+:)?\\w+>)");
				var params = param_regex.split_full(this.rule);

				StringBuilder route = new StringBuilder("^");

				foreach(var p in params) {
					if(p[0] != '<') {
						// regular piece of route
						route.append(Regex.escape_string(p));
					} else {
						// parameter
						var cap = p.slice(1, p.length - 1).split(":", 2);
						var type = cap.length == 1 ? "string" : cap[0];
						var key = cap.length == 1 ? cap[0] : cap[1];

						// TODO: support any type with a HashMap<string, string>
						var types = new HashMap<string, string> ();

						// add default types
						types["any"]    = ".+";
						types["int"]    = "\\d+";
						types["string"] = "\\w+";

						captures.add(key);
						route.append("(?<%s>%s)".printf(key, types[type]));
					}
				}

				route.append("$");
				message("registered %s", route.str);

				this.regex = new Regex(route.str, RegexCompileFlags.OPTIMIZE);
			} catch(RegexError e) {
				error(e.message);
			}
		}

		public bool matches(string path) {
			return this.regex.match(path, 0);
		}

		public void fire(Request req, Response res) {
			MatchInfo matchinfo;
			if(this.regex.match(req.uri.get_path (), 0, out matchinfo)) {
				foreach(var cap in captures) {
					req.params[cap] = matchinfo.fetch_named(cap);
				}
			}
			this.callback(req, res);
		}
	}
}
