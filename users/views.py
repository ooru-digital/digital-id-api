from django.shortcuts import render

# Create your views here.
from rest_framework import generics
from .models import NationalIDUser
from .serializers import NationalIDUserResponseSerializer, NationalIDUserSerializer

from rest_framework import status
from rest_framework.response import Response

from rest_framework.views import APIView

# API to create a new record in the database
class NationalIDUserCreateView(generics.CreateAPIView):
    queryset = NationalIDUser.objects.all()
    serializer_class = NationalIDUserSerializer

    def create(self, request, *args, **kwargs):
        super().create(request, *args, **kwargs)
        return Response(
            {"message": "Successfully stored the information."},
            status=status.HTTP_201_CREATED
        )



class NationalIDUserRetrieveView(APIView):
    def get(self, request, national_id):
        try:
            # Query the database based on national_id_number
            user = NationalIDUser.objects.get(national_id_number=national_id)
            serializer = NationalIDUserResponseSerializer(user)
            
            return Response(
                {
                    "data": serializer.data
                },
                status=status.HTTP_200_OK
            )

        except NationalIDUser.DoesNotExist:
            return Response(
                {"message": "User with the given National ID does not exist."},
                status=status.HTTP_404_NOT_FOUND
            )

