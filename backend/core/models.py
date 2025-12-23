from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Role(models.TextChoices):
        PATIENT = 'patient', 'Patient'
        DOCTOR = 'doctor', 'Doctor'
        CARETAKER = 'caretaker', 'Caretaker'

    role = models.CharField(max_length=20, choices=Role.choices, default=Role.PATIENT)
    phone_number = models.CharField(max_length=32, blank=True)
    profile_image = models.URLField(blank=True)

    def __str__(self) -> str:
        return f"{self.username} ({self.role})"
