from rest_framework import viewsets, permissions
from rest_framework.response import Response
from .models import NotificationPreference
from .serializers import NotificationPreferenceSerializer


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return NotificationPreference.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()
        if qs.exists():
            serializer = self.get_serializer(qs.first())
            return Response(serializer.data)
        return Response({})
