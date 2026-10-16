import { NextAuthOptions } from "next-auth";
import GoogleProvider from "next-auth/providers/google";
import { cookies } from "next/headers";
import { authService } from "@/lib/container";
import { UserRole } from "@/domain/auth/user.entity";

export const authOptions: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID || "",
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || "",
    }),
  ],
  callbacks: {
    async signIn({ user, account }) {
      // Determine originating role from cookie
      let role = "pengguna";
      try {
        const cookieStore = cookies();
        const savedRole = cookieStore.get("retiva_login_role")?.value;
        if (savedRole && ["admin", "dokter", "pengguna"].includes(savedRole)) {
          role = savedRole;
        }
      } catch {}

      if (account?.provider === "google" && user.email) {
        try {
          let mappedRole: UserRole | undefined;
          if (role === "admin") mappedRole = "ADMIN";
          else if (role === "dokter") mappedRole = "DOKTER";
          else if (role === "pengguna") mappedRole = "PENGGUNA";

          // Strictly verify that the user exists in RETIVA PostgreSQL database with correct role
          const authResult = await authService.loginWithGoogleProfile({
            email: user.email,
            fullName: user.name || user.email.split("@")[0],
            role: mappedRole,
          });

          // Attach database user id and role to user object
          (user as any).dbId = authResult.user.id;
          (user as any).role = authResult.user.role;
          (user as any).token = authResult.token;
          if (authResult.user.fullName) {
            user.name = authResult.user.fullName;
          }

          return true;
        } catch (error: any) {
          console.warn("Google login rejected for role:", role, user.email, error?.message);
          const errorMsg = error?.message || "Akses Ditolak";
          return `/login/${role}?error=AccessDenied&msg=${encodeURIComponent(errorMsg)}`;
        }
      }
      return true;
    },
    async redirect({ url, baseUrl }) {
      const liveHost = "hackathon.mataceria.my.id";
      const liveOrigin = "https://hackathon.mataceria.my.id";

      // If in production or live domain, ensure redirection stays on the public domain
      const isLive =
        (typeof process !== "undefined" && process.env.NODE_ENV === "production") ||
        (process.env.NEXTAUTH_URL && process.env.NEXTAUTH_URL.includes(liveHost));

      const fallbackBase = isLive ? liveOrigin : baseUrl;

      // Allows relative callback URLs (e.g. "/dashboard/dokter")
      if (url.startsWith("/")) {
        return `${fallbackBase}${url}`;
      }

      // Allows callback URLs on the same origin or official live domain
      try {
        const parsedUrl = new URL(url);
        if (
          parsedUrl.origin === baseUrl ||
          parsedUrl.origin === liveOrigin ||
          parsedUrl.hostname === liveHost ||
          parsedUrl.hostname.includes("mataceria.my.id")
        ) {
          return url;
        }
      } catch {}

      return fallbackBase;
    },
    async jwt({ token, user }) {
      if (user) {
        token.id = (user as any).dbId || user.id;
        token.role = (user as any).role || "PATIENT";
        token.accessToken = (user as any).token;
        if (user.name) {
          token.name = user.name;
        }
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        (session.user as any).id = token.id;
        (session.user as any).role = token.role;
        (session.user as any).accessToken = token.accessToken;
        if (token.name) {
          session.user.name = token.name as string;
        }
      }
      return session;
    },
  },
  pages: {
    signIn: "/login/pengguna",
    error: "/api/auth/error",
  },
  secret: process.env.NEXTAUTH_SECRET || process.env.JWT_SECRET || "retiva-nextauth-secret-key",
};
