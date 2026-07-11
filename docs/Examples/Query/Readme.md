# Query Example

This is a basic example of handling the HTTP `QUERY` method
([RFC 10008](https://www.rfc-editor.org/rfc/rfc10008)). It responds to a
`QUERY` on any path with the query content echoed back in the response body,
and to a `GET` on the same path with an explanatory message, to illustrate
that both share a route but are distinguished by method.

To run the example server, run:

```bash
nix-shell --run 'example Query'
```

Or, without nix:

```bash
spago -x test.dhall run --main Examples.Query.Main
```
