<!doctype html>
<html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Accedi a Nutrition</title>
<body><main><h1>Accedi a Nutrition</h1><p>Usa il tuo account amministrativo.</p>
@if ($errors->any())<p role="alert">Credenziali non valide.</p>@endif
<form method="post" action="{{ route('login') }}">@csrf
<p><label>Email <input type="email" name="email" autocomplete="username" required></label></p>
<p><label>Password <input type="password" name="password" autocomplete="current-password" required></label></p>
<button type="submit">Accedi</button></form></main></body></html>
