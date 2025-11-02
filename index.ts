import handlerAliyunDrive from './alipan.ts'
import handlerAppxqq from './appxqq.ts'
import handlerEdge from './edge.ts'
import handleKook from './kook.ts'
import handlerNeteaseUU from './neteaseuu.ts'
import handleSwift from './swift.ts'
import handleTianyiEcloud from './tianyi-ecloud.ts'
import { toHexPolyfill } from './utils.ts'

toHexPolyfill()

async function handler(request: Request): Promise<Response> {
  const { pathname } = new URL(request.url)

  // aliundrive/alipan
  if (pathname === '/alipan') {
    return await handlerAliyunDrive(request)
  }

  // swift (temporary fix)
  if (pathname === '/swift-tmp') {
    return await handleSwift(request)
  }

  // appxqq
  if (pathname === '/appxqq') {
    return await handlerAppxqq(request)
  }

  // edge
  if (pathname === '/edge') {
    return await handlerEdge(request)
  }

  // kook
  if (pathname === '/kook') {
    return await handleKook(request)
  }

  // neteaseuu
  if (pathname === '/neteaseuu') {
    return await handlerNeteaseUU(request)
  }

  // tianyi-ecloud
  if (pathname === '/tianyi-ecloud') {
    return await handleTianyiEcloud(request)
  }

  return new Response(
    JSON.stringify({
      message: 'need to specify an action',
      help: 'https://github.com/chawyehsu/dorado/tree/api',
      actions: [
        '/alipan',
        '/alipan?version=&dl',
        '/appxqq',
        '/appxqq?dl',
        '/edge?arch=&channel=',
        '/edge?arch=&channel=&dl',
        '/tianyi-ecloud',
        '/tianyi-ecloud?dl',
        '/neteaseuu?version=',
        '/kook?version=',
      ],
    }),
    {
      status: 200,
      headers: {
        'content-type': 'application/json; charset=UTF-8',
      },
    },
  )
}

Deno.serve(handler)
