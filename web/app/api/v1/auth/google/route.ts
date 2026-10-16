import { NextRequest, NextResponse } from "next/server";
import { authService } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { UserRole } from "@/domain/auth/user.entity";
import { getPublicBaseUrl, resolveRedirectUrl } from "@/lib/url-utils";

export async function OPTIONS() {
  return HttpResponse.corsOptions();
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { email, fullName, role } = body;

    if (!email || typeof email !== "string" || !email.includes("@")) {
      return HttpResponse.error(
        "Email Google tidak valid atau belum diisi",
        "VALIDATION_ERROR",
        400
      );
    }

    let mappedRole: UserRole = "PATIENT";
    if (role === "dokter" || role === "OPHTHALMOLOGIST") {
      mappedRole = "OPHTHALMOLOGIST";
    } else if (role === "admin" || role === "ADMIN") {
      mappedRole = "ADMIN";
    }

    const authResult = await authService.loginWithGoogleProfile({
      email,
      fullName: fullName || email.split("@")[0],
      role: mappedRole,
    });

    return HttpResponse.success(authResult);
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const role = searchParams.get("role") || "pengguna";

  const clientId = process.env.GOOGLE_CLIENT_ID;
  const appUrl = getPublicBaseUrl(req);
  const redirectUri = `${appUrl}/api/v1/auth/google/callback`;

  if (!clientId || clientId.trim() === "") {
    // If Google Client ID is not yet configured in .env, redirect back with error code
    return NextResponse.redirect(
      resolveRedirectUrl(req, `/login/${role}?error=google_not_configured`)
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
