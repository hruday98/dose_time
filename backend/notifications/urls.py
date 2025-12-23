from rest_framework.routers import DefaultRouter
from .views import NotificationPreferenceViewSet

router = DefaultRouter()
router.register(r'prefs', NotificationPreferenceViewSet, basename='notificationpref')

urlpatterns = router.urls
