import { NextRequest } from "next/server";

/**
 * Resolves the true public base URL of the application, taking into account
 * reverse proxy headers (Nginx X-Forwarded-Host, X-Forwarded-Proto) in production.
 *
 * This guarantees that redirects and OAuth callbacks use `https://hackathon.mataceria.my.id`
 * instead of internal Docker container addresses (e.g. http://localhost:3000).
 */
export function getPublicBaseUrl(req?: NextRequest): string {
  if (req) {
    const forwardedHost = req.headers.get("x-forwarded-host");
    const host = forwardedHost || req.headers.get("host") || "";
    const forwardedProto = req.headers.get("x-forwarded-proto");
    const proto =
      forwardedProto ||
      (host && !host.includes("localhost") && !host.includes("127.0.0.1") ? "https" : "http");

    // If request comes through domain name (e.g. hackathon.mataceria.my.id)
    if (
      host &&
      (host.includes("hackathon.mataceria.my.id") ||
        (!host.includes("localhost") && !host.includes("127.0.0.1")))
    ) {
      return `${proto}://${host}`.replace(/\/$/, "");
    }
  }

  // Fallbacks in priority order
  if (process.env.APP_URL && !process.env.APP_URL.includes("localhost")) {
    return process.env.APP_URL.replace(/\/$/, "");
  }
  if (process.env.NEXTAUTH_URL && !process.env.NEXTAUTH_URL.includes("localhost")) {
    return process.env.NEXTAUTH_URL.replace(/\/$/, "");
  }
  if (process.env.NEXT_PUBLIC_APP_URL && !process.env.NEXT_PUBLIC_APP_URL.includes("localhost")) {
    return process.env.NEXT_PUBLIC_APP_URL.replace(/\/$/, "");
  }

  // Default fallback for local development
  return "http://localhost:3000";
}

/**
 * Safely resolves an absolute redirection URL matching the user's public entry domain.
 */
export function resolveRedirectUrl(req: NextRequest, targetPath: string): URL {
  const base = getPublicBaseUrl(req);
  const cleanPath = targetPath.startsWith("/") ? targetPath : `/${targetPath}`;
  return new URL(`${base}${cleanPath}`);
}
