from django.db import connections
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthCheckView(APIView):
    authentication_classes = []
    permission_classes = []

    def get(self, request):
        try:
            connections["default"].cursor()
            db_status = "up"
        except Exception:
            db_status = "down"

        return Response(
            {
                "status": "ok",
                "database": db_status,
            }
        )
