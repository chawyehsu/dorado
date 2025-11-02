interface KookApiResponse {
  url?: string
}

export default async function handleRequest(
  request: Request,
): Promise<Response> {
  const sp = new URLSearchParams(new URL(request.url).search)
  const version = sp.get('version')
  if (!version) {
    return new Response(
      JSON.stringify({ message: 'version parameter is required' }),
      {
        status: 400,
        headers: {
          'content-type': 'application/json; charset=UTF-8',
        },
      },
    )
  }

  const UPSTREAM_API =
    'https://www.kookapp.cn/api/v2/updates/latest-version?platform=windows'

  const res = await fetch(UPSTREAM_API, {
    method: 'GET',
    headers: {
      'user-agent': 'Deno/1.0 (Deno Deploy) Scoop/1.0 (+https://scoop.sh)',
      'content-type': 'application/x-www-form-urlencoded',
      'accept-encoding': 'gzip, deflate, br',
    },
  })
  const data: KookApiResponse = await res.json()

  if (!data.url) {
    return new Response(
      JSON.stringify({
        message: 'upstream api failed, please try again later',
      }),
      {
        status: 500,
        headers: {
          'content-type': 'application/json; charset=UTF-8',
        },
      },
    )
  }

  const regex = `Kook_PC_Setup_v${version}_`
  if (!data.url.match(new RegExp(regex))) {
    return new Response(
      JSON.stringify({ message: 'version parameter mismatch' }),
      {
        status: 400,
        headers: {
          'content-type': 'application/json; charset=UTF-8',
        },
      },
    )
  }

  return Response.redirect(data.url, 302)
}
