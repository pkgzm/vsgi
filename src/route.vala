using VSGI;

namespace Valum {

	/**
	 * Route that matches Request path.
	 *
	 * @since 0.0.1
	 */
	public class Route : Object {

		/**
		 * Router that declared this route.
         *
		 * This is used to hold parameters types.
		 */
		private weak Router router;

		/**
		 * Match a Request and populate its parameters if successful.
		 */
		private RequestMatcher matcher;

		/**
		 * Callback
		 */
		private unowned RouteCallback callback;

		/**
		 * Match the request and populate the parameters.
		 *
		 * @since 0.1
		 */
		public delegate bool RequestMatcher (Request req);

		/**
		 * @since 0.0.1
		 */
		public delegate void RouteCallback (Request req, Response res);

		/**
		 * Create a Route using a custom matcher.
		 *
		 * @since 0.1
		 */
		public Route.from_matcher (Router router, RequestMatcher matcher, RouteCallback callback) {
			this.router   = router;
			this.matcher  = matcher;
			this.callback = callback;
		}

		/**
		 * Create a Route for a given callback using a Regex.
		 *
		 * @since 0.1
		 */
		public Route.from_regex (Router router, Regex regex, RouteCallback callback) throws RegexError {
			this.router   = router;
			this.callback = callback;

			var captures      = new SList<string> ();
			var capture_regex = new Regex ("\\(\\?<(\\w+)>.+\\)");
			MatchInfo capture_match_info;

			// extract the captures from the regular expression
			if (capture_regex.match (regex.get_pattern (), 0, out capture_match_info)) {
				foreach (var capture in capture_match_info.fetch_all ()) {
					captures.append (capture);
				}
			}

			this.matcher = (req) => {
				MatchInfo match_info;
				if (regex.match (req.uri.get_path (), 0, out match_info)) {
					if (captures.length () > 0) {
						// populate the request parameters
						var p = new HashTable<string, string?> (str_hash, str_equal);
						foreach (var capture in captures) {
							p[capture] = match_info.fetch_named (capture);
						}
						req.params = p;
					}
					return true;
				}
				return false;
			};
		}

		/**
		 * Create a Route for a given callback from a rule.
         *
		 * A rule will compile down to Regex.
		 *
		 * @since 0.0.1
		 */
		public Route.from_rule (Router router, string rule, RouteCallback callback) throws RegexError {
			this.router   = router;
			this.callback = callback;

			var param_regex = new Regex ("(<(?:\\w+:)?\\w+>)");
			var params      = param_regex.split_full (rule);
			var captures    = new SList<string> ();
			var route       = new StringBuilder ("^");

			foreach (var p in params) {
				if (p[0] != '<') {
					// regular piece of route
					route.append (Regex.escape_string (p));
				} else {
					// extract parameter
					var cap  = p.slice (1, p.length - 1).split (":", 2);
					var type = cap.length == 1 ? "string" : cap[0];
					var key  = cap.length == 1 ? cap[0] : cap[1];

					captures.append (key);
					route.append ("(?<%s>%s)".printf (key, this.router.types[type]));
				}
			}

			route.append ("$");

			var regex = new Regex (route.str, RegexCompileFlags.OPTIMIZE);

			// register a matcher based on the generated regular expression
			this.matcher = (req) => {
				MatchInfo match_info;
				if (regex.match (req.uri.get_path (), 0, out match_info)) {
					if (captures.length () > 0) {
						// populate the request parameters
						var p = new HashTable<string, string?> (str_hash, str_equal);
						foreach (var capture in captures) {
							p[capture] = match_info.fetch_named (capture);
						}
						req.params = p;
					}
					return true;
				}
				return false;
			};
		}

		/**
		 * Matches the given request and populate its parameters on success.
         *
		 * @since 0.0.1
		 *
		 * @param req request that is being matched
		 */
		public bool match (Request req) {
			return this.matcher (req);
		}

		/**
		 * Fire a request-response couple.
		 *
		 * This will apply the callback on the request and response.
         *
		 * @since 0.0.1
		 *
		 * @param req
		 * @param res
		 */
		public void fire (Request req, Response res) {
			this.callback (req, res);
		}
	}
}
