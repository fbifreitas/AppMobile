import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  List<String> fotos = [];

  void tirarFoto() {
    setState(() {
      fotos.add('foto_${fotos.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [

          /// 🔥 FUNDO (simulando câmera)
          Container(
            color: Colors.black,
          ),

          /// 🔝 TOPO
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sala',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  '${fotos.length}/10',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          /// 📸 LISTA DE FOTOS (preview)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                itemBuilder: (_, index) {
                  return Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    color: Colors.white24,
                    child: Center(
                      child: Text(
                        fotos[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// 🔘 BOTÃO DE FOTO
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: tirarFoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          /// ❌ VOLTAR
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}