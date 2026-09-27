# Fixtures for exposure.yaml.
import logging

logger = logging.getLogger(__name__)


def log(user, password, token, request):
    # ruleid: va-sensitive-value-logged-py
    logger.info("login %s %s", user.email, password)
    # ruleid: va-sensitive-value-logged-py
    logger.debug(f"issued {token}")
    # ruleid: va-sensitive-value-logged-py
    print("card", request.json["x"], user.card_number)
    # ok: va-sensitive-value-logged-py
    logger.info("password changed for user %s", user.id)
    # ok: va-sensitive-value-logged-py
    logger.info("token refreshed", extra={"user_id": user.id})
