from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL


class Prescription(models.Model):
    class MedicationType(models.TextChoices):
        TABLET = 'tablet', 'Tablet'
        CAPSULE = 'capsule', 'Capsule'
        LIQUID = 'liquid', 'Liquid'
        INJECTION = 'injection', 'Injection'
        CREAM = 'cream', 'Cream'
        DROPS = 'drops', 'Drops'
        PATCH = 'patch', 'Patch'
        INHALER = 'inhaler', 'Inhaler'

    class DosageFrequency(models.TextChoices):
        ONCE_DAILY = 'once_daily', 'Once daily'
        TWICE_DAILY = 'twice_daily', 'Twice daily'
        THREE_TIMES_DAILY = 'three_times_daily', 'Three times daily'
        FOUR_TIMES_DAILY = 'four_times_daily', 'Four times daily'
        EVERY_OTHER_DAY = 'every_other_day', 'Every other day'
        WEEKLY = 'weekly', 'Weekly'
        AS_NEEDED = 'as_needed', 'As needed'

    patient = models.ForeignKey(User, related_name='prescriptions', on_delete=models.CASCADE)
    doctor = models.ForeignKey(User, related_name='doctor_prescriptions', null=True, blank=True, on_delete=models.SET_NULL)
    medication_name = models.CharField(max_length=255)
    dosage = models.CharField(max_length=255)
    medication_type = models.CharField(max_length=32, choices=MedicationType.choices)
    frequency = models.CharField(max_length=32, choices=DosageFrequency.choices)
    reminder_times = models.JSONField(default=list, blank=True)  # list of HH:mm strings
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    instructions = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"{self.medication_name} ({self.patient})"


class MedicationLog(models.Model):
    prescription = models.ForeignKey(Prescription, related_name='logs', on_delete=models.CASCADE)
    patient = models.ForeignKey(User, related_name='medication_logs', on_delete=models.CASCADE)
    taken_at = models.DateTimeField()
    is_taken = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"Log for {self.prescription} at {self.taken_at}"
