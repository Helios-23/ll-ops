# Email Config

Current process is to use personal Gmail accounts to add and operate custom `@epytype.org` email addresses, with Cloudflare Email Routing handling inbound forwarding and Gmail handling outbound SMTP.

## Add Custom Address and Routing in Cloudflare

Use Cloudflare Email Routing to create the custom address and forward inbound mail to the destination mailbox.

1. Open the Email Routing routes page for `epytype.org`:
   `https://dash.cloudflare.com/6089ebdfff63a15c9b0095bbae716765/epytype.org/email/routing/routes`
2. Sign in to the Cloudflare dashboard if prompted.
3. Confirm Email Routing is enabled for the domain.
4. Create or verify the destination address that will receive forwarded mail.
5. Add a new custom address.
6. Enter the address you want to receive mail for on `epytype.org` (for example, `j@epytype.org`).
7. Set the routing destination to the target mailbox that should receive forwarded mail.
8. Save the route.
9. Send a test message to the custom address and confirm it arrives in the destination inbox.

## Configure Free Outbound Mail (SMTP) via Google

To send mail from your custom Cloudflare domain without paying for Google Workspace, use Gmail's built-in SMTP server with a Google App Password.

1. Go to your Google Account settings:
   `https://myaccount.google.com/`
2. Under the `Security` tab, ensure `2-Step Verification` is enabled.
3. Search for `App Passwords` from the Google account search bar.
4. Create a new app password with this name:
   `j@epytype.org Cloudflare Email`
5. Copy the generated 16-character code and record it here:
   `password_created:`
6. Open Gmail in your browser, click the gear icon, and select `See all settings`.
7. Open the `Accounts and Import` tab.
8. Under `Send mail as`, click `Add another email address`.
9. Enter these values:
   - `Name`: `Jay Perry`
   - `Email Address`: `j@epytype.org`
   - `Treat as an alias`: unchecked
10. Click `Next`.
11. Enter these SMTP settings exactly:
   - `SMTP Server`: `smtp.gmail.com`
   - `Port`: `587`
   - `Username`: `jperry303`
   - `Password`: the 16-character App Password created earlier
12. Click `Add Account`.
13. Gmail sends a confirmation email to the custom domain address.
14. Because Cloudflare routing is active, the confirmation message should arrive in the destination Gmail inbox.
15. Open the confirmation email and click the confirmation link to finish setup.
