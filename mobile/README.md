# QuickMart Flutter App

तुमच्या QuickMart backend (https://supermarket-1f13.onrender.com) शी जोडलेलं
खरं Android app — GitHub Actions वापरून मोबाईलवरूनच APK बनतो, PC लागत नाही.

## GitHub वर टाकणं आणि APK मिळवणं — पायऱ्या

1. या `mobile` folder मधल्या **सगळ्या फाइल्स** तुमच्या `SuperMarket` GitHub repo मध्ये,
   अगदी तशाच folder structure सह टाका (root मध्ये, backend/frontend च्या शेजारी):
   ```
   SuperMarket/
   ├── backend/        (आधीच आहे)
   ├── frontend/        (आधीच आहे)
   └── mobile/          (नवीन — या README सोबतच्या सगळ्या फाइल्स)
       ├── lib/
       ├── pubspec.yaml
       └── .github/workflows/build_apk.yml
   ```

   टीप: `.github/workflows/build_apk.yml` ही फाईल तुमच्या **repo च्या root मध्ये**
   `.github/workflows/` या नावाच्या folder मध्येच असायला हवी (mobile च्या आत नाही) —
   तरच GitHub Actions ती ओळखेल. म्हणजे शेवटी structure असं दिसेल:
   ```
   SuperMarket/
   ├── .github/workflows/build_apk.yml
   ├── backend/
   ├── frontend/
   └── mobile/
       ├── lib/...
       └── pubspec.yaml
   ```

2. सगळ्या फाइल्स commit झाल्या की, तुमच्या repo च्या वरती **"Actions"** टॅबवर जा.

3. "Build QuickMart APK" नावाचं workflow आपोआप सुरू होईल (push केल्यावर लगेच).
   ते चालू असताना पिवळं 🟡 चिन्ह दिसेल, पूर्ण झालं की हिरवं ✅.
   याला साधारण **5-8 मिनिटं** लागतात.

4. पूर्ण झाल्यावर तुमच्या repo च्या वरती **"Releases"** विभागात जा
   (repo च्या मुख्य पानावर उजवीकडे "Releases" दिसेल).
   तिथे नवीन release दिसेल — त्यात **app-release.apk** ही फाईल असेल.

5. ती फाईल फोनवर टॅप करून डाउनलोड करा, मग उघडून **Install** करा
   (पहिल्यांदा "Install from unknown sources" ची परवानगी मागेल — Allow करा).

## लक्षात ठेवा
- App backend शी बोलतं ते `lib/services/api_service.dart` मधल्या URL वर अवलंबून आहे.
  Backend ची लिंक बदलली, तर ही फाईल update करून पुन्हा push करा — APK आपोआप नव्याने बनेल.
- Free Render server sleep मधून उठायला वेळ लागतो, त्यामुळे app मध्ये products लोड
  व्हायला पहिल्या वेळी ३०-५० सेकंद लागू शकतात.
