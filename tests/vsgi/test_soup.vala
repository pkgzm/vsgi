using VSGI.Soup;

/**
 * @since 0.2
 */
public static void test_vsgi_soup_request () {
	var message      = new Soup.Message ("GET", "http://0.0.0.0:3003/");
	var input_stream = new MemoryInputStream ();

	var request = new Request (message, input_stream, null);

	assert (message == request.message);
	assert (Soup.HTTPVersion.@1_1 == request.http_version);
	assert ("GET" == request.method);
	assert ("0.0.0.0" == request.uri.get_host ());
	assert (3003 == request.uri.get_port ());
	assert (null == request.query);
	assert (null == request.params);
	assert (message.request_headers == request.headers);
	assert (0 == request.cookies.length ());
	assert (input_stream == request.body);
}

/**
 * @since 0.2
 */
public static void test_vsgi_soup_response () {
	var message       = new Soup.Message ("GET", "http://0.0.0.0:3003/");
	var input_stream  = new MemoryInputStream ();
	var output_stream = new MemoryOutputStream (null, realloc, free);

	var request  = new Request (message, input_stream, null);
	var response = new Response (request, message, output_stream);

	assert (message == request.message);
	assert (request == response.request);
	assert (output_stream == response.body);
}
