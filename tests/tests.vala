/**
 * Builds test suites and launch the GLib test framework.
 */
public int main (string[] args) {

	Test.init (ref args);

	Test.add_func ("/valum/route/from_rule", test_valum_route_from_rule);
	Test.add_func ("/valum/route/from_rule/without_captures", test_valum_route_from_rule_without_captures);
	Test.add_func ("/valum/route/from_regex", test_valum_route_from_regex);
	Test.add_func ("/valum/route/from_regex/without_captures", test_valum_route_from_regex_without_captures);
	Test.add_func ("/valum/route/from_matcher", test_valum_route_from_regex);
	Test.add_func ("/valum/route/match", test_valum_route_match);
	Test.add_func ("/valum/route/match/not_matching", test_valum_route_match_not_matching);
	Test.add_func ("/valum/route/fire", test_valum_route_match_not_matching);

	return Test.run ();
}

/**
 * Test implementation of Request used to stub a request.
 */
public class TestRequest : VSGI.Request {

	private string _method;
	private Soup.URI _uri;
	private Soup.MessageHeaders _headers;
	private HashTable<string, string> _query;

	public override string method { owned get { return this._method; } }

	public override Soup.URI uri { get { return this._uri; } }

	public override HashTable<string, string>? query { get { return this._query; } }

	public override Soup.MessageHeaders headers {
		get {
			return this._headers;
		}
	}

	public TestRequest (string method, Soup.URI uri, HashTable<string, string>? query = null) {
		this._method = method;
		this._uri    = uri;
		this._query  = query;
	}

	public TestRequest.with_method (string method) {
		this._method = method;
	}

	public TestRequest.with_uri (Soup.URI uri) {
		this._uri = uri;
	}

	public TestRequest.with_query (HashTable<string, string>? query) {
		this._query = query;
	}

	public override ssize_t read (uint8[] buffer, Cancellable? cancellable = null) {
		return 0;
	}

	public override bool close (Cancellable? cancellable = null) {
		return true;
	}
}

/**
 * Test implementation of VSGI.Response to stub a response.
 */
public class TestResponse : VSGI.Response {

	private uint _status;
	private Soup.MessageHeaders _headers;

	public override uint status { get { return this._status; } set { this._status = value; } }

	public override string mime {
		get { return this.headers.get_content_type (null); }
		set { this.headers.set_content_type (value, null); }
	}

	public override Soup.MessageHeaders headers {
		get {
			return this._headers;
		}
	}

	public TestResponse (uint status) {
		this._status = status;
	}

	public override ssize_t write (uint8[] buffer, Cancellable? cancellable = null) {
		return 0;
	}

	public override bool close (Cancellable? cancellable = null) {
		return true;
	}
}
