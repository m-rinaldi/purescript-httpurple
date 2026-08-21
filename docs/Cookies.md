# Cookies

HTTPurple 🪁 provides helpers for reading cookies from requests and setting them on responses in the `HTTPurple.Cookie` module, so you don't have to parse the `Cookie` request header or build the `Set-Cookie` response header yourself.

## TOC
1. [Reading request cookies](#reading-request-cookies)
1. [Setting response cookies](#setting-response-cookies)
1. [Cookie attributes](#cookie-attributes)
1. [Setting multiple cookies](#setting-multiple-cookies)
1. [Deleting a cookie](#deleting-a-cookie)

## Reading request cookies

`requestCookies` parses the `Cookie` header of a request into a `Map String String` of cookie names to (URL-decoded) values:

```purescript
router request@{ route: Home } = do
  let cookies = requestCookies request.headers
  case Map.lookup "session" cookies of
    Just sessionId -> ok $ "Welcome back, session " <> sessionId
    Nothing -> ok "No session cookie"
```

If there is no `Cookie` header, the result is an empty map. `requestCookies` splits the header on `;` into segments (one `name=value` chunk each); empty segments (e.g. from `;;` with nothing between, or a trailing `;`) are ignored, and only the first `=` in each segment is treated as the separator, so values may themselves contain `=`.

## Setting response cookies

`setCookie` builds a `ResponseHeaders` carrying a single `Set-Cookie` header for the given name and value. Pass it to any of the prime response helpers (`ok'`, `created'`, `notFound'`, etc.):

```purescript
router { route: Login } =
  ok' (setCookie "session" "abc123") "Logged in"
```

The cookie value is URL-encoded for you, and the secure `defaultAttributes` (`SameSite=Lax; HttpOnly; Secure`) are applied — see [Cookie attributes](#cookie-attributes) to change them.

## Cookie attributes

`setCookie'` builds on `setCookie` the same way, but additionally takes a record of attributes. You only need to specify the fields you care about — any you omit are filled in from `defaultAttributes` via [`Justifill`](https://github.com/thought2/purescript-justifill), and plain values (`3600`, `true`, `Lax`) are wrapped in `Just` for you automatically:

```purescript
router { route: Login } = do
  let headers = setCookie' "session" "abc123" { path: "/", maxAge: 3600 }
  ok' headers "Logged in"
```

This produces:

```
Set-Cookie: session=abc123; Path=/; Max-Age=3600; SameSite=Lax; HttpOnly; Secure
```

Notice `SameSite=Lax`, `HttpOnly`, and `Secure` appear even though the example never set them: `defaultAttributes` turns them on by default, following the [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#cookies):

- `httpOnly` keeps the cookie out of reach of JavaScript (guarding against theft via XSS)
- `secure` confines it to HTTPS connections
- `sameSite: Lax` withholds it from cross-site subrequests (guarding against CSRF)

<u>Only `path`, `domain`, and `maxAge` are left unset.</u> Override any default by passing the field explicitly, e.g. `{ httpOnly: false }` for a cookie your client-side JavaScript needs to read.

> **Local development over HTTP:** because `secure` is on by default, browsers will not send these cookies back over a plain `http://` connection — so a cookie you set may appear to vanish on the next request, and `requestCookies` comes back empty. Most browsers exempt `localhost`/`127.0.0.1` (treating them as trustworthy), but a non-localhost HTTP host (a LAN IP, a container hostname, a staging box) will drop the cookie. If cookies mysteriously fail over plain HTTP, pass `{ secure: false }` to opt out — but gate it behind an environment check (e.g. `{ secure: not isDev }`) rather than hardcoding it, so it can't accidentally ship disabled in production.

The available attributes are `path`, `domain`, `maxAge`, `httpOnly`, `secure`, and `sameSite` (`Strict`, `Lax`, or `None`).

Note that `sameSite: None` is only honoured by browsers when the cookie is also `secure: true` (the default); otherwise the cookie is rejected.

If you want to build the attributes once and reuse them across several cookies, build a `CookieAttributes` record directly via record update, e.g. `defaultAttributes { path = Just "/", sameSite = Just Strict }` — note the fields need `Just`-wrapped values here, unlike the bare values `cookie'`/`setCookie'` accept — and pass it as `attributes` in a plain `{ name, value, attributes }` record instead of using `cookie'`.

## Setting multiple cookies

A response can carry several `Set-Cookie` headers. **Do not** try to combine two `setCookie` results with `<>`:

```purescript
-- WRONG: one cookie is silently dropped
setCookie "a" "1" <> setCookie "b" "2"
```

The reason is that `ResponseHeaders` is a `Map` from header name to values, and its `Semigroup` instance merges with `Data.Map.union`, which on a shared key keeps one operand's value and discards the other's rather than combining them (specifically, `x <> y` keeps `y`'s value). Both operands have the same `Set-Cookie` key, so you end up sending only one cookie.

Use `addCookie` instead, folding over `Cookie` values built with `cookie`/`cookie'`. It appends to any `Set-Cookie` values already present (via `Map.insertWith (<>)`), so folding several calls accumulates every cookie. Each `addCookie` call's header value is appended after whatever was already accumulated, so cookies end up in the `Set-Cookie` headers in the order they were applied — chain calls with `#`, so the source order matches the resulting header order:

```purescript
router { route: Login } = do
  let headers = empty
        # addCookie (cookie' "session" "abc123" { path: "/" })
        # addCookie (cookie' "theme" "dark" { httpOnly: false })
  ok' headers "Logged in"
```

This produces two separate headers, in the order written above (each carrying the secure `defaultAttributes`, with `theme` opting out of `HttpOnly` so client-side JavaScript can read it):

```
Set-Cookie: session=abc123; Path=/; SameSite=Lax; HttpOnly; Secure
Set-Cookie: theme=dark; SameSite=Lax; Secure
```

`empty # addCookie c1 >>> addCookie c2` also type-checks and gives the same result, since `>>>` binds tighter than `#`.

For an arbitrary list of cookies, fold `addCookie` over it the same way:

```purescript
foldl (flip addCookie) empty [ cookie "a" "1", cookie "b" "2" ]
```

If you already have a `Cookie` value on hand (e.g. from `cookie`/`cookie'`) rather than a name-value pair, `cookieHeader` converts it to `ResponseHeaders` directly — it's what `setCookie` calls under the hood.

## Deleting a cookie

`clearCookie` builds a `ResponseHeaders` with an empty value and `Max-Age=0` for the named cookie, instructing the client to delete it:

```purescript
router { route: Logout } =
  ok' (clearCookie "session") "Logged out"
```

If the cookie was originally set with a `path` or `domain`, pass matching values to `clearCookie'`, since the client only clears a cookie whose scope matches exactly — anything you omit still falls back to `defaultAttributes`:

```purescript
router { route: Logout } =
  ok' (clearCookie' "session" { path: "/app" }) "Logged out"
```

To expire one cookie while setting or expiring others in the same response, fold `expireCookie`/`expireCookie'` (the `Cookie`-returning counterparts of `clearCookie`/`clearCookie'`) in with `addCookie` the same way:

```purescript
router { route: Logout } = do
  let headers = empty
        # addCookie (expireCookie "session")
        # addCookie (cookie "theme" "dark")
  ok' headers "Logged out, kept your theme"
```
