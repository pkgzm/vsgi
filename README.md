Valum micro-framework
=====================

[![Build Status](https://travis-ci.org/valum-framework/valum.svg?branch=master)](https://travis-ci.org/valum-framework/valum)
[![Documentation Status](https://readthedocs.org/projects/valum-framework/badge/?version=latest)](https://readthedocs.org/projects/valum-framework/?badge=latest)
[![Coverage Status](https://coveralls.io/repos/valum-framework/valum/badge.svg?branch=master)](https://coveralls.io/r/valum-framework/valum?branch=master)

Valum is a web micro-framework entirely written in the
[Vala](https://wiki.gnome.org/Projects/Vala) programming language.

```vala
using Valum;
using VSGI.Soup;

var app = new Router ();

app.get ("", (req, res) => {
    res.write ("Hello world!".data);
    res.end ();
});

new Server (app).run ();
```


Installation
------------

The installation process is fully documented in the
[user documentation](http://valum-framework.readthedocs.org/en/latest/installation.html).


Features
--------

 - router with scope, typed parameters and low-level utilities
 - simple Request-Response mechanism
 - complete integration of [FastCGI](http://www.fastcgi.com/drupal/) protocol
 - [CTPL](http://ctpl.tuxfamily.org/), a simple templating engine
 - extensive documentation available at [valum.readthedocs.org](http://valum.readthedocs.org/en/latest)


Contributing
------------

Valum is built by the community under the
[LGPL](https://www.gnu.org/licenses/lgpl.html) license, so anyone can
contribute.

 1. fork repository
 2. pick one task from TODO.md or [GitHub issues](https://github.com/antono/valum/issues)
 3. let us know what you will do (or attempt!)
 4. code
 5. make a pull request of your amazing changes
 6. let everyone enjoy :)

We use [semantic versionning](http://semver.org/), so make sure that your
changes

 * does not alter api in bugfix release
 * does not break api in minor release
 * breaks api in major (we like it that way!)


Discussions and help
--------------------

You can get help with Valum from different sources:

 - mailing list: [vala-list](https://mail.gnome.org/mailman/listinfo/vala-list).
 - IRC channel: #vala at irc.gimp.net
 - [Google+ page for Vala](https://plus.google.com/115393489934129239313/)
 - issues on [GitHub](https://github.com/antono/valum/issues) with the
   `question` label
