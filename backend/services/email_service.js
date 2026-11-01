// A bounded HTTPS request works on Render's free tier without SMTP sockets.
function getEmailStatus() {
  return process.env.BREVO_API_KEY?.trim() && process.env.EMAIL_FROM?.trim()
    ? 'CONFIGURED' : 'NOT_CONFIGURED';
}

async function sendEmail(mail, { fetchImpl = globalThis.fetch, timeoutMs = 20000 } = {}) {
  if (getEmailStatus() !== 'CONFIGURED') {
    throw new Error('Email sending requires BREVO_API_KEY and EMAIL_FROM on the backend.');
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetchImpl('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': process.env.BREVO_API_KEY.trim(),
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        sender: mail.from,
        to: (Array.isArray(mail.to) ? mail.to : [mail.to]).map(email => ({ email })),
        replyTo: mail.replyTo ? { email: mail.replyTo } : undefined,
        subject: mail.subject,
        ...(mail.html ? { htmlContent: mail.html } : { textContent: mail.text }),
      }),
      signal: controller.signal,
    });
    const data = await response.json();
    if (!response.ok || typeof data?.messageId !== 'string' || !data.messageId.trim()) {
      // Avoid returning provider payloads that could contain recipient data or secrets.
      throw new Error(`Email provider rejected the request (HTTP ${response.status}). Check Brevo logs, API key, verified sender, transactional account activation and sending limits.`);
    }
    // Acceptance by the provider is not a guarantee of inbox delivery.
    return { messageId: data.messageId, accepted: Array.isArray(mail.to) ? mail.to : [mail.to], rejected: [] };
  } catch (error) {
    if (controller.signal.aborted) {
      throw new Error('Email provider request timed out. Please try again.');
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { sendEmail, getEmailStatus };
