export default async function handleRequest(_: Request): Promise<Response> {
  const UPSTREAM_API = 'https://www.swift.org/download/'

  // Proxy the request to swift.org with explicit `accept-encoding` header,
  // return an uncompressed response to downstream scoop.
  return await fetch(UPSTREAM_API, {
    method: "GET",
    headers: {
      "user-agent": "Deno/1.0 (Deno Deploy) Scoop/1.0 (+https://scoop.sh)",
      "content-type": "application/x-www-form-urlencoded",
      "accept-encoding": "gzip, deflate, br",
    },
  })
}
