# Quiver Lux 💎

> A modern multi-vendor luxury marketplace for premium home decor and accessory brands, built with Flutter Web and a Node.js backend.

Quiver Lux is designed to support a luxury retail experience across shoppers, vendors, and marketplace administrators. The platform combines a responsive storefront, backend commerce workflows, and secure Paystack-powered payments with vendor payout automation.

---

## ✨ Key Features

- **Multi-vendor marketplace:** Dedicated experiences for customers, vendors, and admin operators.
- **Paystack integration:** Secure checkout for cards, bank transfers, and USSD with backend verification.
- **Automated vendor payouts:** Vendor banking details are captured in the UI and mapped to Paystack subaccounts on the backend.
- **Responsive storefront:** Flutter Web interface optimized for desktop and mobile browser layouts.
- **Marketplace operations:** Support for payout flows, payment processing, and commerce administration.

---

## 🛠️ Tech Stack

- **Frontend:** Flutter Web, Dart
- **Backend:** Node.js, Express
- **Database & ORM:** Prisma
- **Payment Processing:** Paystack API
- **Deployment:** Vercel-ready backend and Flutter web deployment support

---

## 📁 Project Structure

```text
quiver-lux/
├── lib/                  # Flutter frontend application
├── backend/              # Express API and server logic
├── android/              # Android platform files
├── ios/                  # iOS platform files
├── web/                  # Web app entry and static assets
├── linux/                # Linux desktop platform files
├── macos/                # macOS desktop platform files
├── windows/              # Windows desktop platform files
├── test/                 # Flutter tests
├── analysis_options.yaml # Dart linting rules
├── pubspec.yaml          # Flutter dependencies
├── README.md             # Project documentation
├── vercel.json           # Vercel config
└── LICENSE               # Project license
```

---

## 🚀 Local Development

### 1. Frontend setup

Start the Flutter web app on a fixed local port:

```bash
flutter run -d chrome --web-port 61198
```

### 2. Backend setup

Start the API server:

```bash
cd backend
npm install
# Copy .env.example to .env, then set DATABASE_URL for your local PostgreSQL database.
npm run db:push
npm start
```

> By default, the frontend connects to `http://127.0.0.1:5000/api` during local development.
> The example configuration uses a safe Paystack mock mode, so local checkout does not create a real charge.

---

## ⚙️ Live Mode Checklist

Before switching to real Paystack transactions, complete the following:

1. Update the backend secret key in `backend/.env`:

```env
PAYSTACK_SECRET_KEY=sk_live_your_real_live_secret_key
```

2. Configure the allowed frontend domains in `backend/.env`:

```env
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://www.your-frontend-domain.com
```

3. Build the Flutter app with the production backend URL:

```bash
flutter build web --dart-define=API_BASE_URL=https://your-backend-domain.com
```

4. Point the Paystack webhook to the public backend URL:

```text
https://your-backend-domain.com/api/payments/webhook
```

5. Ensure the checkout flow opens from the real frontend domain so Paystack can redirect back to the app, for example:

```text
https://your-frontend-domain.com/payment-status
```

---

## 🔒 Security & System Notes

- Never place Paystack secret keys in the Flutter app.
- Vendor banking details are entered in the UI and mapped to Paystack subaccounts on the backend.
- Hosted Paystack checkout supports card, bank transfer, and USSD payment flows.
- Webhook validation and backend-side payment verification should remain server-side only.

---

## 📄 License

This project is licensed under the MIT License.
