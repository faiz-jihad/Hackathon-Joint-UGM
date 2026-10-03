import { NextRequest, NextResponse } from "next/server";
import { HttpResponse } from "@/lib/http-response";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const role = searchParams.get("role") || "pengguna";

  const clientId = process.env.GOOGLE_CLIENT_ID;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";
  const redirectUri = `${appUrl}/api/v1/auth/google/callback`;

  if (!clientId || clientId.trim() === "") {
    // If Google Client ID is not yet configured in .env, redirect back with error code
    return NextResponse.redirect(
      new URL(`/login/${role}?error=google_not_configured`, req.url)
    );
  }

  const googleAuthUrl = new URL("https://accounts.google.com/o/oauth2/v2/auth");
  googleAuthUrl.searchParams.set("client_id", clientId);
  googleAuthUrl.searchParams.set("redirect_uri", redirectUri);
  googleAuthUrl.searchParams.set("response_type", "code");
  googleAuthUrl.searchParams.set("scope", "openid email profile");
  googleAuthUrl.searchParams.set("access_type", "offline");
  googleAuthUrl.searchParams.set("prompt", "select_account");
  googleAuthUrl.searchParams.set("state", role);

  return NextResponse.redirect(googleAuthUrl.toString());
}
