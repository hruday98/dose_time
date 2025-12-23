from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Prescription, MedicationLog
from .serializers import PrescriptionSerializer, MedicationLogSerializer


class PrescriptionViewSet(viewsets.ModelViewSet):
    queryset = Prescription.objects.all().order_by('-created_at')
    serializer_class = PrescriptionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Prescription.objects.filter(patient=user).order_by('-created_at')


class MedicationLogViewSet(viewsets.ModelViewSet):
    queryset = MedicationLog.objects.all().order_by('-taken_at')
    serializer_class = MedicationLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = MedicationLog.objects.filter(patient=user).order_by('-taken_at')
        prescription_id = self.request.query_params.get('prescription_id')
        if prescription_id:
            qs = qs.filter(prescription_id=prescription_id)
        return qs

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def mark_taken(self, request, pk=None):
        log = self.get_object()
        log.is_taken = True
        log.save(update_fields=['is_taken'])
        return Response(self.get_serializer(log).data)
