from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL


class NotificationPreference(models.Model):
    user = models.OneToOneField(User, related_name='notification_pref', on_delete=models.CASCADE)
    quiet_hours_start = models.CharField(max_length=5, blank=True)  # HH:mm
    quiet_hours_end = models.CharField(max_length=5, blank=True)    # HH:mm
    enable_daily_summary = models.BooleanField(default=True)
    enable_medication_reminders = models.BooleanField(default=True)
    channels = models.JSONField(default=list, blank=True)  # e.g. ["push", "email"]
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"NotificationPrefs({self.user})"
