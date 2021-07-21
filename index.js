import handlerAppxqq from "./appxqq.js"
import handlerEdge from "./edge.js"

async function handleRequest(request) {
  const { pathname } = new URL(request.url)

  // appxqq
  if (pathname === '/appxqq') {
    return handlerAppxqq(request)
  }

  // appxqq
  if (pathname === '/edge') {
    return handlerEdge(request)
  }

  return new Response(
    JSON.stringify({
      message: "need to specify an action",
      help: "https://github.com/chawyehsu/dorado/tree/api",
      actions: [
        "/appxqq",
        "/appxqq?dl",
        "/edge?channel=",
        "/edge?channel=&dl"
      ]
    }),
    {
      status: 200,
      headers: {
        "content-type": "application/json; charset=UTF-8",
      },
    },
  )
}

addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request))
})
