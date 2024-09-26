[Version = "0.0.8"]
section AccIssuesConnector;

SECRETS = Json.Document(Extension.Contents("secrets.json"));
REDIRECT_URI = "https://oauth.powerbi.com/views/oauthredirect.html";

[DataSource.Kind = "AccIssuesConnector", Publish = "AccIssuesConnector.Publish"]
shared AccIssuesConnector.Contents = (projectId as text) as table =>
    let
        // Sanitize the project ID by removing any "b." prefix.
        sanitizedProjectId = if Text.StartsWith(projectId, "b.") then Text.Middle(projectId, 2) else projectId,
        issues = AccIssuesConnector.GetIssues(sanitizedProjectId),
        tableFromList = Table.FromList(issues, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        expandedTable = Table.ExpandRecordColumn(
            tableFromList,
            "Column1",
            {"id", "title", "description", "linkedDocuments", "status", "createdAt", "updatedAt", "dueDate", "assignedTo", "createdBy"}),
        expandedLinkedDocuments = Table.AddColumn(
            expandedTable,
            "first_link",
            each if List.IsEmpty([linkedDocuments]) then null else List.First([linkedDocuments])
        ),
        expandedFirstLinkedDocument = Table.ExpandRecordColumn(
            expandedLinkedDocuments,
            "first_link",
            {"details"}
        ),
        expandedDetails = Table.ExpandRecordColumn(
            expandedFirstLinkedDocument,
            "details",
            {"position", "objectId", "externalId"}),
        expandedPosition = Table.ExpandRecordColumn(
            expandedDetails,
            "position",
            {"x", "y", "z"})
    in
        expandedPosition;


AccIssuesConnector = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = RefreshToken,
            Label = Extension.LoadString("AuthenticationLabel")
        ]
    ]
];

StartLogin = (dataSourcePath, state, display) =>
    let
        query = [
            response_type = "code",
            client_id = SECRETS[APS_CLIENT_ID],
            scope = "data:read",
            redirect_uri = REDIRECT_URI,
            state = state
        ],
        url = "https://developer.api.autodesk.com/authentication/v2/authorize?" & Uri.BuildQueryString(query)
    in
        [
            LoginUri = url,
            CallbackUri = REDIRECT_URI,
            Context = null,
            WindowWidth = 600,
            WindowHeight = 600
        ];

FinishLogin = (context, callbackUri, state) => let parts = Uri.Parts(callbackUri)[Query] in TokenMethod(parts[code]);

TokenMethod = (code) =>
    let
        query = [
            grant_type = "authorization_code",
            code = code,
            redirect_uri = REDIRECT_URI
        ],
        response = Web.Contents(
            "https://developer.api.autodesk.com/authentication/v2/token",
            [
                Content = Text.ToBinary(Uri.BuildQueryString(query)),
                Headers = [
                    #"Content-Type" = "application/x-www-form-urlencoded",
                    #"Accept" = "application/json",
                    #"Authorization" = "Basic " & Binary.ToText(Text.ToBinary(SECRETS[APS_CLIENT_ID] & ":" & SECRETS[APS_CLIENT_SECRET]), BinaryEncoding.Base64)
                ]
            ]
        )
    in
        Json.Document(response);

RefreshToken = (dataSourcePath, refreshToken) =>
    let
        query = [
            grant_type = "refresh_token",
            refresh_token = refreshToken
        ],
        response = Web.Contents(
            "https://developer.api.autodesk.com/authentication/v2/token",
            [
                Content = Text.ToBinary(Uri.BuildQueryString(query)),
                Headers = [
                    #"Content-Type" = "application/x-www-form-urlencoded",
                    #"Accept" = "application/json",
                    #"Authorization" = "Basic " & Binary.ToText(Text.ToBinary(SECRETS[APS_CLIENT_ID] & ":" & SECRETS[APS_CLIENT_SECRET]), BinaryEncoding.Base64)
                ]
            ]
        )
    in
        Json.Document(response);

AccIssuesConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://github.com/autodesk-platform-services/aps-powerbi-tools",
    SourceImage = AccIssuesConnector.Icons,
    SourceTypeImage = AccIssuesConnector.Icons
];

AccIssuesConnector.Icons = [
    Icon16 = {
        Extension.Contents("AccIssuesConnector16.png"),
        Extension.Contents("AccIssuesConnector20.png"),
        Extension.Contents("AccIssuesConnector24.png"),
        Extension.Contents("AccIssuesConnector32.png")
    },
    Icon32 = {
        Extension.Contents("AccIssuesConnector32.png"),
        Extension.Contents("AccIssuesConnector40.png"),
        Extension.Contents("AccIssuesConnector48.png"),
        Extension.Contents("AccIssuesConnector64.png")
    }
];

AccIssuesConnector.GetIssues = (projectId as text) as list =>
    let
        url = "https://developer.api.autodesk.com/construction/issues/v1/projects/" & projectId & "/issues",
        response = Web.Contents(url, [
            Headers = [
                #"Authorization" = "Bearer " & Extension.CurrentCredential()[access_token]
            ]
        ]),
        json = Json.Document(response)
    in
        json[results];