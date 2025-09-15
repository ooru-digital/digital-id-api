from rest_framework import serializers
from .models import NationalIDUser

class NationalIDUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = NationalIDUser
        fields = '__all__'

class NationalIDUserResponseSerializer(serializers.ModelSerializer):
    face = serializers.SerializerMethodField()

    class Meta:
        model = NationalIDUser
        # exclude `photo` and include `face`
        fields = [
            "id",
            "first_name",
            "last_name",
            "email",
            "phone_number",
            "gender",
            "date_of_birth",
            "national_id_number",
            "created_at",
            "face",
        ]

    def get_face(self, obj):
        return obj.photo
