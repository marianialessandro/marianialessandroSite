<!doctype html>
<html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Autorizza Nutrition</title>
<body><main><h1>Autorizza {{ $client->name }}</h1><p>Questa connessione richiede:</p><ul>
@foreach ($scopes as $scope)<li>{{ $scope->description }}</li>@endforeach
</ul><form method="post" action="{{ route('passport.authorizations.approve') }}">@csrf<input type="hidden" name="auth_token" value="{{ $authToken }}"><button type="submit">Autorizza</button></form>
<form method="post" action="{{ route('passport.authorizations.deny') }}">@csrf @method('DELETE')<input type="hidden" name="auth_token" value="{{ $authToken }}"><button type="submit">Rifiuta</button></form></main></body></html>
