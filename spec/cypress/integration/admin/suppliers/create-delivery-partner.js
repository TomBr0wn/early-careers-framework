describe("Admin user creating delivery partner", () => {
  const leadProviderName = "Lead Provider 1";
  const cohortName = "2021 to 2023";

  beforeEach(() => {
    cy.login("admin");
  });

  it("should show a create supplier button", () => {
    cy.visit("/admin/suppliers");
    cy.get(".govuk-button").should("contain", "Add a new delivery partner");
  });

  it("should create a new delivery partner", () => {
    cy.appScenario("admin/suppliers/create_supplier");
    const deliveryPartnerName = "New delivery partner";

    cy.visit("/admin/suppliers");
    cy.clickCreateDeliveryPartnerButton();

    cy.location("pathname").should(
      "equal",
      "/admin/suppliers/new/delivery-partner/choose-name"
    );
    cy.chooseSupplierName(deliveryPartnerName);

    cy.location("pathname").should(
      "equal",
      "/admin/suppliers/new/delivery-partner/choose-lps"
    );
    cy.get(
      "input[name='delivery_partner_form[lead_provider_ids][]'][type=checkbox]"
    ).should("have.length", 1);
    cy.get(
      "input[name='delivery_partner_form[provider_relationship_hashes][]'][type=checkbox]"
    ).should("have.length", 1);
    cy.chooseFirstLeadProviderAndCohort();

    cy.location("pathname").should(
      "equal",
      "/admin/suppliers/new/delivery-partner/review"
    );
    cy.get("main").should("contain", deliveryPartnerName);
    cy.get("main").should("contain", leadProviderName);

    cy.get("main").should("contain", cohortName);
    cy.confirmCreateSupplier();

    cy.location("pathname").should("contain", "/admin/suppliers");
    cy.get("main").should("contain", deliveryPartnerName);
    cy.get("main").should("contain", "Delivery partner created");
  });

  it("remembers previous choices", () => {
    cy.appScenario("admin/suppliers/create_supplier");
    const deliveryPartnerName = "New delivery partner";

    cy.visit("/admin/suppliers");
    cy.clickCreateDeliveryPartnerButton();

    cy.chooseSupplierName(deliveryPartnerName);
    cy.clickBackLink();
    cy.get("input[type=text]").should("have.value", deliveryPartnerName);
    cy.clickCommitButton();

    cy.chooseFirstLeadProviderAndCohort();
    cy.clickBackLink();
    cy.get(
      "[name='delivery_partner_form[lead_provider_ids][]'][type=checkbox]"
    ).should("be.checked");
    cy.get(
      "[name='delivery_partner_form[provider_relationship_hashes][]'][type=checkbox]"
    ).should("be.checked");
    cy.clickCommitButton();

    cy.get("main").should("contain", deliveryPartnerName);
    cy.get("main").should("contain", leadProviderName);
    cy.get("main").should("contain", cohortName);
    cy.confirmCreateSupplier();

    cy.location("pathname").should("equal", "/admin/suppliers");
    cy.get("main").should("contain", deliveryPartnerName);
  });

  it("allows changing name choice", () => {
    cy.appScenario("admin/suppliers/create_supplier");
    const deliveryPartnerName = "New delivery partner";

    cy.visit("/admin/suppliers");
    cy.clickCreateDeliveryPartnerButton();

    cy.chooseSupplierName("wrong name");
    cy.chooseFirstLeadProviderAndCohort();

    cy.get("a").contains("Change name").click();
    cy.chooseSupplierName(`{selectall}${deliveryPartnerName}`);

    cy.clickCommitButton();
    cy.confirmCreateSupplier();

    cy.location("pathname").should("equal", "/admin/suppliers");
    cy.get("main").should("contain", deliveryPartnerName);
  });
});
