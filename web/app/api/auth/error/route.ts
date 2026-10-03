import { NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const error = searchParams.get("error") || "AccessDenied";

  let role = "pengguna";
  try {
    const cookieStore = cookies();
    const savedRole = cookieStore.get("retiva_login_role")?.value;
    if (savedRole && ["admin", "dokter", "pengguna"].includes(savedRole)) {
      role = savedRole;
    }
  } catch {}

  return NextResponse.redirect(new URL(`/login/${role}?error=${encodeURIComponent(error)}`, req.url));
}
