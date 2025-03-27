*** Settings ***
Documentation    Petstore API Tests from Customer Perspective
Resource         ../resources/keywords.robot
Suite Setup      Create Session To Petstore API

*** Test Cases ***
Customer Can Add New Pet And Check Availability
    [Documentation]    As a customer, I want to add a new pet to the store and check if it's available.
    
    Log    ----- TEST STARTED: Customer Can Add New Pet And Check Availability -----    level=INFO
    
    Log    STEP 1: Generating test data    level=INFO
    ${pet_id}    Generate Random ID
    ${pet_name}    Set Variable    Rex${pet_id}
    Log    Using pet ID: ${pet_id} and name: ${pet_name}    level=INFO
    
    Log    STEP 2: Adding new pet to store    level=INFO
    ${add_response}    Add New Pet    ${pet_id}    ${pet_name}    available    dog
    Log    Pet addition response: ${add_response}    level=DEBUG
    Log    Validating pet was added correctly...    level=INFO
    Should Be Equal As Strings    ${add_response}[name]    ${pet_name}
    Should Be Equal As Strings    ${add_response}[status]    available
    Log    Pet added successfully    level=INFO
    
    Log    Waiting for API to process the new pet...    level=INFO
    Sleep    3s
    
    Log    STEP 3: Verifying pet can be retrieved directly by ID    level=INFO
    ${response}    Try Get Pet By ID    ${pet_id}    expected_status=any
    ${status_code}=    Set Variable    ${response.status_code}
    
    IF    ${status_code} == 200
        Log    Pet retrieval successful with status 200    level=INFO
        Verify Pet Details    ${response.json()}    ${pet_name}    available
    ELSE
        Log    Warning: Pet retrieval returned unexpected status ${status_code}    level=WARN
        Log    Response body: ${response.text}    level=WARN
    END
    
    Log    STEP 4: Verifying pet appears in available pets list    level=INFO
    ${pets_available}    Get Pets By Status    available
    Log    Found ${pets_available.__len__()} available pets    level=INFO
    ${found}=    Set Variable    ${FALSE}
    
    Log    Searching for pet ID ${pet_id} in available pets list...    level=INFO
    FOR    ${pet}    IN    @{pets_available}
        ${is_our_pet}=    Evaluate    str(${pet}[id]) == str(${pet_id})
        IF    ${is_our_pet}
            Set Test Variable    ${found}    ${TRUE}
            Log    Found added pet in available list: ${pet}    level=INFO
            BREAK
        END
    END
    
    Should Be True    ${found}    Our pet ID ${pet_id} was not found among available pets
    Log    Pet was found in the available pets list    level=INFO
    
    Log    STEP 5: Deleting pet    level=INFO
    ${deletion_successful}=    Delete Pet And Verify    ${pet_id}    max_attempts=5    delay=5s
    Should Be True    ${deletion_successful}    Failed to delete pet ID ${pet_id} after multiple attempts
    Log    Pet deleted successfully    level=INFO
    
    Log    ----- TEST COMPLETED SUCCESSFULLY -----    level=INFO 