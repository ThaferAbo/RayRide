import Image from "next/image";
import { BookingFlow } from "@/components/booking-flow";

export default function Home() {
  return (
    <div className="shell home-content">
      <section className="hero" aria-labelledby="hero-title">
        <Image src="/rayride-coast.webp" alt="" fill preload unoptimized className="hero-photo" />
        <div className="hero-content">
          <p className="hero-kicker"><span /> Simulation only</p>
          <h1 id="hero-title">Book your airport<br className="hero-break" /> transfer</h1>
          <p>Upload a flight ticket or enter your details to create a simulated reservation.</p>
        </div>
      </section>
      <BookingFlow />
    </div>
  );
}
