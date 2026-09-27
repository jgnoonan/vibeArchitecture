// Fixtures for llm.yaml.
async function calls(openai, anthropic, model, db, userName) {
  // ruleid: va-llm-call-without-max-tokens-js
  await openai.chat.completions.create({ model: "gpt-x", messages: [] });
  // ok: va-llm-call-without-max-tokens-js
  await openai.chat.completions.create({ model: "gpt-x", messages: [], max_completion_tokens: 500 });
  // ruleid: va-llm-call-without-max-tokens-js
  await generateText({ model, prompt: "hi" });
  // ok: va-llm-call-without-max-tokens-js
  await generateText({ model, prompt: "hi", maxOutputTokens: 300 });

  const messages = [
    // ruleid: va-llm-system-prompt-interpolation-js
    { role: "system", content: `You are helping ${userName}.` },
    // ok: va-llm-system-prompt-interpolation-js
    { role: "system", content: "You are a support assistant." },
    { role: "user", content: userName },
  ];

  const completion = await openai.chat.completions.create({ model: "x", messages, max_tokens: 200 });
  const code = completion.choices[0].message.content;
  // ruleid: va-llm-output-to-dangerous-sink-js
  eval(code);
  // ok: va-llm-output-to-dangerous-sink-js
  eval("1+1");
}
