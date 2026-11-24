import type { NextConfig } from "next";

const config: NextConfig = {
  agentRules: false,
  async headers() {
    return [{ source: "/reservations/:path*", headers: [{ key: "Referrer-Policy", value: "no-referrer" }] }];
  },
};

export default config;
