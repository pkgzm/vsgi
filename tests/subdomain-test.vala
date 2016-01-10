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
using Valum;
using VSGI.Test;

/**
 * @since 0.3
 */
public void test_subdomain () {
	var req   = new Request.with_uri (new Soup.URI ("http://127.0.0.1/"));
	var res   = new Response (req);
	var stack = new Queue<Value?> ();

	subdomain ("api", () => {
		assert_not_reached ();
	}, SubdomainFlags.NONE) (req, res, () => {}, stack);
}

/**
 * @since 0.3
 */
public void test_subdomain_joker () {
	{
		var req   = new Request.with_uri (new Soup.URI ("http://api.example.com/"));
		var res   = new Response (req);
		var stack = new Queue<Value?> ();

		subdomain("*", () => {}) (req, res, () => {
			assert_not_reached ();
		}, stack);
	}

	{
		var req   = new Request.with_uri (new Soup.URI ("http://example.com/"));
		var res   = new Response (req);
		var stack = new Queue<Value?> ();

		subdomain("*", () => {
			assert_not_reached ();
		}) (req, res, () => {}, stack);
	}
}

/**
 * @since 0.3
 */
public void test_subdomain_strict () {
	var req   = new Request.with_uri (new Soup.URI ("http://dev.api.example.com/"));
	var res   = new Response (req);
	var stack = new Queue<Value?> ();

	subdomain ("api", () => {}) (req, res, () => { assert_not_reached (); }, stack);
	subdomain ("dev.api", () => {}) (req, res, () => { assert_not_reached (); }, stack);
	subdomain ("api", () => { assert_not_reached (); }, SubdomainFlags.STRICT) (req, res, () => {}, stack);
	subdomain ("dev.api.example.com", () => {}, SubdomainFlags.STRICT, 0) (req, res, () => { assert_not_reached (); }, stack);
}

/**
 * @since 0.3
 */
public void test_subdomain_extract () {
	assert (0 == extract_subdomains ("com").length);
	assert (0 == extract_subdomains ("example.com").length);
	assert (2 == extract_subdomains ("example.com", 0).length); // keep all the labels
	assert (0 == extract_subdomains ("example.com", 3).length); // skip more labels than provided

	var labels = extract_subdomains ("api.example.com");
	assert (1 == labels.length);
	assert ("api" == labels[0]);

	labels = extract_subdomains ("v1.api.example.com");
	assert (2 == labels.length);
	assert ("v1" == labels[0]);
	assert ("api" == labels[1]);
}

