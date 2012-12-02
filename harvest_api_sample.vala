
// MIT License
// ===========

// Copyright (c) 2012 Tomasz Kowalewski <me@tkowalewski.pl>

// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

/*

Based on:
	https://github.com/tkowalewski/harvest-gtk

Requirements
- valac-0.18
- libsoup-2.4

How to compile:
	valac-0.18 --pkg libsoup-2.4 ./harvest_api_sample.vala

How to run:
	./harvest_api_sample

How to use:
	Please fill variables, compile and run

*/

using Soup;

public static int main (string[] args) {
	string harvest_subdomain = ""; // Your subdomain
	string harvest_email = ""; // Your email
	string harvest_password = ""; // Your password
	string action = "daily"; // Action
	string xml = ""; // Xml data. If you want to POST

	string url = "https://%s.harvestapp.com/%s".printf(harvest_subdomain, action);
	string method = "GET";
	int status = 200;
	if (xml.length > 0) {
		method = "POST";
	}
	var session = new Soup.SessionAsync();
	var message = new Soup.Message (method, url);
	message.set_http_version(Soup.HTTPVersion.1_1);
	
	message.request_headers.append("Content-Type", "application/xml");
	message.request_headers.append("Accept", "application/xml");
	message.request_headers.append("User-Agent", "Harvest-Api-Sample-Vala");

	string authorization = Base64.encode("%s:%s".printf(harvest_email, harvest_password).data);
	message.request_headers.append("Authorization", "Basic %s".printf(authorization));

	if (method == "POST") {
		status = 201;
		StringBuilder body = new StringBuilder(xml);
		message.set_request( "application/xml", MemoryUse.COPY, body.data);
	}

	if (session.send_message(message) == status) {
		stdout.printf((string)message.response_body.flatten().data);
	}
	session.abort();
	return 1;
}
