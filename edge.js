export default async function handleRequest(request) {
  const sp = new URLSearchParams(new URL(request.url).search)
  if (sp.has('arch') && sp.has('channel')) {
    const arch = sp.get('arch')
    const channel = sp.get('channel')
    const UPSTREAM_API = `https://scoop-services.azurewebsites.net/edge-backend?arch=${arch}&channel=${channel}`
    const response = await fetch(UPSTREAM_API, {
      method: "GET",
      headers: {
        "user-agent": "Deno/1.0 (Deno Deploy) Scoop/1.0 (https://scoop.sh)",
        "content-type": "application/x-www-form-urlencoded",
      },
    })

    if (response.ok) {
      const data = await response.json()
      if (sp.has('dl')) {
        const url = data['Url']
        return Response.redirect(url, 302)
      }

      return new Response(JSON.stringify(data), {
        headers: {
          "content-type": "application/json; charset=UTF-8",
        }
      })
    }

    return new Response(
      JSON.stringify({ message: "upstream api failed, please try again later" }),
      {
        status: 500,
        headers: {
          "content-type": "application/json; charset=UTF-8",
        },
      },
    )
  }

  return new Response(
    JSON.stringify({ message: "arch and channel parameter are required" }),
    {
      status: 500,
      headers: {
        "content-type": "application/json; charset=UTF-8",
      },
    },
  )
}
