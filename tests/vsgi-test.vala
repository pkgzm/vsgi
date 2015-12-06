/*
 * This file is part of Valum.
 *
 * Valum is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 *
 * Valum is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Valum.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using Soup;

/**
 * Test implementation of VSGI.
 */
namespace VSGI.Test {

	/**
	 * Stubbed connection with in-memory streams.
	 *
	 * The typical use case is to create a {@link VSGI.Test.Request} with a
	 * stubbed connection so that the produced and consumed messages can be
	 * easily inspected.
	 */
	public class Connection : IOStream {

		/**
		 * @since 0.2.4
		 */
		public MemoryInputStream memory_input_stream { construct; get; }

		/**
		 * @since 0.2.4
		 */
		public MemoryOutputStream memory_output_stream { construct; get; }

		public override InputStream input_stream { get { return memory_input_stream; } }

		public override OutputStream output_stream { get { return memory_output_stream; } }

		public Connection () {
			Object (memory_input_stream: new MemoryInputStream (), memory_output_stream: new MemoryOutputStream (null, realloc, free));
		}
	}

	/**
	 * Test implementation of Request used to stub a request.
	 */
	public class Request : VSGI.Request {

		private HTTPVersion _http_version         = HTTPVersion.@1_1;
		private string _method                    = VSGI.Request.GET;
		private URI _uri                          = new URI (null);
		private MessageHeaders _headers           = new MessageHeaders (MessageHeadersType.REQUEST);
		private HashTable<string, string>? _query = null;

		public override HTTPVersion http_version { get { return this._http_version; } }

		public override string method { owned get { return this._method; } }

		public override URI uri { get { return this._uri; } }

		public override HashTable<string, string>? query { get { return this._query; } }

		public override MessageHeaders headers {
			get {
				return this._headers;
			}
		}

		/**
		 * @since 0.3
		 */
		public Request (Connection connection, string method, URI uri, HashTable<string, string>? query = null) {
			Object (connection: connection);
			this._method = method;
			this._uri    = uri;
			this._query  = query;
		}

		public Request.with_method (string method, URI uri, HashTable<string, string>? query = null) {
			this (new Connection (), method, uri, query);
		}

		public Request.with_uri (URI uri, HashTable<string, string>? query = null) {
			Object (connection: new Connection ());
			this._uri   = uri;
			this._query = query;
		}

		public Request.with_query (HashTable<string, string>? query) {
			Object (connection: new Connection ());
			this._query = query;
		}
	}

	/**
	 * Test implementation of VSGI.Response to stub a response.
	 */
	public class Response : VSGI.Response {

		private MessageHeaders _headers = new MessageHeaders (MessageHeadersType.RESPONSE);

		public override MessageHeaders headers {
			get {
				return this._headers;
			}
		}

		public Response (Request req) {
			Object (request: req);
		}

		public Response.with_status (Request req, uint status) {
			Object (request: req, status: status);
		}
	}
}
