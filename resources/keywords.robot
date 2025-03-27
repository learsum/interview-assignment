*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    JSONLibrary
Library    DateTime
Library    String
Resource   ../variables/env_variables.robot

*** Keywords ***
Create Session To Petstore API
    [Documentation]    Creates an HTTP session to the Petstore API with verify=True
    Log    Creating session to Petstore API at ${API_URL}    level=INFO
    Create Session    petstore    ${API_URL}    verify=True
    Log    ✓ Session created successfully    level=INFO

Generate Random ID
    [Documentation]    Generates a random ID between 1000 and 9999
    Log    Generating random ID...    level=DEBUG
    ${random_id}    Evaluate    random.randint(1000, 9999)    random
    Log    ✓ Generated random ID: ${random_id}    level=INFO
    [Return]    ${random_id}

Add New Pet
    [Documentation]    Adds a new pet to the store with specified attributes
    [Arguments]    ${pet_id}    ${name}    ${status}=available    ${category_name}=dog
    Log    Adding new pet with ID: ${pet_id}, Name: ${name}, Status: ${status}, Category: ${category_name}    level=INFO
    
    # Create pet data structure
    ${category}    Create Dictionary    id=1    name=${category_name}
    ${tags}    Create List    ${category}
    ${photoUrls}    Create List    string
    ${pet_data}    Create Dictionary    
    ...    id=${pet_id}    
    ...    name=${name}    
    ...    category=${category}    
    ...    photoUrls=${photoUrls}    
    ...    tags=${tags}    
    ...    status=${status}
    
    # Send request to API
    Log    Sending pet creation request    level=DEBUG
    ${response}    POST On Session    petstore    /pet    json=${pet_data}    expected_status=200
    Log    ✓ Pet created successfully with ID: ${pet_id}    level=INFO
    
    [Return]    ${response.json()}

Try Get Pet By ID
    [Documentation]    Retrieves a pet by ID with flexible status code handling
    [Arguments]    ${pet_id}    ${expected_status}=any
    Log    Attempting to retrieve pet with ID: ${pet_id}    level=INFO
    ${response}    GET On Session    petstore    /pet/${pet_id}    expected_status=${expected_status}
    Log    Response status code: ${response.status_code}    level=INFO
    Log    Response content: ${response.text}    level=DEBUG
    [Return]    ${response}

Get Pets By Status
    [Documentation]    Retrieves all pets with the specified status
    [Arguments]    ${status}=sold
    Log    Retrieving all pets with status: '${status}'    level=INFO
    ${params}    Create Dictionary    status=${status}
    ${response}    GET On Session    petstore    /pet/findByStatus    params=${params}    expected_status=200
    
    ${count}=    Get Length    ${response.json()}
    Log    ✓ Retrieved ${count} pets with status '${status}'    level=INFO
    Log    Full response: ${response.json()}    level=DEBUG
    
    [Return]    ${response.json()}

Delete Pet And Verify
    [Documentation]    Attempts to delete a pet and verifies deletion with retry mechanism
    [Arguments]    ${pet_id}    ${max_attempts}=3    ${delay}=5s
    Log    Starting deletion process for pet ID: ${pet_id} (max ${max_attempts} attempts)    level=INFO
    ${range_end}=    Evaluate    ${max_attempts} + 1
    
    FOR    ${attempt}    IN RANGE    1    ${range_end}
        Log    ----- DELETE ATTEMPT ${attempt}/${max_attempts} -----    level=INFO
        
        # Try to delete the pet
        ${headers}    Create Dictionary    api_key=special-key
        ${response}    DELETE On Session    petstore    /pet/${pet_id}    headers=${headers}    expected_status=any
        ${status_code}=    Set Variable    ${response.status_code}
        Log    Delete response status: ${status_code}    level=INFO
        
        # Verify deletion
        ${verify_response}    GET On Session    petstore    /pet/${pet_id}    expected_status=any
        ${verify_status}=    Set Variable    ${verify_response.status_code}
        Log    Verification status: ${verify_status}    level=INFO
        
        # Check if successfully deleted
        IF    ${verify_status} == 404
            Log    ✓ Pet ID: ${pet_id} successfully deleted on attempt ${attempt}    level=INFO
            RETURN    ${TRUE}
        END
        
        # Handle retry
        IF    ${attempt} < ${max_attempts}
            Log    ⚠ Pet ID: ${pet_id} not deleted yet. Retrying in ${delay}...    level=WARN
            Sleep    ${delay}
        ELSE
            Log    ✗ Final deletion attempt failed for pet ID: ${pet_id}    level=WARN
        END
    END
    
    Log    ✗ Failed to delete pet ID: ${pet_id} after ${max_attempts} attempts    level=WARN
    [Return]    ${FALSE}

Verify Pet Details
    [Documentation]    Verifies that pet details match expected values
    [Arguments]    ${pet_data}    ${expected_name}    ${expected_status}
    Log    Verifying pet details    level=INFO
    
    Should Be Equal As Strings    ${pet_data}[name]    ${expected_name}
    Should Be Equal As Strings    ${pet_data}[status]    ${expected_status}
    
    Log    ✓ Pet details verified successfully    level=INFO