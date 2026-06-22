# Lumma Agendamentos: app mobile (Flutter)

App Flutter de agendamentos do Espaço Lumma. Consome a API de booking do backend
(`../backend`).

## Pré-requisitos
- **Flutter SDK 3.44+** (Dart 3.12+), com `flutter doctor` sem erros bloqueantes.
- **Android SDK** + um **emulador (AVD)** configurado (ou um dispositivo Android).
- **Backend rodando** localmente em `http://localhost:3000` (ver `../backend`).

## Como rodar (passo a passo, com emulador)

### 1. Suba o backend
O app fala com a API em `http://10.0.2.2:3000`, porque `10.0.2.2` é como o **emulador Android**
enxerga o `localhost` da máquina host. No diretório `../backend`:
```bash
npm install
npm run dev        # Next.js em http://localhost:3000
```

### 2. Suba o emulador Android (cold boot)
```bash
# Windows: o emulador fica em %LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe
emulator -list-avds
emulator -avd <NOME_DO_AVD> -no-snapshot
```
Use `-no-snapshot` (cold boot): um snapshot corrompido pode deixar o device "offline".
Aguarde o boot terminar:
```bash
adb wait-for-device
adb shell getprop sys.boot_completed   # deve retornar 1
```

### 3. Instale as dependências
```bash
flutter pub get
```

### 4. Rode o app
```bash
flutter devices    # descubra o id do device (ex.: emulator-5554)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```
A base URL é injetada em build time via `--dart-define=API_BASE_URL` (default
`http://10.0.2.2:3000`). Para outros alvos:
- **Dispositivo físico:** use o IP da máquina na LAN (ex.: `http://192.168.0.10:3000`).
- **Simulador iOS:** `http://localhost:3000`.

## Ícone do app (launcher)
Gerado por `flutter_launcher_icons` a partir de `assets/icon/icon.png`:
```bash
dart run flutter_launcher_icons
```

## Notas operacionais
- **Cleartext HTTP:** habilitado no `AndroidManifest.xml` (`android:usesCleartextTraffic="true"`)
  para o app alcançar o backend local via `http://10.0.2.2`.
- **Lock de AVD:** um AVD roda em **um processo só**, então não abra o mesmo AVD no Android
  Studio enquanto ele roda pela CLI (e vice-versa), senão a conexão com o device cai.
- **Primeiro build:** o primeiro `flutter run` baixa/compila o Gradle (alguns minutos);
  os seguintes são bem mais rápidos.

## Estrutura
```
lib/
  main.dart · app.dart
  core/      theme/ (cores, tipografia, tema) · network/ (dio + interceptors) · config/ · auth/
  routing/   app_router.dart (go_router + redirect por auth + bottom nav)
  features/  auth · services (catálogo + agendamento) · appointments · profile
  shared/    widgets/ (cards, estados de loading/erro/vazio, marca)
assets/      images/ (logos) · fonts/ (Geist, Cormorant Garamond) · icon/
```
