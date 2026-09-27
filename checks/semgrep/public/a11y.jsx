// Fixtures for a11y.yaml.
export function Card({ src, onOpen, props }) {
  // ruleid: va-img-missing-alt
  const a = <img src={src} />;
  // ok: va-img-missing-alt
  const b = <img src={src} alt="" />;
  // ok: va-img-missing-alt
  const c = <img {...props} />;
  // ruleid: va-click-handler-on-non-interactive
  const d = <div onClick={onOpen}>Open</div>;
  // ok: va-click-handler-on-non-interactive
  const e = <div role="button" tabIndex={0} onClick={onOpen} onKeyDown={onOpen}>Open</div>;
  // ok: va-click-handler-on-non-interactive
  const f = <button onClick={onOpen}>Open</button>;
  return <section>{a}{b}{c}{d}{e}{f}</section>;
}
