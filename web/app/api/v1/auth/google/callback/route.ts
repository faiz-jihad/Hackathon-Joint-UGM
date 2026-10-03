import { NextRequest, NextResponse } from "next/server";
import { authService } from "@/lib/container";
import { UserRole } from "@/domain/auth/user.entity";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const code = searchParams.get("code");
  const state = searchParams.get("state") || "pengguna";
  const errorParam = searchParams.get("error");

  const appUrl = process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000";
  const redirectUri = `${appUrl}/api/v1/auth/google/callback`;

  if (errorParam || !code) {
    return NextResponse.redirect(
      new URL(`/login/${state}?error=${errorParam || "no_code"}`, req.url)
    );
  }

  try {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
      return NextResponse.redirect(
        new URL(`/login/${state}?error=google_not_configured`, req.url)
      );
    }

    // 1. Exchange code for access token with Google OAuth 2.0
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        grant_type: "authorization_code",
      }),
    });

    const tokenData = await tokenResponse.json();

    if (!tokenResponse.ok || !tokenData.access_token) {
      console.error("Google OAuth token exchange failed:", tokenData);
      return NextResponse.redirect(
        new URL(`/login/${state}?error=token_exchange_failed`, req.url)
      );
    }

    // 2. Fetch user profile from Google
    const profileResponse = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
      headers: {
        Authorization: `Bearer ${tokenData.access_token}`,
      },
    });

    const profileData = await profileResponse.json();

    if (!profileResponse.ok || !profileData.email) {
      console.error("Google user profile fetch failed:", profileData);
      return NextResponse.redirect(
        new URL(`/login/${state}?error=profile_fetch_failed`, req.url)
      );
    }

    // 3. Map state to UserRole entity
    let mappedRole: UserRole = "PATIENT";
    if (state === "dokter") {
      mappedRole = "OPHTHALMOLOGIST";
    } else if (state === "admin") {
      mappedRole = "ADMIN";
    }

    // 4. Authenticate or Provision user in RETIVA database
    const authResult = await authService.loginWithGoogleProfile({
      email: profileData.email,
      fullName: profileData.name || profileData.email.split("@")[0],
      role: mappedRole,
    });

    // 5. Transfer session to browser localStorage and redirect cleanly to dashboard
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>RETIVA - Mengalihkan Sesi...</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              display: flex;
              align-items: center;
              justify-content: center;
              height: 100vh;
              margin: 0;
              background-color: #0b1329;
              color: #ffffff;
            }
            .spinner {
              border: 3px solid rgba(255,255,255,0.1);
              border-top: 3px solid #38bdf8;
              border-radius: 50%;
              width: 36px;
              height: 36px;
              animation: spin 0.8s linear infinite;
              margin: 0 auto 1.5rem;
            }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
          </style>
        </head>
        <body>
          <div style="text-align: center;">
            <div class="spinner"></div>
            <h3>Otentikasi Google Berhasil</h3>
            <p style="color: #94a3b8; font-size: 0.9rem;">Menyiapkan dashboard ${state}...</p>
          </div>
          <script>
            try {
              localStorage.setItem('retiva_auth_token', ${JSON.stringify(authResult.token)});
              localStorage.setItem('retiva_current_user', ${JSON.stringify(JSON.stringify(authResult.user))});
              localStorage.setItem('retiva_last_role', ${JSON.stringify(state)});
            } catch (e) {
              console.error(e);
            }
            window.location.replace('/dashboard/${encodeURIComponent(state)}');
          </script>
        </body>
      </html>
    `;

    return new NextResponse(html, {
      status: 200,
      headers: { "Content-Type": "text/html; charset=utf-8" },
    });
  } catch (err: any) {
    console.error("Google OAuth error:", err);
    return NextResponse.redirect(
      new URL(`/login/${state}?error=unregistered_email`, req.url)
    );
  }
}
