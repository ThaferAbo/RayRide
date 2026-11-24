import { ArrowRightIcon, FileTextIcon, PencilSimpleIcon, UploadSimpleIcon, WarningCircleIcon } from "@phosphor-icons/react";
import { useState } from "react";

export function TicketStep({ file, pending, error, onPick, onReject, onExtract, onManual }: {
  file: File | null;
  pending: boolean;
  error: string;
  onPick: (file: File) => void;
  onReject: (message: string) => void;
  onExtract: () => void;
  onManual: () => void;
}) {
  const [dragging, setDragging] = useState(false);
  return (
    <section className="panel" aria-labelledby="ticket-title">
      <h2 className="panel-title" id="ticket-title" tabIndex={-1}>Upload your flight ticket</h2>
      <p className="panel-intro">We’ll look for your flight number and arrival details.</p>
      <div className="dropzone" data-dragging={dragging}
        onDragOver={(event) => { event.preventDefault(); if (!pending) setDragging(true); }}
        onDragLeave={() => setDragging(false)}
        onDrop={(event) => {
          event.preventDefault();
          setDragging(false);
          if (pending) return;
          const files = event.dataTransfer.files;
          if (files.length > 1) onReject("Drop one ticket at a time.");
          else if (files[0]) onPick(files[0]);
        }}>
        <span className="upload-icon" aria-hidden="true">
          {file ? <FileTextIcon size={24} /> : <UploadSimpleIcon size={24} />}
        </span>
        <p className="drop-title">{file ? file.name : "Drag and drop a ticket here"}</p>
        <input id="ticket-file" className="sr-only file-control" type="file"
          accept=".pdf,.png,.jpg,.jpeg,application/pdf,image/png,image/jpeg"
          aria-describedby="ticket-file-help" disabled={pending}
          onChange={(event) => {
            const selected = event.currentTarget.files?.[0];
            if (selected) onPick(selected);
            event.currentTarget.value = "";
          }} />
        <label htmlFor="ticket-file" className={`button ${file ? "button-outline" : "button-primary"}`}>
          {file ? "Choose another file" : "Choose a file"}
        </label>
        <p className="fine-print" id="ticket-file-help">PDF, PNG or JPEG · 10 MiB max</p>
      </div>
      {error && <div className="notice notice-error" role="alert"><WarningCircleIcon size={18} aria-hidden="true" />{error}</div>}
      <div className="panel-actions">
        <button type="button" className="text-action" onClick={onManual}>
          <PencilSimpleIcon size={17} aria-hidden="true" /> Enter details manually
        </button>
        {file && <button type="button" className="button button-primary" disabled={pending} onClick={onExtract}>
          {pending ? "Reading ticket…" : error ? "Try extraction again" : "Extract flight details"}
          <ArrowRightIcon size={17} aria-hidden="true" />
        </button>}
      </div>
      {pending && <p role="status" className="fine-print mt-2">A scanned ticket can take a few seconds to read.</p>}
    </section>
  );
}
