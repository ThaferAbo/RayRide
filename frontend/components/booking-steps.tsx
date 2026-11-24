import { CheckIcon } from "@phosphor-icons/react/ssr";

const labels = ["Ticket", "Review", "Confirmation"];

export function BookingSteps({ current }: { current: 1 | 2 | 3 }) {
  return (
    <ol aria-label="Reservation progress" className="steps">
      {labels.map((label, index) => (
        <li key={label} aria-current={index + 1 === current ? "step" : undefined}
          className={`step${index + 1 < current ? " step-complete" : ""}`}>
          <span className="step-marker" aria-hidden="true">
            {index + 1 < current ? <CheckIcon size={15} weight="bold" /> : index + 1}
          </span>
          {label}
        </li>
      ))}
    </ol>
  );
}
