import { Given, When } from "cypress-cucumber-preprocessor/steps";
import {
  computeHeadersFromEmail,
  SIGN_IN_EMAIL_TEMPLATE,
  ADMIN_ACCOUNT_CREATED_TEMPLATE,
  NOMINATION_CONFIRMATION_EMAIL_TEMPLATE,
  BASIC_TEMPLATE,
} from "../commands";

Given(
  "An email sign in notification should be sent to the email {string}",
  (email) => {
    cy.appSentEmails().then((emails) => {
      expect(emails).to.have.lengthOf(1);
      const headersHash = computeHeadersFromEmail(emails[0]);
      expect(headersHash["template-id"]).to.eq(SIGN_IN_EMAIL_TEMPLATE);
      expect(headersHash.To).to.eq(email);
    });
  }
);

Given(
  "An Admin account created email should be sent to the email {string}",
  (email) => {
    cy.appSentEmails().then((emails) => {
      expect(emails).to.have.lengthOf(1);
      const headersHash = computeHeadersFromEmail(emails[0]);
      expect(headersHash["template-id"]).to.eq(ADMIN_ACCOUNT_CREATED_TEMPLATE);
      expect(headersHash.To).to.eq(email);
    });
  }
);

Given(
  "Email should be sent to Nominated School Induction Coordinator to email {string}",
  (email) => {
    cy.appSentEmails().then((emails) => {
      expect(emails).to.have.lengthOf(1);
      const headersHash = computeHeadersFromEmail(emails[0]);
      expect(headersHash["template-id"]).to.eq(
        NOMINATION_CONFIRMATION_EMAIL_TEMPLATE
      );
      expect(headersHash.To).to.eq(email);
    });
  }
);

Given(
  "Confirmation email should be sent to the Induction Coordinator to email {string}",
  (email) => {
    cy.appSentEmails().then((emails) => {
      expect(emails).to.have.lengthOf(1);
      const headersHash = computeHeadersFromEmail(emails[0]);
      expect(headersHash["template-id"]).to.eq(BASIC_TEMPLATE);
      expect(headersHash.To).to.eq(email);
    });
  }
);

When(
  "I should be able to login with magic link for email {string}",
  (email) => {
    cy.appSentEmails().then((emails) => {
      expect(emails).to.have.lengthOf(1);
      const headersHash = computeHeadersFromEmail(emails[0]);
      expect(headersHash["template-id"]).to.eq(SIGN_IN_EMAIL_TEMPLATE);
      expect(headersHash.To).to.eq(email);
      cy.visit(
        headersHash.personalisation.sign_in.replace(
          "http://www.example.com",
          ""
        )
      );
      cy.get("h1").should("contain", "You’re now signed in");
    });
  }
);
