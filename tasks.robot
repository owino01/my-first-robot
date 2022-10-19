*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault



*** Variables ***
${legsInput_xpath}=    /html/body/div/div/div[1]/div/div[1]/form/div[3]/input
${orderButton_xpath}=    /html/body/div/div/div[1]/div/div[1]/form/button[2]
${modal_xpath}=    /html/body/div/div/div[2]/div/div/div/div/div/button[2]
${orderAnotherRobotButton_xpath}=    /html/body/div/div/div[1]/div/div[1]/div/button


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get vault & user input and open the robot order website
    Fill the form using the data from the csv file
    Store pdf receipts in a zip archive within the output folder
    [Teardown]    Close the browser


*** Keywords ***
Get vault & user input and open the robot order website
    ${secret}=    Get Secret    orders_link
    Add text input    csvUrl    label=Csv site
    ${inputResult}=    Run dialog
    Open Available Browser    ${secret}[orders_site]
    Download    ${inputResult.csvUrl}    overwrite=True

    
    
Fill and preview form for one order   
    [Arguments]    ${order} 
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath=${legsInput_xpath}    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:preview
    Click Button    xpath=${orderButton_xpath}
    #save receipt
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt	outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt${order}[Order number].pdf
    #screenshot
    ${screenshot}=    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshot${order}[Order number].png        
    Open Pdf    ${OUTPUT_DIR}${/}receipt${order}[Order number].pdf      
    ${files}=    Create List    
    ...    ${OUTPUT_DIR}${/}receipt${order}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}screenshot${order}[Order number].png    
    Wait Until Keyword Succeeds    1 min    5 sec
    ...    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}receipt${order}[Order number].pdf
         


Fill the form using the data from the csv file   
    ${orders}=    Read table from CSV    orders.csv 

    FOR    ${order}    IN    @{orders}
        Wait Until Element Is Visible   xpath=${modal_xpath}    60
        Click Button    OK
        Wait Until Keyword Succeeds    1 min    3 sec
        ...    Fill and preview form for one order    ${order}
        Wait Until Page Contains Element    
        ...    xpath=${orderAnotherRobotButton_xpath}
        ...    40 sec
        Click Button    xpath=${orderAnotherRobotButton_xpath}        
    END


Store pdf receipts in a zip archive within the output folder
    ${receiptList}=    Set Variable    ${OUTPUT_DIR}
    Archive Folder With Zip
    ...    ${receiptList}
    ...    ${OUTPUT_DIR}${/}receiptList.zip
    ...    False   
    ...    include=*.pdf



Close the browser
    Close Browser