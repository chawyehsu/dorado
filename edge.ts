import { decode } from "https://deno.land/std@0.196.0/encoding/base64.ts";
import { bufferToHex } from "https://deno.land/x/hextools@v1.0.0/mod.ts";
import {
  BufReader,
  BufWriter,
} from "https://deno.land/std@0.196.0/io/mod.ts";
import { TextProtoReader } from "https://deno.land/std@0.158.0/textproto/mod.ts";

interface DownloadInfo {
  FileId: string;
  Url: string;
  TimeLimitedUrl: boolean;
  Hashes: {
      Sha1: string;
      Sha256: string;
  };
}

// Deno Deploy doesn't have this cert, and Deno.createHttpClient isn't stable yet,
// so this is the best I could come up with.
const caCert = await Deno.readTextFile(new URL("assets/Microsoft Update Secure Server CA 2.1.crt", import.meta.url));

async function fetchVersion(channel: string, arch: string, version?: string | null): Promise<Response> {
  const conn = await Deno.connectTls({
    hostname: "msedge.api.cdp.microsoft.com",
    port: 443,
    caCerts: [caCert],
  });
  const writer = new BufWriter(conn);
  const encoder = new TextEncoder();

  const path = version === undefined || version === null
    ? "/latest?action=select"
    : `/${version}/files?action=GenerateDownloadInfo`;

  const lines = [
    `POST /api/v1.1/contents/Browser/namespaces/Default/names/msedge-${channel}-win-${arch.toUpperCase()}/versions/${path} HTTP/1.1`,
    "Host: msedge.api.cdp.microsoft.com",
    "Connection: keep-alive",
    `Content-Length: 57`,
    "Content-Type: application/json",
    "User-Agent: Microsoft Edge Update/1.3.129.35;winhttp",
    "",
    '{"targetingAttributes":{"Updater":"MicrosoftEdgeUpdate"}}',
  ]
  await writer.write(encoder.encode(lines.join("\r\n") + "\r\n\r\n"));
  await writer.flush();

  const bufReader = new BufReader(conn);
  const tpReader = new TextProtoReader(bufReader);
  const statusLine = await tpReader.readLine();
  if (statusLine === null) {
    throw new Error("Malformed HTTP response");
  }
  const [_, status, statusText] = statusLine.match(/HTTP\/1.1 (\d{3}) (.*)/) ?? [];
  const headers = await tpReader.readMimeHeader();

  if (headers === null) {
    return new Response(null, {
        status: Number(status),
        statusText,
    });
  }
  const body = new Uint8Array(Number(headers.get("content-length")));
  await bufReader.readFull(body);

  return new Response(body, {
    status: Number(status),
    statusText,
    headers: headers ?? undefined,
  });
}

export default async function handleRequest(request: Request): Promise<Response> {
  const sp = new URLSearchParams(new URL(request.url).search)
  if (!sp.has("arch") || !sp.has("channel")) {
    return new Response(
      JSON.stringify({ message: "arch and channel parameter are required" }),
      {
        status: 400,
        headers: {
          "content-type": "application/json; charset=UTF-8",
        },
      },
    )
  }

  let arch = sp.get("arch")!.toLowerCase();
  if (arch === "86" || arch === "64") {
    arch = `x${arch}`;
  }

  const channel = sp.get("channel")!.toLowerCase();
  const version = sp.get("version");

  const response = await fetchVersion(channel, arch, version);
  if (!response.ok) {
    const text = await response.text();
    const body = {
      message: "upstream api failed, please try again later",
      details: {
        status: response.status,
        statusText: response.statusText,
        body: text,
      }
    };

    return new Response(JSON.stringify(body), {
      status: response.status,
      headers: {
        "content-type": "application/json; charset=UTF-8",
      },
    });
  }

  const data = await response.json();
  if (!version) {
    return new Response(JSON.stringify(data.ContentId), {
      headers: {
        "content-type": "application/json; charset=UTF-8",
      }
    });
  }

  // Find the install package and not the update packages
  const item = data.find((item: DownloadInfo) => item.FileId.split("_").length == 3);
  if (sp.has("dl")) {
    return Response.redirect(item.Url, 302);
  }

  // Convert hashes to a format Scoop understands
  item.Hashes.Sha1 = bufferToHex(decode(item.Hashes.Sha1));
  item.Hashes.Sha256 = bufferToHex(decode(item.Hashes.Sha256));

  return new Response(JSON.stringify(item), {
    headers: {
      "content-type": "application/json; charset=UTF-8",
    }
  });
}
