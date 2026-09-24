process.env.JWT_SECRET = "retiva-healthcare-jwt-secret-replace-in-production-min-32-chars";

import { JwtTokenService } from "../infrastructure/security/jwt-token.service";

async function testLiveServer() {
  console.log("=== TESTING LIVE DEV SERVER (PORT 3000) ===");

  const token = new JwtTokenService().generateToken({
    userId: "usr-001",
    email: "dr.hendra@retina.id",
    role: "OPHTHALMOLOGIST",
  });

  const endpoints = [
    { url: "http://localhost:3000/", name: "Web UI Homepage", auth: false },
    { url: "http://localhost:3000/api/v1/patients", name: "Patients API", auth: true },
    { url: "http://localhost:3000/api/v1/models/active", name: "Active Model API", auth: true },
    { url: "http://localhost:3000/api/v1/facilities", name: "Facilities API", auth: true },
  ];

  for (const ep of endpoints) {
    try {
      const headers: Record<string, string> = {};
      if (ep.auth) {
        headers["Authorization"] = `Bearer ${token}`;
        headers["x-retiva-clinical"] = "true";
      }

      const res = await fetch(ep.url, { headers });
      console.log(`[${res.status}] ${ep.name} (${ep.url})`);
      if (res.status !== 200) {
        const text = await res.text();
        console.error(`   Error details:`, text.slice(0, 300));
      } else {
        const contentType = res.headers.get("content-type");
        if (contentType?.includes("application/json")) {
          const data = await res.json();
          console.log(`   JSON Response:`, Object.keys(data));
        } else {
          console.log(`   HTML Response OK (Length: ${(await res.text()).length} bytes)`);
        }
      }
    } catch (err: any) {
      console.error(`[FAIL] ${ep.name}:`, err.message);
    }
  }
}

testLiveServer();
