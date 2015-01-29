using Soup;

/**
 * Soup implementation of VSGI.
 */
namespace VSGI {

	/**
	 * Soup Request
	 */
	class SoupRequest : VSGI.Request {

		private Soup.Message message;
		private HashTable<string, string>? _query;

		public override string method { owned get { return this.message.method ; } }

		public override URI uri { get { return this.message.uri; } }

		public override HashTable<string, string>? query { get { return this._query; } }

		public override MessageHeaders headers {
			get {
				return this.message.request_headers;
			}
		}

		public SoupRequest(Soup.Message msg, HashTable<string, string>? query) {
			this.message = msg;
			this._query = query;
		}

		public override ssize_t read (uint8[] buffer, Cancellable? cancellable = null) {
			buffer = this.message.request_body.data;
			return this.message.request_body.data.length;
		}

		/**
		 * This will complete the request MessageBody.
		 */
		public override bool close (Cancellable? cancellable = null) {
			this.message.request_body.complete ();
			return true;
		}
	}

	/**
	 * Soup Response
	 */
	class SoupResponse : VSGI.Response {

		private Soup.Message message;

		public override string mime {
			get { return this.message.response_headers.get_content_type (null); }
			set { this.message.response_headers.set_content_type (value, null); }
		}

		public override uint status {
			get { return this.message.status_code; }
			set { this.message.set_status (value); }
		}

		public override MessageHeaders headers {
			get { return this.message.response_headers; }
		}

		public SoupResponse (Soup.Message msg) {
			this.message = msg;
		}

		public override ssize_t write (uint8[] buffer, Cancellable? cancellable = null) {
			this.message.response_body.append_take (buffer);
			return buffer.length;
		}

		/**
		 * This will complete the response MessageBody.
         *
		 * Once called, you will not be able to alter the stream.
		 */
		public override bool close (Cancellable? cancellable = null) {
			this.message.response_body.complete ();
			return true;
		}
	}

	/**
	 * Implementation of VSGI.Server based on Soup.Server.
	 *
	 * @since 0.1
	 */
	public class SoupServer : VSGI.Server {

		private Soup.Server server;

		public SoupServer (VSGI.Application app, uint port) throws Error {
			base (app);
			this.server = new Soup.Server (Soup.SERVER_PORT, 3003);
		}

		/**
		 * Creates a Soup.Server, bind the application to it using a closure and
		 * start the server.
		 */
		public override void listen () {

			Soup.ServerCallback soup_handler = (server, msg, path, query, client) => {

				var req = new SoupRequest (msg, query);
				var res = new SoupResponse (msg);

				this.application.handler (req, res);

				message ("%u %s %s".printf (res.status, req.method, req.uri.get_path ()));
			};

			this.server.add_handler (null, soup_handler);

			message ("listening on http://%s:%u", server.interface.physical, server.interface.port);

			// run the server
			this.server.run ();
		}
	}
}
