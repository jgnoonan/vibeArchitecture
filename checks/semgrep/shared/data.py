# Fixtures for data.yaml (Python ORMs).
from django.db import models
from sqlalchemy import Column, Float, Numeric


class Order(models.Model):
    # ruleid: va-money-as-float-py
    total_price = models.FloatField()
    # ok: va-money-as-float-py
    subtotal = models.DecimalField(max_digits=12, decimal_places=2)
    # ok: va-money-as-float-py
    rating = models.FloatField()


class Invoice:
    # ruleid: va-money-as-float-py
    amount = Column(Float, nullable=False)
    # ok: va-money-as-float-py
    fee = Column(Numeric(12, 2))
