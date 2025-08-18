from rest_framework import serializers
from .models import NationalIDUser

class NationalIDUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = NationalIDUser
        fields = '__all__'

