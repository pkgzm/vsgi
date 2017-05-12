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

[ModuleInit]
public Type server_init (TypeModule type_module) {
	var status = global::FastCGI.init ();
	if (status != 0)
		error ("code %u: failed to initialize FCGX library", status);
	return typeof (VSGI.FastCGI.Server);
}

/**
 * FastCGI implementation of VSGI.
 */
[CCode (lower_case_cprefix = "vsgi_fastcgi_")]
namespace VSGI.FastCGI {

	private errordomain RequestError {
		FAILED
	}

	/**
	 * FastCGI Server using GLib.MainLoop.
	 */
	[Version (since = "0.1")]
	public class Server : VSGI.Server {

		[Version (since = "0.3")]
		[Description (blurb = "Listen queue depth used in the listen() call")]
		public int backlog { get; construct; default = 10; }

		private SList<Soup.URI> _uris = new SList<Soup.URI> ();

		public override SList<Soup.URI> uris {
			owned get {
				var copy_uris = new SList<Soup.URI> ();
				foreach (var uri in _uris) {
					copy_uris.append (uri.copy ());
				}
				return copy_uris;
			}
		}

		public override void listen (SocketAddress? address = null) throws GLib.Error {
			int fd;

			if (address == null) {
				fd = global::FastCGI.LISTENSOCK_FILENO;
				_uris.append (new Soup.URI ("fcgi+fd://%d/".printf (fd)));
			} else if (address is UnixSocketAddress) {
				var socket_address = address as UnixSocketAddress;

				fd = global::FastCGI.open_socket (socket_address.path, backlog);

				if (fd == -1) {
					throw new IOError.FAILED ("Could not open socket path '%s'.", socket_address.path);
				}

				_uris.append (new Soup.URI ("fcgi+unix://%s/".printf (socket_address.path)));
			} else if (address is InetSocketAddress) {
				var inet_address = address as InetSocketAddress;

				if (inet_address.get_family () == SocketFamily.IPV6) {
					throw new IOError.NOT_SUPPORTED ("The FastCGI backend does not support listening on IPv6 address.");
				}

				if (inet_address.get_address ().is_loopback) {
					throw new IOError.NOT_SUPPORTED ("The FastCGI backend cannot be restricted to the loopback interface.");
				}

				var port = inet_address.get_port () > 0 ? inet_address.get_port () : (uint16) Random.int_range (1024, 32768);

				fd = global::FastCGI.open_socket ((":%" + uint16.FORMAT).printf (port), backlog);

				if (fd == -1) {
					throw new IOError.FAILED ("Could not open TCP port '%" + uint16.FORMAT + "'.", port);
				}

				_uris.append (new Soup.URI (("fcgi://0.0.0.0:%" + uint16.FORMAT + "/").printf (port)));
			} else {
				throw new IOError.NOT_SUPPORTED ("The FastCGI backend only support listening from 'InetSocketAddress' and 'UnixSocketAddress'.");
			}

			accept_loop_async.begin (fd);
		}

		public override void listen_socket (Socket socket) {
			accept_loop_async.begin (socket.get_fd ());
		}

		public override void stop () {
			global::FastCGI.shutdown_pending ();
		}

		private async void accept_loop_async (int fd) {
			do {
				var connection = new Connection (fd);

				try {
					if (!yield connection.init_async (Priority.DEFAULT, null))
						break;
				} catch (GLib.Error err) {
					critical (err.message);
					break;
				}

				var req = new Request.from_cgi_environment (connection, connection.request.environment);
				var res = new Response (req);

				handler.handle_async.begin (req, res, (obj, result) => {
					try {
						handler.handle_async.end (result);
					} catch (Error err) {
						critical ("%s", err.message);
					}
				});
			} while (true);
		}

		/**
		 * {@inheritDoc}
		 */
		private class Connection : IOStream, AsyncInitable {

			public int fd { construct; get; }

			public global::FastCGI.request request;

			private InputStream _input_stream;
			private OutputStream _output_stream;

			public override GLib.InputStream input_stream {
				get {
					return _input_stream;
				}
			}

			public override GLib.OutputStream output_stream {
				get {
					return this._output_stream;
				}
			}

			public Connection (int fd) {
				Object (fd: fd);
			}

			public async bool init_async (int priority = Priority.DEFAULT, Cancellable? cancellable = null) throws GLib.Error {
				// accept a request
				var request_status = global::FastCGI.request.init (out request, fd);

				if (request_status != 0) {
					throw new RequestError.FAILED ("could not initialize FCGX request (code %d)",
					                               request_status);
				}

				new IOChannel.unix_new (fd).add_watch_full (priority, IOCondition.IN, init_async.callback);

				yield;

				// accept loop
				IOSchedulerJob.push ((job) => {
					if (request.accept () < 0) {
						return true;
					}
					job.send_to_mainloop_async (init_async.callback);
					return false;
				}, priority, cancellable);

				yield;

				_input_stream  = new InputStream (fd, request.in);
				_output_stream = new OutputStream (fd, request.out, request.err);

				return true;
			}

			~Connection () {
				request.finish ();
				request.close (false); // keep the socket open
			}
		}
	}
}
