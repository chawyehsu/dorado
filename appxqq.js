async function handleRequest(request) {
  const UPSTREAM_API = 'https://store.rg-adguard.net/api/GetFiles'
  // `9nhlgf0zwc5s` refers to:
  // https://www.microsoft.com/zh-cn/p/qq%E6%A1%8C%E9%9D%A2%E7%89%88/9nhlgf0zwc5s
  const BODY = 'type=ProductId&url=9nhlgf0zwc5s&ring=Retail&lang=en-US'

  const response = await fetch(UPSTREAM_API, {
    method: "POST",
    body: BODY,
    headers: {
      "user-agent": "Deno/1.0 (Deno Deploy) Scoop/1.0 (https://scoop.sh)",
      "content-type": "application/x-www-form-urlencoded",
    },
  })

  if (response.ok) {
    const text = await response.text()
    const re = new RegExp(/href="(?<url>http:\/\/t.+?)".+?(?<name>90.+?4B1ECA_(?<version>[\d.]+).+?a99ra4d2cbcxa.appx).+?">(?<sha1>\w{40})</sm)
    const groups = text.match(re)

    if (groups) {
      const url = groups[1]
      const name = groups[2]
      const version = groups[3]
      const hash = groups[4]

      const { pathname } = new URL(request.url)

      if (pathname === '/dl') {
        return Response.redirect(url, 302)
      }

      if (pathname === '/checkver') {
        return new Response(JSON.stringify({
          'version': version,
          'name': name
        }), {
          headers: {
            "content-type": "application/json; charset=UTF-8",
          }
        })
      }

      if (pathname === '/hash') {
        return new Response(JSON.stringify({
          'sha1': hash,
          'name': name
        }), {
          headers: {
            "content-type": "application/json; charset=UTF-8",
          }
        })
      }

      return new Response(JSON.stringify({
        'url': url,
        'version': version,
        'name': name,
        'sha1': hash
      }), {
        headers: {
          "content-type": "application/json; charset=UTF-8",
        }
      })
    }
  }

  return new Response(
    JSON.stringify({ message: "couldn't process your request" }),
    {
      status: 500,
      headers: {
        "content-type": "application/json; charset=UTF-8",
      },
    },
  )
}

addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request))
})
