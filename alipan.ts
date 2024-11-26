export default async function handleRequest(request: Request): Promise<Response> {
  const UPSTREAM_API = 'https://luban.m.qq.com/api/public/software-manager/softwareProxy'
  // https://pc.qq.com/detail/16/detail_28156.html
  const BODY = 'cmdid=3318&jprxReq%5Breq%5D%5Bsoft_id_list%5D%5B%5D=28156'

  const response = await fetch(UPSTREAM_API, {
    method: "POST",
    body: BODY,
    headers: {
      "user-agent": "Deno/1.0 (Deno Deploy) Scoop/0.5.2 (+https://scoop.sh)",
      "content-type": "application/x-www-form-urlencoded",
    },
  })

  if (response.ok) {
    const data = await response.json()
    const resp = data.resp
    if (resp.retCode !== 0) {
      return new Response(
        JSON.stringify({ message: "upstream api returns error" }),
        {
          status: 500,
          headers: {
            "content-type": "application/json; charset=UTF-8",
          },
        },
      )
    }

    const url = resp.soft_list[0].download_https_url
    const version = url.match(/aDrive-(\d+\.\d+\.\d+).exe/)?.[1]

    const sp = new URLSearchParams(new URL(request.url).search)
    if (sp.has('dl')) {
      const req_version = sp.get("version");
      if (req_version && req_version !== version) {
        return new Response(
          JSON.stringify({
            message: "version mismatch",
            requested: req_version,
            available: version
          }),
          {
            status: 404,
            headers: {
              "content-type": "application/json; charset=UTF-8",
            },
          },
        )
      }

      return Response.redirect(url, 302)
    }

    return new Response(JSON.stringify({
      'url': url,
      'version': version
    }), {
      headers: {
        "content-type": "application/json; charset=UTF-8",
      }
    })
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
