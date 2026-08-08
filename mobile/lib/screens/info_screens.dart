import 'package:flutter/material.dart';

const kBrandGreen = Color(0xFF2E7D32);

class InfoSection {
  final String heading;
  final String body;
  const InfoSection(this.heading, this.body);
}

class StaticInfoScreen extends StatelessWidget {
  final String title;
  final List<InfoSection> sections;

  const StaticInfoScreen({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sections
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.heading,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(s.body,
                          style: const TextStyle(fontSize: 14, height: 1.5)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ----  सुपरमार्केट साठी standard content ----

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const StaticInfoScreen(
      title: "About Us",
      sections: [
        InfoSection("आमच्याबद्दल",
            "सुपरमार्केट हे विश्वासू आणि दर्जेदार grocery store आहे. रोजच्या गरजेच्या वस्तूंपासून ते खास पदार्थांपर्यंत, सगळं एकाच ठिकाणी परवडणाऱ्या किमतीत उपलब्ध करून देणं हे आमचं ध्येय आहे."),
        InfoSection("आमची बांधिलकी",
            "उत्तम दर्जाचे उत्पादने, वाजवी दर, आणि जलद घरपोच सेवा — या तिन्हींवर आमचा भर आहे. आमच्या ग्राहकांचं समाधान हीच आमची सर्वात मोठी उपलब्धी आहे."),
      ],
    );
  }
}

class StoreInformationScreen extends StatelessWidget {
  const StoreInformationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const StaticInfoScreen(
      title: "Store Information",
      sections: [
        InfoSection("पत्ता",
            "सुपरमार्केट\n रोड, शिवशक्ती चौक"),
        InfoSection("संपर्क", "फोन: 0000884976 / 777400000"),
        InfoSection("दुकानाची वेळ", "सकाळी 9:00 ते रात्री 10:00 (सातही दिवस)"),
        InfoSection("Delivery क्षेत्र",
            "सध्या दुकानाच्या जवळच्या भागात home delivery उपलब्ध आहे."),
      ],
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const StaticInfoScreen(
      title: "Help & Support",
      sections: [
        InfoSection("मदत हवी आहे?",
            "ऑर्डर, delivery, किंवा product संबंधी कुठलीही अडचण असल्यास खाली दिलेल्या नंबरवर कॉल करा."),
        InfoSection("संपर्क", "फोन: 209000 / 00013110\nवेळ: सकाळी 9 ते रात्री 10"),
        InfoSection("वारंवार विचारले जाणारे प्रश्न",
            "• ऑर्डर किती वेळात पोहोचते? — साधारण 30-60 मिनिटांत\n• Payment कसं करायचं? — सध्या फक्त Cash on Delivery उपलब्ध आहे\n• ऑर्डर रद्द कशी करायची? — वरील नंबरवर कॉल करून सांगा"),
      ],
    );
  }
}

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const StaticInfoScreen(
      title: "Refund, Terms and Policies",
      sections: [
        InfoSection("Return / Refund Policy",
            "खराब, कालबाह्य, किंवा चुकीचा product आल्यास delivery च्या वेळीच किंवा त्याच दिवशी संपर्क साधल्यास तो बदलून दिला जाईल किंवा पैसे परत केले जातील."),
        InfoSection("Delivery Policy",
            "Order confirm झाल्यावर तो साधारण 30-60 मिनिटांत पोहोचवला जातो. Stock उपलब्धतेनुसार वेळ बदलू शकतो."),
        InfoSection("Payment",
            "सध्या फक्त Cash on Delivery (COD) हा payment पर्याय उपलब्ध आहे."),
        InfoSection("Privacy",
            "तुमची वैयक्तिक माहिती (नाव, फोन, पत्ता) फक्त order पूर्ण करण्यासाठी वापरली जाते, ती कुठेही शेअर केली जात नाही."),
      ],
    );
  }
}
