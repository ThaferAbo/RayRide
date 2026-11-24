"use client";

import { CopyIcon } from "@phosphor-icons/react";
import { useState } from "react";

export function CopyReference({ reference }: { reference: string }) {
  const [message, setMessage] = useState("");
  async function copy() {
    try {
      await navigator.clipboard.writeText(reference);
      setMessage("Reference copied");
    } catch {
      setMessage("Select the reference to copy it.");
    }
  }
  return (
    <div>
      <button type="button" className="button button-outline" onClick={copy}>
        <CopyIcon size={17} aria-hidden="true" /> Copy reference
      </button>
      {message && <p className="fine-print mt-1" role="status">{message}</p>}
    </div>
  );
}
