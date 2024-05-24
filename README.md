Welcome! This repository contains a project I completed for my Files & Databases, which I received approval to share as a portfolio project. 
In this project I design and create a MySQL database for the Madrid Metro system.
You can find my first draft of the schema, ER model diagram, and metadata description in the documentation. It also includes various query and trigger functionality tests using sample data. 

As a Python programer at heart, I decided to organize the database into many separate procedures (essentially functions) that carry out a specific task and update the database accordingly.
- RegisterNewCustomer(full_name, date_of_birth, zip_code, email, phone_number, student_status, disability_status, family normal discount status, family special discount status). -- Registers a new customer by inserting their data and assigning a unique customer ID.
- Populate zip codes() -- Generates fake zip codes for all of Madrid (this data was not provided to us, so I used fake ones as a placeholder to show how the database works).
- IssueMonthlyCard(customer_id) -- Generates a new monthly card for a given customer with a starting balance of 12 euros
- IssueMultiUseCard(customer_id) -- Generates a new multiuse card for a given customer that is valid for 30 days.
- ReloadMonthlyCard(card_id) -- Reloads a monthly card for a given card and extends validity for 30 days.
- ReloadJultiUseCard(card_id, amount) -- Reloads a multiuse card with a given amount.
- ReplaceMonthlyCard(customer_id) -- Replaces a lost/stolen monthly card and assigns a new card id.
- ReplaceMultiUseCard(customer_id) -- Replaces a lost/stolen multiuse card and assigns a new card id.
- RemoveCustomer(customer_id) -- Removes a customer, their metrocards, and past transactions from the database.
- CalculateMonthlyPrice(customer_id) -- Calculates the price of a monthly card for a given customer using a combination of zoning, age group, student status, disability status, and family discounts.

I also wrote various triggers throughout my code to handle specific constraints.
