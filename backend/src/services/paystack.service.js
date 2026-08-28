import axios from 'axios';
import { env } from '../config/env.js';
import { ApiError } from '../utils/apiError.js';

const PAYSTACK_BASE_URL = 'https://api.paystack.co';

const paystackHeaders = {
  Authorization: `Bearer ${env.PAYSTACK_SECRET_KEY}`,
  'Content-Type': 'application/json',
};

export const initializePayment = async ({
  email,
  amountInKobo,
  reference,
  metadata,
  callbackUrl,
  channels,
  splitCode,
  subaccount,
  transactionCharge,
  bearer,
}) => {
  try {
    const response = await axios.post(
      `${PAYSTACK_BASE_URL}/transaction/initialize`,
      {
        email,
        amount: amountInKobo,
        reference,
        metadata,
        ...(callbackUrl ? { callback_url: callbackUrl } : {}),
        ...(Array.isArray(channels) && channels.length > 0 ? { channels } : {}),
        ...(splitCode ? { split_code: splitCode } : {}),
        ...(subaccount ? { subaccount } : {}),
        ...(transactionCharge !== undefined ? { transaction_charge: transactionCharge } : {}),
        ...(bearer ? { bearer } : {}),
      },
      {
        headers: paystackHeaders,
      }
    );

    return response.data.data;
  } catch (error) {
    throw new ApiError(500, 'Paystack payment initialization failed', error.response?.data || error.message);
  }
};

export const verifyPaymentTransaction = async (reference) => {
  try {
    const response = await axios.get(
      `${PAYSTACK_BASE_URL}/transaction/verify/${encodeURIComponent(reference)}`,
      {
        headers: {
          Authorization: paystackHeaders.Authorization,
        },
      }
    );

    return response.data.data;
  } catch (error) {
    throw new ApiError(500, 'Paystack verification request failed', error.response?.data || error.message);
  }
};

export const listBanks = async ({
  country = 'nigeria',
  currency = 'NGN',
  payWithBank = false,
  payWithBankTransfer = false,
  enabledForVerification = false,
} = {}) => {
  try {
    const response = await axios.get(`${PAYSTACK_BASE_URL}/bank`, {
      headers: {
        Authorization: paystackHeaders.Authorization,
      },
      params: {
        country,
        currency,
        ...(payWithBank ? { pay_with_bank: true } : {}),
        ...(payWithBankTransfer ? { pay_with_bank_transfer: true } : {}),
        ...(enabledForVerification ? { enabled_for_verification: true } : {}),
      },
    });

    return response.data.data ?? [];
  } catch (error) {
    throw new ApiError(500, 'Unable to fetch Paystack banks', error.response?.data || error.message);
  }
};

export const resolveAccountNumber = async ({ accountNumber, bankCode }) => {
  try {
    const response = await axios.get(`${PAYSTACK_BASE_URL}/bank/resolve`, {
      headers: {
        Authorization: paystackHeaders.Authorization,
      },
      params: {
        account_number: accountNumber,
        bank_code: bankCode,
      },
    });

    return response.data.data;
  } catch (error) {
    const message =
      error.response?.data?.message || 'Unable to verify the bank account details with Paystack';
    throw new ApiError(400, message, error.response?.data || error.message);
  }
};

export const createSubaccount = async ({
  businessName,
  bankCode,
  accountNumber,
  percentageCharge,
  description,
  primaryContactEmail,
}) => {
  try {
    const response = await axios.post(
      `${PAYSTACK_BASE_URL}/subaccount`,
      {
        business_name: businessName,
        bank_code: bankCode,
        account_number: accountNumber,
        percentage_charge: percentageCharge,
        ...(description ? { description } : {}),
        ...(primaryContactEmail ? { primary_contact_email: primaryContactEmail } : {}),
      },
      {
        headers: paystackHeaders,
      }
    );

    return response.data.data;
  } catch (error) {
    const message =
      error.response?.data?.message || 'Unable to create the vendor Paystack subaccount';
    throw new ApiError(400, message, error.response?.data || error.message);
  }
};

export const createTransactionSplit = async ({
  name,
  currency = 'NGN',
  subaccounts,
  bearerType = 'account',
}) => {
  try {
    const response = await axios.post(
      `${PAYSTACK_BASE_URL}/split`,
      {
        name,
        type: 'flat',
        currency,
        subaccounts,
        bearer_type: bearerType,
      },
      {
        headers: paystackHeaders,
      }
    );

    return response.data.data;
  } catch (error) {
    const message =
      error.response?.data?.message || 'Unable to create the Paystack transaction split';
    throw new ApiError(400, message, error.response?.data || error.message);
  }
};
