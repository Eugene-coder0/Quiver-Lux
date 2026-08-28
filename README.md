# Quiver Lux

## Local Development

Frontend:

```bash
flutter run -d chrome --web-port 61198
```

Backend:

```bash
cd backend
npm start
```

By default, Flutter uses `http://127.0.0.1:5000/api` in local development.

## Live Mode Switch Checklist

As of August 28, 2026, these are the required changes before using real Paystack payments:

1. Replace the backend Paystack key in `backend/.env`

```env
PAYSTACK_SECRET_KEY=sk_live_your_real_live_secret_key
```

2. Set the backend CORS origins in `backend/.env`

```env
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://www.your-frontend-domain.com
```

3. Build Flutter with the real API base URL

```bash
flutter build web --dart-define=API_BASE_URL=https://your-backend-domain.com
```

4. Ensure Paystack webhooks point to your public backend

```text
https://your-backend-domain.com/api/payments/webhook
```

5. Ensure customer checkout is opened from the real frontend domain so Paystack returns to the deployed app, for example:

```text
https://your-frontend-domain.com/payment-status
```

## Notes

- Do not place Paystack secret keys in Flutter.
- Vendor bank details are entered in the UI; Paystack subaccounts are created on the backend.
- Hosted Paystack checkout is used for card, bank, bank transfer, and USSD flows.
