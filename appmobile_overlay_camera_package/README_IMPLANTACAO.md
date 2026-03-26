Pacote para câmera embarcada com overlay "Onde estou?".

Usei a estratégia de câmera embarcada porque o pacote `camera` permite preview e captura dentro da interface Flutter, o que viabiliza overlay customizado por cima da câmera. citeturn900866search1

Arquivos no pacote:
- lib/screens/overlay_camera_screen.dart
- lib/screens/checkin_screen.dart
- lib/screens/checkin_step2_screen.dart
- install_overlay_camera_package.bat

O `.bat` copia os arquivos automaticamente para o projeto atual e cria backup dos arquivos antigos.

Passos:
1. Extraia o zip.
2. Entre na raiz do projeto Flutter.
3. Execute `install_overlay_camera_package.bat`.
4. Adicione no `pubspec.yaml`:
   - camera: ^0.11.3+1
5. Rode:
   - flutter pub get
   - flutter analyze
   - flutter run

Git:
git status
git add .
git commit -m "feat: adiciona camera embarcada com overlay no check-in"
git push origin main