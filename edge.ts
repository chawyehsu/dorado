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

const encoder = new TextEncoder();

// Deno Deploy doesn't have this cert, and Deno.createHttpClient isn't stable yet,
// so this is the best I could come up with.
// Microsoft Update Secure Server CA 2.1
const caCert = `-----BEGIN CERTIFICATE-----
MIIHADCCBOigAwIBAgITMwAAAAq4kaLIClCl3wAAAAAACjANBgkqhkiG9w0BAQsF
ADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
AxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcN
MTIwNjIxMTczMzM1WhcNMjcwNjIxMTc0MzM1WjCBhDELMAkGA1UEBhMCVVMxEzAR
BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
Y3Jvc29mdCBDb3Jwb3JhdGlvbjEuMCwGA1UEAxMlTWljcm9zb2Z0IFVwZGF0ZSBT
ZWN1cmUgU2VydmVyIENBIDIuMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
ggIBAIsV6r17t2cxpIcOFIqSCXjB1Wi28ppZ4H/IGmdG3jGaAqrI50dJ6ak6h0yF
/jwuG0cERatWEbtguFI2idurX8gorvMbOaC/BqJk2azmI0PNaZWQ5a+Ib5jb+yLC
ByxI8UyFA1pqzUBh4SIaIuObKz3s44ubK8xVZYEUuszhiv7QvDonFzpHQfu4MPEE
MtHVOW56RssyKuFzdos1OhXYjpSCZni+kXwLowGugOMJhCxpK9mMJNTyPzUHd+Gf
41RDX+yK/SRYT6NUYNIAX3VEK9Lvf7s+tl77d/vhnmalQB8xPNDjMgS4p+ulEt9w
Gmrwo1IQuFjDiH2kszH5f2FTri3Mgjr2SotDZPLMk93g1RQuSAZmEED2I+efOVC4
dyESKUB7/Hf0MNNeujezZyA7ih3/mXg5ppuFz61acjBRKlmNKBc1MnqUHbBSBX9K
BuBNfeqW1SsMoy2JWrVcKqvEtqbTX2mfEEMA/aecmMO6S7vo2CM8c7OBFjY9sbxh
msAS3TC0kLffSK3YF2oDMqdgW57PGm14ZVSP01KO5W6E8sq43xkd2rT6KZ7IHqPW
18QwPsHbffy5eQbgumeadF3cryR7ElIt1VccANw9mqA+km1DWoL3tYb+nlS0MMKd
YNFPT903Vx0chN5ej9CQXHBu4zq3Rkmz7wF5YJVEO9gZ0CJlAgMBAAGjggFjMIIB
XzAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU0vI9hHSGG1CFql3lpQea8EfT
LmkwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMBIGA1Ud
EwEB/wQIMAYBAf8CAQAwHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEjiTQw
WgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
cmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBeBggr
BgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
bS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDATBgNV
HSUEDDAKBggrBgEFBQcDATANBgkqhkiG9w0BAQsFAAOCAgEAopvuA2tH2+meSVsn
VatGbRha0QgVj4Saq5ZlNJW0Qpyf4pRyuZT+KLK2/Ia6ZzUugrtLAECro+hIEB5K
29S+pnY1nzSMn+lSZJwGWfRZTWn466g21wKFMInPpO3QB8yfzr2zwniissTh8Jkn
8Uejsz/EkGU520E3FCT26dlU1YtzHnrcZ7d8qp4tLFEVeSsrxkqpYJQxalJIZ3HH
uhOG3BQLmLtJDs822W1knAR6c+iYuLDbJ9o8TnOY9/lIWy8Vv2z3i+LEn27O7QSl
vTZHyCgFJMgjhELOSLliGhA3411RX8kyCE9AJ1OLufdcejOYwMG0POpmrj3s/Q5n
+Bfm5JQHaGGCUy7XfKMRbyYJejjcC1YtLS5HVxBf/Smh7nruCYIpDimr8AIgJCVz
ekbVxTHzuSYdXLZgnpUzu71MgFGSBh5DAHaErUmwwztK/TIyak9zwodWouV+2clp
HYgCWASmHOkRysH6T3n46pDmexplqG5dGM5QNrCjn5u1ptgVdDPR1LGHTT+KGT+F
45owrOFOwUOuz2H6RFUPgwPkCOYnK4bM17tdlaQ4DrtghSqL03ZaPFdASXHa+fZB
1ro0E6c8fv9vqaf7NvhIQE+BepDH87/f3gCGCzZ0pTNnbRH2k2VCc4CbaWZRKWg8
5c95ZPsdlHeynrIjVZ76ubrfiuM=
-----END CERTIFICATE-----
`;

async function fetchVersion(channel: string, arch: string, version?: string | null): Promise<Response> {
  const conn = await Deno.connectTls({
    hostname: "msedge.api.cdp.microsoft.com",
    port: 443,
    caCerts: [caCert],
  });
  const writer = new BufWriter(conn);

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
