# ACC Issues Connector

This data connector is designed for scenarios where the person authoring the Power BI report has access to existing designs in APS-based applications such as [Autodesk Construction Cloud](https://construction.autodesk.com). The author of the report will need to log in with their Autodesk credentials before using this data source, and specify the ID of the project whose issues should be imported.

This project was inspired by https://github.com/autodesk-platform-services/aps-powerbi-tools.

## Development

### Prerequisites

- [APS app credentials](https://forge.autodesk.com/en/docs/oauth/v2/tutorials/create-app)
  - [Provision access to ACC or BIM360](https://tutorials.autodesk.io/#provision-access-in-other-products)
- [Power Query SDK](https://learn.microsoft.com/en-us/power-query/install-sdk)
- [.NET 8](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)

### Running locally in Visual Studio Code

- Ensure you have the Power Query SDK extension installed in Visual Studio Code.

- Clone this repository

- Open this repository in Visual Studio Code.

- Create a "secrets.json" file at the root of this repository, and populate it with your APS application client ID and secret:

  ```json
  {
      "APS_CLIENT_ID": "<your client id>",
      "APS_CLIENT_SECRET": "<your client secret>"
  }
  ```

- Open your APS application on https://aps.autodesk.com/myapps, and add the following Callback URL: `https://oauth.powerbi.com/views/oauthredirect.html`

- Build the connector (.mez file) by opening a terminal in this directory, then run `dotnet build`.

  - **USEFUL:** The file `AccIssuesConnector.proj` contains a build step which will automatically copy the built artifact (`bin\AnyCPU\Debug\AccIssuesConnector.mez`) into the appropriate location so that PowerBI can load it automatically (`%USERPROFILE%\Documents\Microsoft Power BI Desktop\Custom Connectors\AccIssuesConnector.mez`).

  - **IMPORTANT:** the .mez file should not be shared with 3rd parties; it includes the _secrets.json_ file with your APS application credentials.

- To test the connector directly in Visual Studio Code:

  - Ensure you have the Power Query SDK extension installed.

  - Press `Ctrl + Shift + P` and type "Power query: Set credential" to sign into ACC using the three-legged authentication flow.

    - Set the "Source Kind" to "AccIssuesConnector"

    - Set the query/test file to "AccIssuesConnector.query.pq" which contains your test code.

    - Set the authentication type to OAuth

    - A dialog should appear prompting you to sign into your Autodesk account. Grant it the access it requests.

    - **NOTE** If you ever want to rename this connector and modify it for your own purposes, you'll need to update the file paths in `.vscode/settings.json` to preserve this testing workflow.

  - Open the file AccIssuesConnector.query.pq, then right-click inside the tab and select "Evaluate current power query file".

  - A new tab named "PQTest result" should open up with the queried test results.

- To test the connector in PowerBI:

  - Run `dotnet build` to build/update the .mez file (see the "USEFUL" comment above).

  - Open a blank report in PowerBI (or use an existing report, your choice!)

  - Go to "Get Data" and type "ACC Issues". The custom connector should show up as "ACC Issues (Beta) (Custom)".

    - Specify the project ID whose issues you want to load.

    - You will be prompted to sign into ACC. Proceed, then press "Connect".

    - Upon completion, a new table will be shown containing the issues. Press "Load" to proceed.

## License

This sample is licensed under the terms of the [MIT License](http://opensource.org/licenses/MIT). Please see the [LICENSE](LICENSE) file for more details.
