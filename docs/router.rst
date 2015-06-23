Router
======

Router is the core component of Valum. It dispatches request to the right
handler and processes certain error conditions described in
:doc:`redirection-and-error`.

HTTP methods
------------

Callback can be connected to HTTP methods via a list of helpers having the
``Route.HandlerCallback`` delegate signature:

.. code:: vala

    app.get ("rule", (req, res) => {});

The rule has to respect the rule syntax described in :doc:`route`. It will be
compiled down to a regex which named groups are made accessible through
:doc:`vsgi/request` parameters.

Helpers for the HTTP/1.1 protocol and the extra ``TRACE`` methods are included.

-  ``get``
-  ``post``
-  ``put``
-  ``delete``
-  ``connect``
-  ``trace``

This is an example of ``POST`` request handling using `Soup.Form`_ to decode
the ``application/x-www-form-urlencoded`` body of the :doc:`vsgi/request`.

.. _Soup.Form: http://valadoc.org/#!api=libsoup-2.4/Soup.Form

.. code:: vala

    app.post ("login", (req, res) => {
        var buffer = new MemoryOutputStream.resizable ();

        // consume the request body
        buffer.splice (req.body, OutputStreamSpliceFlags.CLOSE_SOURCE);

        var data = Soup.Form.decode ((string) buffer.get_data ());

        var username = data["username"];
        var password = data["password"];

        // assuming you have a session implementation in your app
        var session = new Session.authenticated_by (username, password);
    });

It is also possible to use a custom HTTP method via the ``method``
function.

.. code:: vala

    app.method ("METHOD", "rule", (req, res) => {});

:doc:`vsgi/request` provide an enumeration of HTTP methods for your
convenience.

.. code:: vala

    app.method (Request.GET, "rule", (req, res) => {});

Multiple methods can be captured with ``methods`` and ``all``.

.. code:: vala

    app.all ("", (req, res) => {
        // matches all methods registered in VSGI.Request.METHODS
    });

    app.methods (Request.GET, Request.POST, "", (req, res) => {
        // matches GET and POST
    });

Regular expression
------------------

.. code:: vala

    app.regex (/home/, (req, res) => {
        // matches /home
    });

Matcher callback
----------------

Request can be matched by a simple callback, but you have to be cautious if you
want to fill request parameters. You must respect the `populate if match` rule,
otherwise you will experience inconsistencies.

.. code:: vala

    app.matcher (Request.GET, (req) => { return req.uri.get_path () == "/home"; }, (req, res) => {
        // matches /home
    });

Status handling
---------------

Thrown status code can be handled by a :doc:`route` handler callback.

The received :doc:`vsgi/request` and :doc:`vsgi/response` object are in the
same state they were when the status was thrown, except for the request
parameters that contains two additional keys:

-  ``code`` for the status code
-  ``message`` for the status message

.. _GLib.Error

.. code:: vala

    app.status (Soup.Status.NOT_FOUND, (req, res) => {
        // produce a 404 page...
    });

Similarly to conventional request handling, the ``next`` continuation can be
invoked to jump to the next status handler in the queue.

.. code:: vala

    app.status (Soup.Status.NOT_FOUND, (req, res, next) => {
        next ();
    });

    app.status (Soup.Status.NOT_FOUND, (req, res) => {
        res.status = 404;
        res.body.write ("Not found!".data);
    });

:doc:`redirection-and-error` can be thrown during the status handling, they
will be caught by the ``Router`` and processed accordingly.

.. code:: vala

    // turns any 404 into a permanent redirection
    app.status (Soup.Status.NOT_FOUND, (req, res) => {
        throw new Redirection.PERMANENT ("http://example.com");
    });

Scoping
-------

Scoping is a powerful prefixing mechanism for rules and regular expressions.
Route declarations within a scope will be prefixed by ``<scope>/``. There is an
implicit initial scope so that all rules are automatically rooted with (``/``).

The ``Router`` maintains a scope stack so that when the program flow enter
a scope, it pushes the fragment on top of that stack and pops it when it exits.

The default separator is a ``/`` and it might become possible to change it in
a future release.

.. code:: vala

    app.scope ("admin", (admin) => {
        // admin is a scoped Router
        app.get ("users", (req, res) => {
            // matches /admin/users
        });
    });

    app.get ("users", (req, res) => {
        // matches /users
    });

Subrouting
----------

Since ``VSGI.ApplicationCallback`` is type compatible with
``Route.HandlerCallback``, it is possible to delegate request handling to
another VSGI-compliant application.

.. code:: vala

    var app = new Router ();
    var api = new Router ();

    // delegate all GET requests to api router
    app.get ("<any:any>", api.handle);

This feature can be used to combine independently working applications in
a single one, as opposed to :doc:`module`, which are designed to be
specifically integrated in a working application.

It is important to be cautious since the pair of request-response may be the
target of side-effects such as:

-  parent router ``setup`` and ``teardown`` signals can operate before and
   after the delegated handler
-  matcher that matched the request before being delegated may initialize the
   :doc:`vsgi/request` parameters

In the example, the ``<any:any>`` parameter will initialize the
:doc:`vsgi/request` parameters.

Next
----

The :doc:`route` handler takes a callback as an optional third argument. This
callback is a continuation that will continue the routing process to the next
matching route.

.. code:: vala

    app.get ("", (req, res, next) => {
        message ("pre");
        next (); // keep routing
    });

    app.get ("", (req, res) => {
        // this is invoked!
    });

