# Phase 2 Telehealth Cloud Backend Setup Guide (`မြန်မာနေ့စဉ်`)

ဤ Folder တွင် မိခင်နှင့် ကလေး Telehealth စနစ်အတွက် Production-ready **Cloud Firestore Security Rules**, **Composite Indexes**, နှင့် **Firebase Hosting** Configuration များ ပါဝင်ပါသည်။ App ဘက်မှ [`FirebaseTelehealthGateway`](../lib/data/services/telehealth_gateway.dart) သည် Firebase Auth + Firestore REST API ဖြင့် တိုက်ရိုက် ချိတ်ဆက်ထားပါသည်။

## ၁။ Firebase Project ပြင်ဆင်နည်း

1. [Firebase Console](https://console.firebase.google.com/) တွင် Project အသစ်တစ်ခု ဖန်တီးပါ (ဥပမာ - `myanmar-daily-health`)။
2. **Authentication → Sign-in method** တွင်:
   - `Email/Password` နှင့်/သို့မဟုတ် `Anonymous` login ကို Enable လုပ်ပါ။
3. **Firestore Database** ကို Production Mode ဖြင့် ဖွင့်ပါ (အနီးဆုံး `asia-southeast1` Singapore region ရွေးပါ)။
4. Local မှ Firebase CLI ဖြင့် Rules နှင့် Indexes ကို Deploy တင်ပါ-
   ```bash
   npm install -g firebase-tools
   firebase login
   cd cloud_backend
   firebase use <YOUR_FIREBASE_PROJECT_ID>
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## ၂။ App ထဲတွင် ချိတ်ဆက်အသုံးပြုနည်း

1. App → **`မိခင်/ကလေး`** → **`ဆရာဝန်ပြ`** Sub-tab သို့ သွားပါ။
2. **`Cloud Telehealth ချိတ်ဆက်မည်`** ခလုတ်ကို နှိပ်ပြီး **Firebase Project ID** နှင့် **Firebase Web API Key** ကို ထည့်သွင်းပါ။
3. မိသားစု Email/Password (သို့မဟုတ် Guest အဖြစ်) Login ဝင်ပြီးပါက **`Cloud မှတစ်ဆင့် ဆရာဝန် Queue သို့ ပို့မည်`** ခလုတ်ဖြင့် SBAR Ticket များ တိုက်ရိုက်ပေးပို့နိုင်ပါပြီ။

## ၃။ ဆရာဝန် (Verified SAMA Doctor) Role သတ်မှတ်နည်း

`firestore.rules` သည် မိခင်/ကလေး၏ ဆေးမှတ်တမ်းများကို **ကိုယ်ပိုင် Patient UID နှင့် Verified Doctor Claim ရှိသူများသာ** ကြည့်ရှုခွင့်ပြုထားပါသည်။ ဆရာဝန်အကောင့်ကို Admin SDK မှတစ်ဆင့် SAMA လိုင်စင်စိစစ်ပြီးမှသာ အောက်ပါ Custom Claims သတ်မှတ်ပေးရပါမည်-

```javascript
// Firebase Admin SDK (Server-side / Cloud Function only)
await admin.auth().setCustomUserClaims(doctorUid, {
  doctor_verified: true,
  sama_license: 'SAMA-12345',
});
```
