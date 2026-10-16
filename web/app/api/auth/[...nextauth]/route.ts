import NextAuth from "next-auth";
import { authOptions } from "@/lib/auth";
import { NextRequest } from "next/server";
import { getPublicBaseUrl } from "@/lib/url-utils";

function syncNextAuthUrl(req: NextRequest) {
  const publicBaseUrl = getPublicBaseUrl(req);
  if (publicBaseUrl && !publicBaseUrl.includes("localhost")) {
    process.env.NEXTAUTH_URL = publicBaseUrl;
  }
}

const nextAuthHandler = NextAuth(authOptions);

export async function GET(req: NextRequest, ctx: any) {
  syncNextAuthUrl(req);
  return nextAuthHandler(req, ctx);
}

export async function POST(req: NextRequest, ctx: any) {
  syncNextAuthUrl(req);
  return nextAuthHandler(req, ctx);
}
