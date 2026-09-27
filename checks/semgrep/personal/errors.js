// Fixtures for errors.yaml.
app.get("/x", async (req, res) => {
  try {
    await work();
  } catch (err) {
    // ruleid: va-error-details-in-response-js
    res.status(500).json({ error: err });
  }
  try {
    await work();
  } catch (err) {
    // ruleid: va-error-details-in-response-js
    res.status(500).send(err.stack);
  }
  try {
    await work();
  } catch (err) {
    req.log.error({ err }, "work failed");
    // ok: va-error-details-in-response-js
    res.status(500).json({ error: "Something went wrong", requestId: req.id });
  }
});

app.use((err, req, res, next) => {
  // ruleid: va-error-details-in-response-js
  res.status(500).send(err);
});

function logOnly(err) {
  // ok: va-error-details-in-response-js
  console.error(err.stack);
}
