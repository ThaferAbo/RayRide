import { AirplaneTiltIcon, TicketIcon } from "@phosphor-icons/react/ssr";
import "@fontsource-variable/manrope";
import type { Metadata } from "next";
import Link from "next/link";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "RayRide | Airport transfer reservations",
  description: "Review your flight details and create a local, simulated airport transfer reservation.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header className="site-header">
          <div className="shell topbar">
            <Link href="/" className="wordmark">
              <span className="brand-mark"><AirplaneTiltIcon size={21} weight="fill" aria-hidden="true" /></span>
              RayRide<span>.</span>
            </Link>
            <nav aria-label="Main navigation">
              <Link href="/reservations" className="button button-outline nav-button">
                <TicketIcon size={19} aria-hidden="true" /> Find a reservation
              </Link>
            </nav>
          </div>
        </header>
        <main>{children}</main>
        <footer className="shell site-footer">
          <span>CSE491 · Group 4</span>
          <Link href="/status">System status</Link>
        </footer>
      </body>
    </html>
  );
}
