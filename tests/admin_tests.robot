*** Settings ***
Documentation    Petstore API Tests from Administrator Perspective
Resource         ../resources/keywords.robot
Suite Setup      Create Session To Petstore API

*** Test Cases ***
Admin Can Delete Inactive Pets
    [Documentation]    As an admin, I want to delete inactive pets to maintain the database order.
    
    Log    ----- TEST STARTED: Admin Can Delete Inactive Pets -----    level=INFO
    
    Log    STEP 1: Generating test data    level=INFO
    ${pet_id}    Generate Random ID
    ${pet_name}    Set Variable    TestInactive${pet_id}
    Log    Using pet ID: ${pet_id} and name: ${pet_name}    level=INFO
    
    Log    STEP 2: Adding pet with 'sold' status to database    level=INFO
    ${add_response}    Add New Pet    ${pet_id}    ${pet_name}    sold    cat
    Should Be Equal As Strings    ${add_response}[status]    sold
    Log    ✓ Inactive pet added successfully    level=INFO
    
    Log    Waiting for API to process the new pet...    level=INFO
    Sleep    5s
    
    Log    STEP 3: Retrieving all inactive pets    level=INFO
    ${sold_pets}    Get Pets By Status    sold
    ${count}=    Get Length    ${sold_pets}
    Log    Found ${count} inactive pets    level=INFO
    
    Log    STEP 4: Verifying our inactive pet is on the list    level=INFO
    ${found}=    Set Variable    ${FALSE}
    
    Log    Searching for pet ID ${pet_id} in inactive pets list...    level=INFO
    FOR    ${pet}    IN    @{sold_pets}
        ${is_our_pet}=    Evaluate    str(${pet}[id]) == str(${pet_id})
        IF    ${is_our_pet}
            Set Test Variable    ${found}    ${TRUE}
            Log    ✓ Found our inactive pet in sold list: ${pet}    level=INFO
            BREAK
        END
    END
    
    Should Be True    ${found}    Our inactive pet with ID ${pet_id} was not found among inactive pets
    Log    ✓ Inactive pet was found in the sold pets list    level=INFO
    
    Log    STEP 5: Deleting inactive pet    level=INFO
    ${deletion_successful}=    Delete Pet And Verify    ${pet_id}    max_attempts=5    delay=5s
    Should Be True    ${deletion_successful}    Failed to delete pet ID ${pet_id} after multiple attempts
    Log    ✓ Inactive pet deleted successfully    level=INFO
    
    Log    ----- TEST COMPLETED SUCCESSFULLY -----    level=INFO 