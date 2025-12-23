from rest_framework import serializers
from .models import Prescription, MedicationLog


class PrescriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Prescription
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class MedicationLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicationLog
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']
