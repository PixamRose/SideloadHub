# SideloadHub — Guide sideload LAN

## Workflow complet

### 1. PC — lancer le hub

```powershell
$env:GITHUB_TOKEN = "ton_token"   # optionnel
.\LAN-HUB.bat
```

### 2. iPhone — connecter l'app

- IP affichée par le serveur (ex: `192.168.1.42`)
- Port: `8765`

### 3. Mettre à jour une app

1. Onglet **Apps** → choisis l'app
2. **Télécharger l'IPA**
3. **Partager → AltStore** (AltServer doit tourner sur le PC)

### 4. Première install de SideloadHub

Comme les autres apps : GitHub Actions → artifact `SideloadHub-ipa` → Sideloadly USB.

Ensuite, les mises à jour se font via le hub LAN.

## AltStore + WiFi (recommandé)

1. Installe [AltServer](https://altstore.io) sur Windows
2. Installe AltStore sur iPhone
3. SideloadHub télécharge l'IPA → Partager → AltStore
4. AltServer signe et installe **sans câble USB** (même WiFi)

## Dépannage

| Problème | Solution |
|----------|----------|
| Connexion refusée | Même WiFi PC/iPhone, pare-feu port 8765 |
| 0 app disponible | Lance SYNC-HUB.bat avec GITHUB_TOKEN |
| AltStore n'apparaît pas | Partage → Enregistrer dans Fichiers puis AltStore |
