import { env } from '../config/env.js';
import { ApiError } from '../utils/apiError.js';
import { createSubaccount, resolveAccountNumber } from './paystack.service.js';

const normalize = (value) => {
  const text = value?.toString().trim();
  return text ? text : '';
};

const TEST_SUBACCOUNT_PREFIX = 'TEST_SUB_';

const isTestSecretKey = () => env.PAYSTACK_SECRET_KEY.trim().startsWith('sk_test_');

export const isMockPaystackSubaccountCode = (value) =>
  normalize(value).startsWith(TEST_SUBACCOUNT_PREFIX);

export const shouldUseTestPaystackBypass = (error) => {
  if (!env.ALLOW_TEST_PAYSTACK_BYPASS || !isTestSecretKey()) {
    return false;
  }

  const message = [
    error?.message,
    error?.errorDetails?.message,
    error?.errorDetails?.error,
    typeof error?.errorDetails === 'string' ? error.errorDetails : '',
    error?.errors?.message,
    error?.errors?.error,
    typeof error?.errors === 'string' ? error.errors : '',
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  return message.includes('test mode');
};

const buildBypassAccountName = (accountNumber) => {
  const digits = normalize(accountNumber);
  const suffix = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
  return `Test Account ${suffix}`.trim();
};

export const buildTestModePaystackFallback = ({
  businessName,
  brandName,
  storeName,
  accountNumber,
  bankCode,
  accountName,
}) => ({
  paystackRecipientCode: '',
  paystackSubaccountCode: `${TEST_SUBACCOUNT_PREFIX}${Date.now()}_${normalize(accountNumber)}`,
  paystackBusinessName:
    normalize(businessName) || normalize(brandName) || normalize(storeName),
  paystackAccountName: normalize(accountName) || buildBypassAccountName(accountNumber),
  paystackAccountNumber: normalize(accountNumber),
  paystackBankCode: normalize(bankCode),
  paystackSetupComplete: true,
  paystackBypassMode: true,
});

export const buildVendorPaystackProfile = async ({
  storeName,
  brandName,
  businessName,
  bankCode,
  accountNumber,
  contactEmail,
  description,
  commissionRate = 10,
  legacySubaccountCode,
  legacyRecipientCode,
  legacyAccountName,
}) => {
  const normalizedBankCode = normalize(bankCode);
  const normalizedAccountNumber = normalize(accountNumber);
  const normalizedBusinessName =
    normalize(businessName) || normalize(brandName) || normalize(storeName);

  if (normalizedBankCode && normalizedAccountNumber) {
    if (!normalizedBusinessName) {
      throw new ApiError(400, 'Business name is required before creating a Paystack subaccount');
    }

    try {
      const resolvedAccount = await resolveAccountNumber({
        accountNumber: normalizedAccountNumber,
        bankCode: normalizedBankCode,
      });
      const subaccount = await createSubaccount({
        businessName: normalizedBusinessName,
        bankCode: normalizedBankCode,
        accountNumber: normalizedAccountNumber,
        percentageCharge: Number(commissionRate),
        description: normalize(description),
        primaryContactEmail: normalize(contactEmail),
      });

      return {
        paystackRecipientCode: '',
        paystackSubaccountCode: normalize(subaccount.subaccount_code),
        paystackBusinessName: normalize(subaccount.business_name) || normalizedBusinessName,
        paystackAccountName:
          normalize(subaccount.account_name) ||
          normalize(resolvedAccount.account_name) ||
          normalize(legacyAccountName),
        paystackAccountNumber: normalizedAccountNumber,
        paystackBankCode: normalizedBankCode,
        paystackSetupComplete: Boolean(normalize(subaccount.subaccount_code)),
        paystackBypassMode: false,
      };
    } catch (error) {
      if (shouldUseTestPaystackBypass(error)) {
        return buildTestModePaystackFallback({
          businessName: normalizedBusinessName,
          brandName,
          storeName,
          accountNumber: normalizedAccountNumber,
          bankCode: normalizedBankCode,
          accountName: legacyAccountName,
        });
      }
      throw error;
    }
  }

  const normalizedLegacySubaccount = normalize(legacySubaccountCode);
  const normalizedLegacyRecipient = normalize(legacyRecipientCode);
  if (normalizedLegacySubaccount || normalizedLegacyRecipient) {
    return {
      paystackRecipientCode: normalizedLegacyRecipient,
      paystackSubaccountCode: normalizedLegacySubaccount,
      paystackBusinessName: normalizedBusinessName,
      paystackAccountName: normalize(legacyAccountName),
      paystackAccountNumber: normalizedAccountNumber,
      paystackBankCode: normalizedBankCode,
      paystackSetupComplete: true,
    };
  }

  throw new ApiError(
    400,
    'Provide a bank code and account number so Quiver Lux can verify the account and create the vendor Paystack subaccount'
  );
};
