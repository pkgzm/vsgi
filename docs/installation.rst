Installation
============

This document describes the compilation and installation process. Most of that
work is automated with `waf`_, a build tool written in Python.

.. _waf: https://code.google.com/p/waf/

Packages
--------

Packages for RPM and Debian based Linux distributions will be provided for
stable releases so that the framework can easily be installed in a container or
production environment.

Fedora
~~~~~~

RPM packages for Fedora (21, 22 and rawhide) are available from the
`arteymix/valum-framework`_ Copr repository.

.. _arteymix/valum-framework: https://copr.fedoraproject.org/coprs/arteymix/valum-framework/

.. code-block:: bash

    dnf copr enable arteymix/valum-framework

The `valum` package contains the shared library and `valum-devel` contains all
that is necessary to build an application.

.. code-block:: bash

    dnf install valum valum-devel

Nix
~~~

.. code-block:: bash

    nix-shell -p valum

Dependencies
------------

The following dependencies are minimal to build the framework under Ubuntu
12.04 LTS and should be satisfied by most recent Linux distributions.

+--------------+----------+
| Package      | Version  |
+==============+==========+
| vala         | latest   |
+--------------+----------+
| python       | latest   |
+--------------+----------+
| waf          | provided |
+--------------+----------+
| glib-2.0     | >=2.32   |
+--------------+----------+
| gio-2.0      | >=2.32   |
+--------------+----------+
| gio-unix-2.0 | >=2.32   |
+--------------+----------+
| gthread-2.0  | >=2.32   |
+--------------+----------+
| libsoup-2.4  | >=2.38   |
+--------------+----------+

Recent dependencies will enable more advanced features:

+-------------+---------+------------------------------------------------------+
| Package     | Version | Feature                                              |
+=============+=========+======================================================+
| glib-2.0    | >=2.38  | subprocess in tests                                  |
+-------------+---------+------------------------------------------------------+
| gio-2.0     | >=2.34  | CGI server uses the command line stdin which can be  |
|             |         | provided by DBus                                     |
+-------------+---------+------------------------------------------------------+
| gio-2.0     | >=2.40  | CLI arguments parsing                                |
+-------------+---------+------------------------------------------------------+
| gio-2.0     | >=2.44  | ``write_head_async`` in :doc:`vsgi/response` and     |
|             |         | `GLib.strv_contains`_ to lookup methods when         |
|             |         | producing an ``Allow`` header                        |
+-------------+---------+------------------------------------------------------+
| libsoup-2.4 | >=2.48  | new server API                                       |
+-------------+---------+------------------------------------------------------+
| libsoup-2.4 | >=2.50  | uses `Soup.ClientContext.steal_connection`_ directly |
+-------------+---------+------------------------------------------------------+

.. _GLib.strv_contains: http://valadoc.org/#!api=glib-2.0/GLib.strv_contains
.. _Soup.ClientContext.steal_connection: http://valadoc.org/#!api=libsoup-2.4/Soup.ClientContext.steal_connection

You can also install additional dependencies to build the examples, you will
have to specify the ``--enable-examples`` flag during the configure step.

+---------------+------------------------------------+
| Package       | Description                        |
+---------------+------------------------------------+
| json-glib-1.0 | JSON library                       |
+---------------+------------------------------------+
| libmemcached  | client for memcached cache storage |
+---------------+------------------------------------+
| libluajit     | embed a Lua VM                     |
+---------------+------------------------------------+

Download the sources
--------------------

You may either clone the whole git repository or download one of our
`releases from GitHub`_:

.. _releases from GitHub: https://github.com/antono/valum/releases

.. code-block:: bash

    git clone git://github.com/valum-framework/valum.git && cd valum

The ``master`` branch is a development trunk and is not guaranteed to be very
stable. It is always a better idea to checkout the latest tagged release.

Build
-----

.. code-block:: bash

    ./waf configure
    ./waf build

Install
-------

Installing the build files is optional and if you omit that step, make sure
that ``LD_LIBRARY_PATH`` points to the ``build`` folder where the shared
library has been generated.

.. code-block:: bash

    sudo ./waf install

The installation is usually prefixed by ``/usr/local``, which is generally not
in the dynamic library path. You have to export the ``LD_LIBRARY_PATH``
environment variable for it to work.

.. code-block:: bash

    export LD_LIBRARY_PATH=/usr/local/lib64 # just lib on 32-bit systems

Run the tests
--------------

.. code-block:: bash

    ./build/tests/tests

If any of them fail, please `open an issue on GitHub`_ so that we can tackle
the bug.

.. _open an issue on GitHub: https://github.com/valum-framework/valum/issues

Run the sample application
--------------------------

You can run the sample application from the ``build`` folder if you called
``./waf configure`` with the ``--enable-examples`` flag, it uses the
:doc:`vsgi/server/soup`.

.. code-block:: bash

    ./build/example/app/app
