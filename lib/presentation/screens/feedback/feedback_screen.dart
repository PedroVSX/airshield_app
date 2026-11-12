
import 'package:flutter/material.dart';
import 'package:airshield_app/data/services/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  String _category = 'Sugestão';

  final TextEditingController _controller =
      TextEditingController();

  static const Color primaryColor = Color(0xFF55D6BE);
  static const Color backgroundColor = Color(0xFF101418);
  static const Color surfaceColor = Color(0xFF1B2228);
  static const Color textColor = Color(0xFFF1F5F4);
  static const Color secondaryColor = Color(0xFF9AA6AC);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_rating == 0 || _controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe uma avaliação e escreva seu feedback.',
          ),
        ),
      );
      return;
    }

    try {
      await FeedbackService.sendFeedback(
        rating: _rating,
        category: _category,
        message: _controller.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback enviado com sucesso!'),
        ),
      );

      _controller.clear();

      setState(() {
        _rating = 0;
        _category = 'Sugestão';
      });

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar feedback: $e'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: const Text('Feedback'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.message_rounded,
                color: primaryColor,
                size: 42,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sua opinião importa!',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajude a tornar o AirShield cada vez melhor.',
                style: TextStyle(color: secondaryColor),
              ),
              const SizedBox(height: 32),

              const Text(
                'Como você avalia o aplicativo?',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final selected = index < _rating;

                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    icon: Icon(
                      selected ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF2B84B),
                      size: 36,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              const Text(
                'Tipo de feedback',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: surfaceColor,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Sugestão', 'Problema', 'Elogio']
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 28),

              const Text(
                'Conte um pouco mais',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Escreva sua opinião...',
                  hintStyle: const TextStyle(
                    color: secondaryColor,
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _sendFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Enviar feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
