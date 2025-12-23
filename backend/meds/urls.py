from rest_framework.routers import DefaultRouter
from .views import PrescriptionViewSet, MedicationLogViewSet

router = DefaultRouter()
router.register(r'prescriptions', PrescriptionViewSet, basename='prescription')
router.register(r'logs', MedicationLogViewSet, basename='medicationlog')

urlpatterns = router.urls
