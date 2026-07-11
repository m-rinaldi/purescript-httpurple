module Examples.Query.Main where

import Prelude

import Data.Generic.Rep (class Generic)
import Effect.Aff (Aff)
import Effect.Console (log)
import HTTPurple (Method(..), Request, Response, ServerM, notFound, ok, serve, toString)
import Routing.Duplex (RouteDuplex')
import Routing.Duplex as RD
import Routing.Duplex.Generic as G

data Route = Test

derive instance Generic Route _

route :: RouteDuplex' Route
route = RD.root $ G.sum
  { "Test": G.noArgs
  }

-- | Route to the correct handler
router :: Request Route -> Aff Response
router { body, method: Query } = toString body >>= ok
router { method: Get } = ok "send a QUERY request with a body to see it echoed back"
router _ = notFound

-- | Boot up the server
main :: ServerM
main =
  serve { hostname: "localhost", port: 8080, onStarted } { route, router }
  where
  onStarted = do
    log " ┌───────────────────────────────────────────────┐"
    log " │ Server now up on port 8080                    │"
    log " │                                               │"
    log " │ To test, run:                                 │"
    log " │  > curl -XQUERY --data 'q=foo' localhost:8080 │"
    log " │    # => q=foo                                 │"
    log " └───────────────────────────────────────────────┘"
