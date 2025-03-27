*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    JSONLibrary
Library    DateTime
Library    String
Resource   ../variables/env_variables.robot

*** Keywords ***
Create Session To Petstore API
    Log    Creating session to Petstore API at ${API_URL}    level=INFO
    Create Session    petstore    ${API_URL}    verify=True
    Log    Session created successfully    level=INFO

Generate Random ID
    Log    Generating random ID...    level=DEBUG
    ${random_id}    Evaluate    random.randint(1000, 9999)    random
    Log    Generated random ID: ${random_id}    level=INFO
    [Return]    ${random_id}

Add New Pet
    [Arguments]    ${pet_id}    ${name}    ${status}=available    ${category_name}=dog
    Log    Adding new pet with ID: ${pet_id}, Name: ${name}, Status: ${status}, Category: ${category_name}    level=INFO
    ${category}    Create Dictionary    id=1    name=${category_name}
    ${tags}    Create List    ${category}
    ${photoUrls}    Create List    string
    ${pet_data}    Create Dictionary    id=${pet_id}    name=${name}    category=${category}    photoUrls=${photoUrls}    tags=${tags}    status=${status}
    Log    Sending pet creation request with data: ${pet_data}    level=DEBUG
    ${response}    POST On Session    petstore    /pet    json=${pet_data}    expected_status=200
    Log    Pet created successfully with ID: ${pet_id}    level=INFO
    [Return]    ${response.json()}

Get Pet By ID
    [Arguments]    ${pet_id}
    Log    Retrieving pet with ID: ${pet_id}    level=INFO
    ${response}    GET On Session    petstore    /pet/${pet_id}    expected_status=200
    Log    Retrieved pet successfully: ${response.json()}    level=DEBUG
    [Return]    ${response.json()}

Try Get Pet By ID
    [Arguments]    ${pet_id}    ${expected_status}=any
    Log    Attempting to retrieve pet with ID: ${pet_id}, expecting status: ${expected_status}    level=INFO
    ${response}    GET On Session    petstore    /pet/${pet_id}    expected_status=${expected_status}
    Log    Response status code: ${response.status_code}    level=INFO
    Log    Response content: ${response.text}    level=DEBUG
    [Return]    ${response}

Verify Pet Does Not Exist
    [Arguments]    ${pet_id}
    Log    Verifying pet with ID: ${pet_id} no longer exists    level=INFO
    ${response}    GET On Session    petstore    /pet/${pet_id}    expected_status=404
    Log    Received 404 response as expected    level=INFO
    Should Be Equal As Strings    ${response.json()}[message]    Pet not found
    Log    Verified pet does not exist    level=INFO

Get Pets By Status
    [Arguments]    ${status}=sold
    Log    Retrieving all pets with status: ${status}    level=INFO
    ${params}    Create Dictionary    status=${status}
    ${response}    GET On Session    petstore    /pet/findByStatus    params=${params}    expected_status=200
    Log    Retrieved ${response.json().__len__()} pets with status '${status}'    level=INFO
    Log    Full response: ${response.json()}    level=DEBUG
    [Return]    ${response.json()}

Delete Pet And Verify
    [Arguments]    ${pet_id}    ${max_attempts}=3    ${delay}=5s
    Log    Starting deletion process for pet ID: ${pet_id} with max ${max_attempts} attempts    level=INFO
    ${range_end}=    Evaluate    ${max_attempts} + 1
    FOR    ${attempt}    IN RANGE    1    ${range_end}
        Log    ===== DELETE ATTEMPT ${attempt}/${max_attempts} =====    level=INFO
        
        # Try to delete the pet
        ${headers}    Create Dictionary    api_key=special-key
        Log    Sending DELETE request for pet ID: ${pet_id}    level=INFO
        ${response}    DELETE On Session    petstore    /pet/${pet_id}    headers=${headers}    expected_status=any
        ${status_code}=    Set Variable    ${response.status_code}
        Log    Delete response status code: ${status_code}    level=INFO
        Log    Delete response body: ${response.text}    level=DEBUG
        
        # Check if the pet is gone
        Log    Verifying pet deletion...    level=INFO
        ${verify_response}    GET On Session    petstore    /pet/${pet_id}    expected_status=any
        ${verify_status}=    Set Variable    ${verify_response.status_code}
        Log    Verification response status: ${verify_status}    level=INFO
        Log    Verification response body: ${verify_response.text}    level=DEBUG
        
        # If we get a 404, the pet is successfully deleted
        IF    ${verify_status} == 404
            Log    ✓ SUCCESS: Pet ID: ${pet_id} successfully deleted on attempt ${attempt}    level=INFO
            RETURN    ${TRUE}
        END
        
        # If we haven't deleted it yet, wait and try again
        IF    ${attempt} < ${max_attempts}
            Log    Pet ID: ${pet_id} not deleted yet (status code: ${verify_status}). Retrying in ${delay}...    level=WARN
            Sleep    ${delay}
        ELSE
            Log    ✗ FAILURE: Final deletion attempt failed for pet ID: ${pet_id}    level=WARN
        END
    END
    
    # If we got here, we failed to delete the pet after all attempts
    Log    ✗ FAILURE: Failed to delete pet ID: ${pet_id} after ${max_attempts} attempts    level=WARN
    [Return]    ${FALSE}

Verify Pet Details
    [Arguments]    ${pet_data}    ${expected_name}    ${expected_status}
    Log    Verifying pet details - Expected name: ${expected_name}, Expected status: ${expected_status}    level=INFO
    Log    Actual pet data: ${pet_data}    level=DEBUG
    Should Be Equal As Strings    ${pet_data}[name]    ${expected_name}
    Should Be Equal As Strings    ${pet_data}[status]    ${expected_status}
    Log    ✓ Pet details verified successfully    level=INFO

Place Order For Pet
    [Arguments]    ${pet_id}    ${quantity}=1    ${ship_date}=${EMPTY}    ${status}=placed    ${complete}=${TRUE}
    Log    Placing order for pet ID: ${pet_id}, Quantity: ${quantity}, Status: ${status}    level=INFO
    
    # If no ship date provided, use current date plus 3 days
    ${current_date}=    Run Keyword If    '${ship_date}' == '${EMPTY}'    Get Current Date    increment=3 days    result_format=iso8601
    ${ship_date}=    Set Variable If    '${ship_date}' == '${EMPTY}'    ${current_date}    ${ship_date}
    Log    Using ship date: ${ship_date}    level=INFO
    
    # Create order data
    ${order_id}=    Generate Random ID
    Log    Generated order ID: ${order_id}    level=INFO
    ${order_data}=    Create Dictionary
    ...    id=${order_id}
    ...    petId=${pet_id}
    ...    quantity=${quantity}
    ...    shipDate=${ship_date}
    ...    status=${status}
    ...    complete=${complete}
    
    Log    Submitting order with data: ${order_data}    level=DEBUG
    # Place order
    ${response}=    POST On Session    petstore    /store/order    json=${order_data}    expected_status=200
    Log    ✓ Order placed successfully with ID: ${response.json()}[id]    level=INFO
    Log    Complete order details: ${response.json()}    level=DEBUG
    
    # Return order details
    [Return]    ${response.json()}

Get Order By ID
    [Arguments]    ${order_id}
    Log    Retrieving order with ID: ${order_id}    level=INFO
    ${response}=    GET On Session    petstore    /store/order/${order_id}    expected_status=200
    Log    ✓ Retrieved order details: ${response.json()}    level=INFO
    [Return]    ${response.json()} 