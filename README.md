# Petstore API Testing Framework

Sample test automation framework for the Swagger Petstore API using Robot Framework.

## Overview

This project contains automated tests for the Swagger Petstore API (https://petstore.swagger.io/). The tests cover basic functionalities from two perspectives:

1. **Administrator Perspective** - Managing pets in the database
2. **Customer Perspective** - Adding and checking availability of pets

## Prerequisites

- Python 3.6 or higher
- Robot Framework
- Robot Framework RequestsLibrary
- Additional dependencies listed in requirements.txt

## Installation

1. Clone this repository
2. Install Python dependencies:

```bash
pip install -r requirements.txt
```

## Test Cases

### Administrator Test

- **Admin Can Delete Inactive Pets**: Tests the ability for administrators to clean up inactive (sold) pets from the database.

### Customer Test

- **Customer Can Add New Pet And Check Availability**: Tests the ability for customers to add new pets to the store and verify their availability.

## Running the Tests

### Run All Tests

```bash
robot tests/
```

### Run Specific Test Suite

```bash
robot tests/admin_tests.robot
```

```bash
robot tests/customer_tests.robot
```

## API Reliability Considerations

**Important note**: The Petstore API is publicly available, which means it is shared by many users simultaneously. Depending on the current server load, tests may require adjustments:

1. You may need to increase the number of retry attempts in test cases, especially for pet deletion operations:
   ```robot
   ${deletion_successful}=    Delete Pet And Verify    ${pet_id}    max_attempts=10    delay=5s
   ```

2. During high API load, you may encounter:
   - 404 errors for pets that actually exist
   - Delays in change propagation
   - Occasional 500 or 503 errors

3. If you experience test execution problems I woulf recommend:
   - Increasing the `delay` parameter between retries
   - Increasing the `max_attempts` parameter for more retry attempts
   - Adding longer delays after adding a pet (`Sleep    10s`)

These adjustments will allow for stable test execution even during high load.
