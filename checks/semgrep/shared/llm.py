# Fixtures for llm.yaml.
import subprocess


def calls(client, anthropic, cursor, user_name):
    # ruleid: va-llm-call-without-max-tokens-py
    client.chat.completions.create(model="x", messages=[])
    # ok: va-llm-call-without-max-tokens-py
    client.chat.completions.create(model="x", messages=[], max_completion_tokens=400)
    # ruleid: va-llm-call-without-max-tokens-py
    client.responses.create(model="x", input="hi")
    # ok: va-llm-call-without-max-tokens-py
    client.responses.create(model="x", input="hi", max_output_tokens=300)

    messages = [
        # ruleid: va-llm-system-prompt-interpolation-py
        {"role": "system", "content": f"You are helping {user_name}."},
        # ok: va-llm-system-prompt-interpolation-py
        {"role": "system", "content": "You are a support assistant."},
    ]

    resp = client.chat.completions.create(model="x", messages=messages, max_tokens=200)
    sql = resp.choices[0].message.content
    # ruleid: va-llm-output-to-dangerous-sink-py
    cursor.execute(sql)
    # ok: va-llm-output-to-dangerous-sink-py
    cursor.execute("SELECT 1")
