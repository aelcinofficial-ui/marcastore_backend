import json
import urllib.error
import urllib.parse
import urllib.request

import jwt
from google.auth.exceptions import TransportError
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2 import id_token as google_id_token
from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.http import HttpResponseBadRequest, HttpResponseRedirect
from django.utils.decorators import method_decorator
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from rest_framework import serializers, status
from rest_framework.exceptions import APIException, AuthenticationFailed
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import SocialIdentity, User as Profile


AuthUser = get_user_model()


class AppleAndroidRedirect(HttpResponseRedirect):
  allowed_schemes = ['intent']


def _tokens_for(auth_user):
  refresh = RefreshToken.for_user(auth_user)
  return {
      'access': str(refresh.access_token),
      'refresh': str(refresh),
  }


def _auth_response(auth_user, profile, http_status=status.HTTP_200_OK):
  return Response(
      {
          **_tokens_for(auth_user),
          'user': {
              'id': profile.pk,
              'first_name': profile.name.split(' ', 1)[0],
              'last_name': (
                  profile.name.split(' ', 1)[1]
                  if ' ' in profile.name
                  else ''
              ),
              'name': profile.name,
              'email': profile.email,
              'phone': profile.phone or '',
          },
      },
      status=http_status,
  )


class RegisterSerializer(serializers.Serializer):
  first_name = serializers.CharField(max_length=150, trim_whitespace=True)
  last_name = serializers.CharField(
      max_length=150, allow_blank=True, required=False, default=''
  )
  email = serializers.EmailField()
  password = serializers.CharField(
      min_length=8, write_only=True, trim_whitespace=False
  )

  def validate_email(self, value):
    email = value.strip().lower()
    if AuthUser.objects.filter(email__iexact=email).exists():
      raise serializers.ValidationError(
          'Bu e-poçt ünvanı artıq qeydiyyatdan keçib.'
      )
    return email

  def validate(self, attrs):
    auth_user = AuthUser(
        username=attrs['email'],
        email=attrs['email'],
        first_name=attrs['first_name'],
        last_name=attrs['last_name'],
    )
    try:
      validate_password(attrs['password'], user=auth_user)
    except DjangoValidationError as error:
      raise serializers.ValidationError({'password': error.messages})
    return attrs

  @transaction.atomic
  def create(self, validated_data):
    email = validated_data['email']
    first_name = validated_data['first_name'].strip()
    last_name = validated_data['last_name'].strip()
    auth_user = AuthUser.objects.create_user(
        username=email,
        email=email,
        first_name=first_name,
        last_name=last_name,
        password=validated_data['password'],
    )
    name = ' '.join(part for part in (first_name, last_name) if part)
    profile, _ = Profile.objects.update_or_create(
        email=email,
        defaults={'name': name},
    )
    return auth_user, profile


class EmailRegisterView(APIView):
  permission_classes = [AllowAny]

  def post(self, request):
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    auth_user, profile = serializer.save()
    return _auth_response(auth_user, profile, status.HTTP_201_CREATED)


class EmailLoginView(APIView):
  permission_classes = [AllowAny]

  def post(self, request):
    email = str(request.data.get('email', '')).strip().lower()
    password = request.data.get('password', '')
    if not email or not isinstance(password, str) or not password:
      raise serializers.ValidationError(
          {'detail': 'E-poçt və şifrə tələb olunur.'}
      )

    auth_user = AuthUser.objects.filter(email__iexact=email).first()
    if auth_user is None or not auth_user.check_password(password):
      raise AuthenticationFailed('E-poçt və ya şifrə yanlışdır.')
    if not auth_user.is_active:
      raise AuthenticationFailed('Bu hesab deaktiv edilib.')

    profile = Profile.objects.filter(email__iexact=auth_user.email).first()
    if profile is None:
      profile = Profile.objects.create(
          name=' '.join(
              part for part in (auth_user.first_name, auth_user.last_name)
              if part
          ) or auth_user.email,
          email=auth_user.email,
      )
    return _auth_response(auth_user, profile)


def _apple_identity(identity_token):
  client_ids = settings.APPLE_CLIENT_IDS
  if not client_ids:
    raise APIException(
        'APPLE_CLIENT_IDS Django mühit dəyişəni konfiqurasiya edilməyib.'
    )
  try:
    jwks = jwt.PyJWKClient('https://appleid.apple.com/auth/keys')
    signing_key = jwks.get_signing_key_from_jwt(identity_token)
    claims = jwt.decode(
        identity_token,
        signing_key.key,
        algorithms=['RS256'],
        audience=client_ids,
        issuer='https://appleid.apple.com',
        options={'require': ['exp', 'iat', 'sub', 'iss', 'aud']},
    )
  except jwt.PyJWKClientConnectionError as error:
    raise APIException(
        'Apple imza açarlarını yoxlamaq mümkün olmadı.'
    ) from error
  except (jwt.PyJWTError, ValueError) as error:
    raise AuthenticationFailed('Apple identity token etibarsızdır.') from error

  return {
      'provider_user_id': claims['sub'],
      'email': claims.get('email', ''),
      'email_verified': claims.get('email_verified') in (True, 'true', 'True'),
  }


def _facebook_identity(access_token):
  app_id = settings.FACEBOOK_APP_ID
  app_secret = settings.FACEBOOK_APP_SECRET
  if not app_id or not app_secret:
    raise APIException(
        'FACEBOOK_APP_ID və FACEBOOK_APP_SECRET Django mühit dəyişənləri '
        'konfiqurasiya edilməyib.'
    )

  graph_base = (
      f'https://graph.facebook.com/{settings.FACEBOOK_GRAPH_API_VERSION}'
  )
  debug_query = urllib.parse.urlencode({
      'input_token': access_token,
      'access_token': f'{app_id}|{app_secret}',
  })
  try:
    with urllib.request.urlopen(
        f'{graph_base}/debug_token?{debug_query}', timeout=10
    ) as response:
      token_info = json.load(response)['data']
    if (
        not token_info.get('is_valid')
        or str(token_info.get('app_id')) != str(app_id)
    ):
      raise AuthenticationFailed('Facebook access token etibarsızdır.')

    profile_query = urllib.parse.urlencode({
        'fields': 'id,name,email',
        'access_token': access_token,
    })
    with urllib.request.urlopen(
        f'{graph_base}/me?{profile_query}', timeout=10
    ) as response:
      profile_data = json.load(response)
  except AuthenticationFailed:
    raise
  except (urllib.error.URLError, TimeoutError, KeyError, ValueError) as error:
    raise APIException('Facebook hesabını yoxlamaq mümkün olmadı.') from error

  return {
      'provider_user_id': str(profile_data.get('id', '')),
      'email': profile_data.get('email', ''),
      'email_verified': bool(profile_data.get('email')),
      'name': profile_data.get('name', ''),
  }


def _google_identity(identity_token):
  audience = settings.GOOGLE_CLIENT_ID or settings.GOOGLE_CLIENT_IDS
  if not audience:
    raise APIException(
        'GOOGLE_CLIENT_ID Django mühit dəyişəni konfiqurasiya edilməyib.'
    )
  try:
    claims = google_id_token.verify_oauth2_token(
        identity_token,
        GoogleAuthRequest(),
        audience=audience,
    )
  except TransportError as error:
    raise APIException(
        'Google imza açarlarını yoxlamaq mümkün olmadı.'
    ) from error
  except ValueError as error:
    raise AuthenticationFailed('Google identity token etibarsızdır.') from error

  return {
      'provider_user_id': claims.get('sub', ''),
      'email': claims.get('email', ''),
      'email_verified': claims.get('email_verified') in (True, 'true', 'True'),
      'name': claims.get('name', ''),
  }


class SocialLoginView(APIView):
  permission_classes = [AllowAny]

  @transaction.atomic
  def post(self, request, provider):
    if provider == SocialIdentity.Provider.APPLE:
      identity_token = request.data.get('identity_token')
      if not isinstance(identity_token, str) or not identity_token:
        raise serializers.ValidationError(
            {'identity_token': 'Apple identity token tələb olunur.'}
        )
      identity_data = _apple_identity(identity_token)
      provided_name = str(request.data.get('name', '')).strip()
    elif provider == SocialIdentity.Provider.FACEBOOK:
      access_token = request.data.get('access_token')
      if not isinstance(access_token, str) or not access_token:
        raise serializers.ValidationError(
            {'access_token': 'Facebook access token tələb olunur.'}
        )
      identity_data = _facebook_identity(access_token)
      provided_name = str(identity_data.get('name', '')).strip()
    elif provider == SocialIdentity.Provider.GOOGLE:
      identity_token = request.data.get('id_token')
      if not isinstance(identity_token, str) or not identity_token:
        raise serializers.ValidationError(
            {'id_token': 'Google identity token tələb olunur.'}
        )
      identity_data = _google_identity(identity_token)
      provided_name = str(identity_data.get('name', '')).strip()
    else:
      raise serializers.ValidationError(
          {'provider': 'Google, Apple və Facebook girişləri dəstəklənir.'}
      )

    provider_user_id = identity_data.get('provider_user_id', '')
    if not provider_user_id:
      raise AuthenticationFailed('Provider istifadəçi ID-si qaytarmadı.')

    identity = SocialIdentity.objects.select_related('user').filter(
        provider=provider,
        provider_user_id=provider_user_id,
    ).first()
    email = str(identity_data.get('email', '')).strip().lower()
    if identity is None and (
        not email or not identity_data.get('email_verified')
    ):
      raise AuthenticationFailed(
          'Təsdiqlənmiş e-poçt verən Google/Apple/Facebook hesabı tələb olunur.'
      )

    if identity is not None:
      profile = identity.user
    else:
      profile = Profile.objects.filter(email__iexact=email).first()
      if profile is None:
        profile = Profile.objects.create(
            email=email,
            name=provided_name or email.split('@', 1)[0],
        )
      SocialIdentity.objects.create(
          user=profile,
          provider=provider,
          provider_user_id=provider_user_id,
      )

    auth_user = AuthUser.objects.filter(email__iexact=profile.email).first()
    if auth_user is None:
      username = profile.email.lower()
      auth_user = AuthUser.objects.create_user(
          username=username,
          email=profile.email,
          password=None,
      )
    if not auth_user.is_active:
      raise AuthenticationFailed('Bu hesab deaktiv edilib.')

    return _auth_response(auth_user, profile)


class GoogleLoginView(SocialLoginView):
  def post(self, request):
    return super().post(request, SocialIdentity.Provider.GOOGLE)


class CurrentUserView(APIView):
  permission_classes = [IsAuthenticated]

  def get(self, request):
    profile = Profile.objects.filter(
        email__iexact=request.user.email
    ).first()
    if profile is None:
      raise AuthenticationFailed('İstifadəçi profilini tapmaq mümkün olmadı.')
    return Response({
        'id': profile.pk,
        'first_name': profile.name.split(' ', 1)[0],
        'last_name': (
            profile.name.split(' ', 1)[1] if ' ' in profile.name else ''
        ),
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone or '',
    })


@method_decorator(csrf_exempt, name='dispatch')
class AppleAndroidCallbackView(View):
  def post(self, request):
    callback_data = request.POST.urlencode()
    if not callback_data:
      return HttpResponseBadRequest('Apple callback məlumatı boşdur.')
    redirect_uri = (
        'intent://callback?'
        f'{callback_data}'
        '#Intent;package=com.example.marcastore_app;'
        'scheme=signinwithapple;end'
    )
    response = AppleAndroidRedirect(redirect_uri)
    response['Cache-Control'] = 'no-store'
    return response
